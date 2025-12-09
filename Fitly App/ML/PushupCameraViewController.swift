import UIKit
import AVFoundation
import Vision
import CoreImage

final class PushupCameraViewController: UIViewController {

    // MARK: - Public
    weak var delegate: PushupCameraDelegate?

    // MARK: - UI
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

    // MARK: - Camera / Vision
    private let cameraManager = CameraSessionManager()
    private let videoQueue = DispatchQueue(label: "fitly.camera.queue")
    private let sequenceHandler = VNSequenceRequestHandler()

    // MARK: - Counting logic
    private var repCount: Int = 0 {
        didSet { DispatchQueue.main.async { self.countLabel.text = "\(self.repCount)" } }
    }
    private var smoothedAngle: CGFloat = 170
    private var armWasDown = false
    private let downThreshold: CGFloat = 80
    private let upThreshold: CGFloat = 150
    private let smoothingAlpha: CGFloat = 0.2

    // MARK: - Debug (kept minimal)
    private var frameCounter = 0
    private var debugLogs = false

    // MARK: - Lifecycle
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

    // MARK: - UI
    private func setupUI() {
        previewContainer.translatesAutoresizingMaskIntoConstraints = false
        previewContainer.clipsToBounds = true
        view.addSubview(previewContainer)

        overlayView.backgroundColor = .clear
        overlayView.isUserInteractionEnabled = false
        previewContainer.addSubview(overlayView)

        view.addSubview(countLabel)
        view.addSubview(doneButton)

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

        let dbl = UITapGestureRecognizer(target: self, action: #selector(cancelTapped))
        dbl.numberOfTapsRequired = 2
        view.addGestureRecognizer(dbl)
    }

    // MARK: - Camera configuration
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

            if let conn = pl.connection {
                conn.automaticallyAdjustsVideoMirroring = false
                conn.videoOrientation = .portrait
                conn.isVideoMirrored = true
            } else {
                pl.setAffineTransform(CGAffineTransform(scaleX: -1, y: 1))
            }

            if pl.superlayer == nil {
                self.previewContainer.layer.insertSublayer(pl, at: 0)
            }

            self.previewContainer.bringSubviewToFront(self.overlayView)

            if self.debugLogs {
                self.debugSessionStatus()
            }

            self.cameraManager.startRunning()
        }
    }

    @objc private func sessionConfigFailed(_ n: Notification) {
        var msg = "Unknown camera error"
        if let e = n.object as? Error { msg = e.localizedDescription }
        presentErrorAndClose(msg)
    }

    private func showPermissionAlert() {
        let ac = UIAlertController(title: "Camera Access Required",
                                   message: "Enable camera access in Settings.",
                                   preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            self.delegate?.pushupSessionDidCancel()
            self.dismiss(animated: true)
        })
        present(ac, animated: true)
    }

    private func presentErrorAndClose(_ message: String) {
        let ac = UIAlertController(title: "Camera Error", message: message, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "Close", style: .default) { _ in
            self.delegate?.pushupSessionDidCancel()
            self.dismiss(animated: true)
        })
        present(ac, animated: true)
    }

    // MARK: - Actions
    @objc private func doneTapped() {
        doneButton.isEnabled = false
        cameraManager.stopRunning()

        CoreDataManager.shared.createPushupSession(count: repCount, date: Date())

        DispatchQueue.main.async {
            self.delegate?.pushupSessionDidFinish(count: self.repCount)
            self.dismiss(animated: true)
        }
    }

    @objc private func cancelTapped() {
        cameraManager.stopRunning()
        delegate?.pushupSessionDidCancel()
        dismiss(animated: true)
    }

    // MARK: - Vision orientation helper
    private func currentCGImagePropertyOrientation() -> CGImagePropertyOrientation {
        return cameraManager.usingFrontCamera ? .leftMirrored : .right
    }

    // MARK: - Frame processing
    private func processFrame(pixelBuffer: CVPixelBuffer) {
        let req = VNDetectHumanBodyPoseRequest()
        let orientation = currentCGImagePropertyOrientation()

        do {
            try sequenceHandler.perform([req], on: pixelBuffer, orientation: orientation)
        } catch {
            if debugLogs { print("Vision perform error:", error) }
            return
        }

        guard let obs = req.results?.first else {
            DispatchQueue.main.async { self.overlayView.updateImage(nil) }
            return
        }

        handlePoseObservation(obs)
    }

    // MARK: - Pose handling (use capture-device normalized coords)
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
                points[name] = CGPoint(x: p.x, y: p.y)
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
            DispatchQueue.main.async { self.overlayView.updateImage(nil) }
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

            let img = self.drawSkeleton(points: points, rep: self.repCount)
            self.overlayView.updateImage(img)
        }
    }

    // MARK: - Draw skeleton (FINAL: flip BOTH axes before projecting)
    private func drawSkeleton(points: [VNHumanBodyPoseObservation.JointName: CGPoint], rep: Int) -> CGImage? {
        let size = overlayView.bounds.size
        guard size.width > 0 && size.height > 0 else { return nil }

        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        guard let ctx = UIGraphicsGetCurrentContext() else { UIGraphicsEndImageContext(); return nil }

        ctx.setLineWidth(3)
        ctx.setStrokeColor(UIColor.systemGreen.cgColor)
        ctx.setFillColor(UIColor.systemGreen.cgColor)

        func mapPoint(_ p: CGPoint) -> CGPoint {
            let flipped = CGPoint(x: 1 - p.x, y: 1 - p.y)
            return cameraManager.previewLayer.layerPointConverted(fromCaptureDevicePoint: flipped)
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
                ctx.move(to: mapPoint(pa))
                ctx.addLine(to: mapPoint(pb))
                ctx.strokePath()
            }
        }

        for (_, p) in points {
            let v = mapPoint(p)
            let r: CGFloat = 6
            ctx.addEllipse(in: CGRect(x: v.x - r/2, y: v.y - r/2, width: r, height: r))
            ctx.drawPath(using: .fill)
        }

        let text = "Reps: \(rep)"
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 20),
            .foregroundColor: UIColor.white
        ]
        (text as NSString).draw(at: CGPoint(x: 10, y: 10), withAttributes: attrs)

        let img = UIGraphicsGetImageFromCurrentImageContext()?.cgImage
        UIGraphicsEndImageContext()
        return img
    }

    // MARK: - Math helper
    private func angleBetween(a: CGPoint, b: CGPoint, c: CGPoint) -> CGFloat {
        let v1 = CGVector(dx: a.x - b.x, dy: a.y - b.y)
        let v2 = CGVector(dx: c.x - b.x, dy: c.y - b.y)
        let dot = v1.dx * v2.dx + v1.dy * v2.dy
        let m1 = hypot(v1.dx, v1.dy)
        let m2 = hypot(v2.dx, v2.dy)
        guard m1 > 1e-4 && m2 > 1e-4 else { return 180 }
        return acos(max(-1, min(1, dot / (m1 * m2)))) * 180 / .pi
    }

    // MARK: - Debug helper
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
        print("====================")
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension PushupCameraViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        frameCounter += 1
        if frameCounter % 60 == 0 && debugLogs {
            print("Frames received:", frameCounter)
        }

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        processFrame(pixelBuffer: pixelBuffer)
    }
}
