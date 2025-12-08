import UIKit
import AVFoundation
import Vision
import CoreImage

final class PushupCameraViewController: UIViewController {

    weak var delegate: PushupCameraDelegate?

    // UI
    private let previewContainer = UIView()
    private let overlayView = OverlayView()
    private let countLabel: UILabel = {
        let l = UILabel()
        l.font = .boldSystemFont(ofSize: 34)
        l.textColor = .white
        l.text = "0"
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    private let doneButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Done", for: .normal)
        b.setTitleColor(.white, for: .normal)
        b.backgroundColor = UIColor.systemBlue
        b.layer.cornerRadius = 10
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    // camera manager + vision
    private let cameraManager = CameraSessionManager()
    private let videoQueue = DispatchQueue(label: "fitly.camera.queue")
    private let sequenceHandler = VNSequenceRequestHandler()

    // counting
    private var repCount: Int = 0 {
        didSet { DispatchQueue.main.async { self.countLabel.text = "\(self.repCount)" } }
    }
    private var smoothedAngle: CGFloat = 170
    private var armWasDown = false
    private let downThreshold: CGFloat = 80
    private let upThreshold: CGFloat = 150
    private let smoothingAlpha: CGFloat = 0.2

    // debug
    private var frameCounter = 0
    private var showDebugCameraFrame = false // set true to render raw camera frames into overlay (expensive)

    // lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupUI()
        observeCameraNotifications()
        checkCameraPermissionAndConfigure()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        cameraManager.previewLayer.frame = previewContainer.bounds
        overlayView.frame = previewContainer.bounds
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        cameraManager.stopRunning()
    }

    private func setupUI() {
        previewContainer.translatesAutoresizingMaskIntoConstraints = false
        previewContainer.clipsToBounds = true
        view.addSubview(previewContainer)
        view.addSubview(countLabel)
        view.addSubview(doneButton)
        previewContainer.addSubview(overlayView)
        overlayView.isUserInteractionEnabled = false
        overlayView.backgroundColor = .clear

        NSLayoutConstraint.activate([
            previewContainer.topAnchor.constraint(equalTo: view.topAnchor),
            previewContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            previewContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            previewContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            countLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            countLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            doneButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            doneButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            doneButton.widthAnchor.constraint(equalToConstant: 120),
            doneButton.heightAnchor.constraint(equalToConstant: 44)
        ])

        doneButton.addTarget(self, action: #selector(doneTapped), for: .touchUpInside)
        let dblTap = UITapGestureRecognizer(target: self, action: #selector(cancelTapped))
        dblTap.numberOfTapsRequired = 2
        view.addGestureRecognizer(dblTap)
    }

    // MARK: Permissions and config
    private func checkCameraPermissionAndConfigure() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            configureCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    granted ? self.configureCamera() : self.showPermissionAlert()
                }
            }
        default:
            showPermissionAlert()
        }
    }

    private func showPermissionAlert() {
        let ac = UIAlertController(title: "Camera Access Required",
                                   message: "Enable camera access in Settings to count push-ups.",
                                   preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            self.delegate?.pushupSessionDidCancel()
            self.dismiss(animated: true, completion: nil)
        })
        present(ac, animated: true, completion: nil)
    }

    private func configureCamera() {
        cameraManager.configureSession(preferredPosition: .front,
                                       sampleBufferDelegate: self,
                                       delegateQueue: videoQueue)
    }

    private func observeCameraNotifications() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(sessionConfigured),
                                               name: .cameraSessionConfigurationCompleted,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(sessionConfigFailed(_:)),
                                               name: .cameraSessionConfigurationFailed,
                                               object: nil)
    }

    @objc private func sessionConfigured() {
        DispatchQueue.main.async {
            let pl = self.cameraManager.previewLayer
            pl.frame = self.previewContainer.bounds

            if let plConn = pl.connection {
                if plConn.automaticallyAdjustsVideoMirroring {
                    plConn.automaticallyAdjustsVideoMirroring = false
                }
                if plConn.isVideoOrientationSupported {
                    plConn.videoOrientation = .portrait
                }
                if plConn.isVideoMirroringSupported {
                    plConn.isVideoMirrored = self.cameraManager.usingFrontCamera
                }
            } else if self.cameraManager.usingFrontCamera {
                pl.setAffineTransform(CGAffineTransform(scaleX: -1, y: 1))
            }

            if pl.superlayer == nil {
                self.previewContainer.layer.insertSublayer(pl, at: 0)
            }

            self.previewContainer.bringSubviewToFront(self.overlayView)

            // Debug: print status before starting
            self.debugSessionStatus()

            // start running
            self.cameraManager.startRunning()
        }
    }

    @objc private func sessionConfigFailed(_ n: Notification) {
        var msg = "Unknown camera error."
        if let err = n.object as? Error { msg = err.localizedDescription }
        presentErrorAndClose(msg)
    }

    private func presentErrorAndClose(_ message: String) {
        let ac = UIAlertController(title: "Camera error", message: message, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            self.delegate?.pushupSessionDidCancel()
            self.dismiss(animated: true, completion: nil)
        })
        present(ac, animated: true, completion: nil)
    }

    // MARK: Actions
    @objc private func doneTapped() {
        // Предотвращаем двойные нажатия
        doneButton.isEnabled = false

        // Останавливаем камеру
        cameraManager.stopRunning()

        // Сохраняем запись через CoreDataManager
        let countToSave = Int(repCount)
        CoreDataManager.shared.createPushupSession(count: countToSave, date: Date())

        // Сообщаем делегату и закрываем экран на main
        DispatchQueue.main.async {
            self.delegate?.pushupSessionDidFinish(count: self.repCount)
            self.dismiss(animated: true, completion: nil)
        }
    }

    @objc private func cancelTapped() {
        cameraManager.stopRunning()
        delegate?.pushupSessionDidCancel()
        dismiss(animated: true, completion: nil)
    }

    // MARK: Pose handling
    private func processFrame(pixelBuffer: CVPixelBuffer) {
        let request = VNDetectHumanBodyPoseRequest()
        do {
            try sequenceHandler.perform([request], on: pixelBuffer)
            guard let observation = request.results?.first else {
                overlayView.updateImage(nil)
                return
            }
            handlePoseObservation(observation)
        } catch {
            // ignore transient Vision errors
        }
    }

    private func handlePoseObservation(_ obs: VNHumanBodyPoseObservation) {
        var points: [VNHumanBodyPoseObservation.JointName: CGPoint] = [:]
        let jointNames: [VNHumanBodyPoseObservation.JointName] = [
            .nose, .leftEye, .rightEye, .leftEar, .rightEar,
            .leftShoulder, .rightShoulder, .leftElbow, .rightElbow,
            .leftWrist, .rightWrist, .leftHip, .rightHip,
            .leftKnee, .rightKnee, .leftAnkle, .rightAnkle
        ]
        for name in jointNames {
            if let p = try? obs.recognizedPoint(name), p.confidence >= 0.15 {
                points[name] = CGPoint(x: p.x, y: 1 - p.y)
            }
        }

        var angles: [CGFloat] = []
        if let s = points[.leftShoulder], let e = points[.leftElbow], let w = points[.leftWrist] {
            angles.append(angleBetween(a: s, b: e, c: w))
        }
        if let s = points[.rightShoulder], let e = points[.rightElbow], let w = points[.rightWrist] {
            angles.append(angleBetween(a: s, b: e, c: w))
        }

        guard !angles.isEmpty else {
            overlayView.updateImage(nil)
            return
        }

        let chosen = angles.reduce(0, +) / CGFloat(angles.count)
        smoothedAngle = smoothingAlpha * chosen + (1 - smoothingAlpha) * smoothedAngle

        DispatchQueue.main.async {
            if self.smoothedAngle < self.downThreshold {
                self.armWasDown = true
            } else if self.armWasDown && self.smoothedAngle > self.upThreshold {
                self.repCount += 1
                self.armWasDown = false
            }
            let img = self.makeOverlayImage(points: points, repCount: self.repCount, mirrorX: self.cameraManager.usingFrontCamera)
            self.overlayView.updateImage(img)
        }
    }

    private func makeOverlayImage(points: [VNHumanBodyPoseObservation.JointName: CGPoint], repCount: Int, mirrorX: Bool) -> CGImage? {
        let size = overlayView.bounds.size
        guard size.width > 0 && size.height > 0 else { return nil }
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        guard let ctx = UIGraphicsGetCurrentContext() else { UIGraphicsEndImageContext(); return nil }

        ctx.setLineWidth(2)
        ctx.setStrokeColor(UIColor.systemGreen.cgColor)
        ctx.setFillColor(UIColor.systemGreen.cgColor)

        func toView(_ p: CGPoint) -> CGPoint {
            let normalizedX = mirrorX ? (1 - p.x) : p.x
            return CGPoint(x: normalizedX * size.width, y: p.y * size.height)
        }

        let connections: [(VNHumanBodyPoseObservation.JointName, VNHumanBodyPoseObservation.JointName)] = [
            (.nose, .leftEye), (.nose, .rightEye),
            (.leftEye, .leftEar), (.rightEye, .rightEar),
            (.leftShoulder, .leftElbow), (.leftElbow, .leftWrist),
            (.rightShoulder, .rightElbow), (.rightElbow, .rightWrist),
            (.leftShoulder, .rightShoulder),
            (.leftShoulder, .leftHip), (.rightShoulder, .rightHip),
            (.leftHip, .rightHip),
            (.leftHip, .leftKnee), (.leftKnee, .leftAnkle),
            (.rightHip, .rightKnee), (.rightKnee, .rightAnkle)
        ]

        for (a, b) in connections {
            if let pa = points[a], let pb = points[b] {
                ctx.move(to: toView(pa)); ctx.addLine(to: toView(pb)); ctx.strokePath()
            }
        }

        for (_, p) in points {
            let v = toView(p)
            let r: CGFloat = 6
            ctx.addEllipse(in: CGRect(x: v.x - r/2, y: v.y - r/2, width: r, height: r))
            ctx.drawPath(using: .fill)
        }

        let text = "Reps: \(repCount)"
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 14),
            .foregroundColor: UIColor.white
        ]
        text.draw(at: CGPoint(x: 8, y: 8), withAttributes: attrs)

        let uiImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return uiImage?.cgImage
    }

    // MARK: - Math
    private func angleBetween(a: CGPoint, b: CGPoint, c: CGPoint) -> CGFloat {
        let v1 = CGVector(dx: a.x - b.x, dy: a.y - b.y)
        let v2 = CGVector(dx: c.x - b.x, dy: c.y - b.y)
        let dot = v1.dx * v2.dx + v1.dy * v2.dy
        let m1 = hypot(v1.dx, v1.dy)
        let m2 = hypot(v2.dx, v2.dy)
        guard m1 > 1e-4 && m2 > 1e-4 else { return 180 }
        let cosA = max(-1, min(1, dot / (m1 * m2)))
        return acos(cosA) * 180 / .pi
    }
}

// MARK: AVCaptureVideoDataOutputSampleBufferDelegate
extension PushupCameraViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        frameCounter += 1
        if frameCounter % 60 == 0 {
            print("Frames received:", frameCounter)
        }

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        if showDebugCameraFrame {
            // Draw raw camera frame to overlay for debug (expensive)
            let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
            let context = CIContext(options: nil)
            if let cg = context.createCGImage(ciImage, from: ciImage.extent) {
                DispatchQueue.main.async {
                    self.overlayView.updateImage(cg)
                }
            }
        }

        processFrame(pixelBuffer: pixelBuffer)
    }
    
    
    // ----------------- Добавь внутрь PushupCameraViewController -----------------
    private func debugSessionStatus() {
        print("=== Camera debug ===")
        let session = cameraManager.captureSession
        print("session running:", session.isRunning)
        print("inputs count:", session.inputs.count)
        for (i, input) in session.inputs.enumerated() {
            print(" input[\(i)]:", type(of: input))
            if let devInput = input as? AVCaptureDeviceInput {
                print("  device position:", devInput.device.position.rawValue)
                print("  localizedName:", devInput.device.localizedName)
                // activeFormat may be useful (optional)
                let fmt = devInput.device.activeFormat
                print("  active format videoSupportedFrameRateRanges:", fmt.videoSupportedFrameRateRanges)
            }
        }
        print("outputs count:", session.outputs.count)
        for (i, out) in session.outputs.enumerated() {
            print(" output[\(i)]:", type(of: out))
            if let vOut = out as? AVCaptureVideoDataOutput {
                if let conn = vOut.connection(with: .video) {
                    print("  videoOutput connection - active:", conn.isActive,
                          "mirroringSupported:", conn.isVideoMirroringSupported,
                          "automaticallyAdjusts:", conn.automaticallyAdjustsVideoMirroring,
                          "isMirrored:", conn.isVideoMirrored,
                          "orientationSupported:", conn.isVideoOrientationSupported,
                          "orientation:", conn.videoOrientation.rawValue)
                } else {
                    print("  videoOutput connection: nil")
                }
            }
        }
        let pl = cameraManager.previewLayer
        print("previewLayer superlayer:", pl.superlayer != nil ? "yes" : "no")
        print("previewLayer frame:", pl.frame)
        print("previewContainer bounds:", previewContainer.bounds)
        print("overlayView frame:", overlayView.frame)
        print("====================")
    }
    // ---------------------------------------------------------------------------

}
