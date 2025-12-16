import UIKit
import AVFoundation
import Vision
import CoreImage
import SnapKit

final class PushupCameraViewController: UIViewController {

    weak var delegate: PushupCameraDelegate?
    var dailyTarget: Int?

    private let contentView = PushupCameraViewCell()
    private let cameraManager = CameraSessionManager()
    private let videoQueue = DispatchQueue(label: "fitly.camera.queue")
    private let sequenceHandler = VNSequenceRequestHandler()

    // MARK: - Counting logic
    private var repCount: Int = 0 {
        didSet {
            DispatchQueue.main.async {
                self.contentView.bigCountLabel.text = "\(self.repCount)"
                self.updateCounterUI()
            }
        }
    }

    private var didShowDailyCompleteAlert = false

    private var smoothedAngle: CGFloat = 170
    private var armWasDown = false
    private var downThreshold: CGFloat = 110
    private var upThreshold: CGFloat = 140
    private var angleSmoothingAlpha: CGFloat = 0.25

    // MARK: - Point smoothing & visibility
    private var lastKnownPoints: [VNHumanBodyPoseObservation.JointName: CGPoint] = [:]
    private var lastKnownConfidences: [VNHumanBodyPoseObservation.JointName: CGFloat] = [:]
    private let positionSmoothingAlpha: CGFloat = 0.35
    private let minVisibleConfidence: CGFloat = 0.05

    private var frameCounter = 0
    private var debugLogs = false

    override func loadView() {
        view = contentView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        SoundManager.shared.prepareSounds(dingName: "ding", successName: "succes")

        observeCameraNotifications()
        checkCameraPermissionAndConfigure()

        contentView.endSessionButton.addTarget(
            self,
            action: #selector(doneTapped),
            for: .touchUpInside
        )

        let dbl = UITapGestureRecognizer(target: self, action: #selector(cancelTapped))
        dbl.numberOfTapsRequired = 2
        view.addGestureRecognizer(dbl)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        cameraManager.previewLayer.frame = contentView.previewContainer.bounds
        contentView.overlayView.frame = contentView.previewContainer.bounds
        updateCounterUI()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        cameraManager.stopRunning()
    }
    
    private func updateCounterUI() {
        let total = dailyTarget ?? 0
        contentView.fractionLabel.text = "/\(total)"
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
        cameraManager.configureSession(
            preferredPosition: .front,
            sampleBufferDelegate: self,
            delegateQueue: videoQueue
        )
    }

    private func observeCameraNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(sessionConfigured),
            name: .cameraSessionConfigurationCompleted,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(sessionConfigFailed(_:)),
            name: .cameraSessionConfigurationFailed,
            object: nil
        )
    }

    @objc private func sessionConfigured() {
        DispatchQueue.main.async {
            let pl = self.cameraManager.previewLayer
            pl.frame = self.contentView.previewContainer.bounds

            if let conn = pl.connection {
                conn.automaticallyAdjustsVideoMirroring = false
                conn.videoOrientation = .portrait
                conn.isVideoMirrored = true
            } else {
                pl.setAffineTransform(CGAffineTransform(scaleX: -1, y: 1))
            }

            if pl.superlayer == nil {
                self.contentView.previewContainer.layer.insertSublayer(pl, at: 0)
            }

            self.contentView.previewContainer.bringSubviewToFront(
                self.contentView.overlayView
            )

            if self.debugLogs { self.debugSessionStatus() }

            self.cameraManager.startRunning()
        }
    }

    @objc private func sessionConfigFailed(_ n: Notification) {
        var msg = "Unknown camera error"
        if let e = n.object as? Error {
            msg = e.localizedDescription
        }
        presentErrorAndClose(msg)
    }

    private func showPermissionAlert() {
        let ac = UIAlertController(
            title: "Camera Access Required",
            message: "Enable camera access in Settings.",
            preferredStyle: .alert
        )

        ac.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            self.delegate?.pushupSessionDidCancel()
            self.dismiss(animated: true)
        })

        present(ac, animated: true)
    }

    private func presentErrorAndClose(_ message: String) {
        let ac = UIAlertController(
            title: "Camera Error",
            message: message,
            preferredStyle: .alert
        )

        ac.addAction(UIAlertAction(title: "Close", style: .default) { _ in
            self.delegate?.pushupSessionDidCancel()
            self.dismiss(animated: true)
        })

        present(ac, animated: true)
    }

    // MARK: - Actions
    @objc private func doneTapped() {
        contentView.endSessionButton.isEnabled = false
        cameraManager.stopRunning()

        CoreDataManager.shared.createPushupSession(
            count: repCount,
            date: Date()
        )

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
            DispatchQueue.main.async {
                self.contentView.overlayView.updateImage(nil)
            }
            return
        }

        handlePoseObservation(obs)
    }

    // MARK: - Pose handling
    private func handlePoseObservation(_ obs: VNHumanBodyPoseObservation) {
        var detected: [VNHumanBodyPoseObservation.JointName: (CGPoint, CGFloat)] = [:]

        let jointNames: [VNHumanBodyPoseObservation.JointName] = [
            .nose, .leftEye, .rightEye, .leftEar, .rightEar,
            .leftShoulder, .rightShoulder, .leftElbow, .rightElbow,
            .leftWrist, .rightWrist, .leftHip, .rightHip,
            .leftKnee, .rightKnee, .leftAnkle, .rightAnkle
        ]

        for name in jointNames {
            if let p = try? obs.recognizedPoint(name) {
                detected[name] = (CGPoint(x: p.x, y: p.y), CGFloat(p.confidence))
            }
        }

        var mergedPoints: [VNHumanBodyPoseObservation.JointName: CGPoint] = [:]
        var mergedConf: [VNHumanBodyPoseObservation.JointName: CGFloat] = [:]

        for name in jointNames {
            if let det = detected[name] {
                if let last = lastKnownPoints[name] {
                    let x = positionSmoothingAlpha * det.0.x + (1 - positionSmoothingAlpha) * last.x
                    let y = positionSmoothingAlpha * det.0.y + (1 - positionSmoothingAlpha) * last.y
                    mergedPoints[name] = CGPoint(x: x, y: y)
                } else {
                    mergedPoints[name] = det.0
                }
                mergedConf[name] = det.1
            } else if let last = lastKnownPoints[name] {
                mergedPoints[name] = last
                let lastConf = lastKnownConfidences[name] ?? 0
                mergedConf[name] = max(minVisibleConfidence, lastConf * 0.85)
            }
        }

        lastKnownPoints = mergedPoints
        lastKnownConfidences = mergedConf

        var angles: [CGFloat] = []

        if let s = mergedPoints[.leftShoulder],
           let e = mergedPoints[.leftElbow],
           let w = mergedPoints[.leftWrist] {
            angles.append(angleBetween(a: s, b: e, c: w))
        }

        if let s = mergedPoints[.rightShoulder],
           let e = mergedPoints[.rightElbow],
           let w = mergedPoints[.rightWrist] {
            angles.append(angleBetween(a: s, b: e, c: w))
        }

        guard !angles.isEmpty else {
            DispatchQueue.main.async {
                self.contentView.overlayView.updateImage(nil)
            }
            return
        }

        let chosen = angles.reduce(0, +) / CGFloat(angles.count)
        smoothedAngle = angleSmoothingAlpha * chosen
            + (1 - angleSmoothingAlpha) * smoothedAngle

        DispatchQueue.main.async {
            if self.smoothedAngle < self.downThreshold {
                self.armWasDown = true
            } else if self.armWasDown && self.smoothedAngle > self.upThreshold {
                self.repCount += 1
                self.armWasDown = false

                SoundManager.shared.playDing()

                if let target = self.dailyTarget,
                   target > 0,
                   self.repCount >= target,
                   !self.didShowDailyCompleteAlert {

                    self.didShowDailyCompleteAlert = true
                    SoundManager.shared.playSuccess()
                    self.showDailyCompletionAlert()
                }
            }

            let img = self.drawSkeleton(
                points: mergedPoints,
                confidences: mergedConf,
                rep: self.repCount
            )

            self.contentView.overlayView.updateImage(img)
        }
    }

    private func showDailyCompletionAlert() {
        let ac = UIAlertController(
            title: "Congratulations!",
            message: "You've completed today's target.",
            preferredStyle: .alert
        )

        ac.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            self.cameraManager.stopRunning()
            CoreDataManager.shared.createPushupSession(
                count: self.repCount,
                date: Date()
            )
            DispatchQueue.main.async {
                self.delegate?.pushupSessionDidFinish(count: self.repCount)
                self.dismiss(animated: true)
            }
        })

        if presentedViewController == nil {
            present(ac, animated: true)
        }
    }

    // MARK: - Drawing & math
    private func drawSkeleton(
        points: [VNHumanBodyPoseObservation.JointName: CGPoint],
        confidences: [VNHumanBodyPoseObservation.JointName: CGFloat],
        rep: Int
    ) -> CGImage? {

        let size = contentView.overlayView.bounds.size
        guard size.width > 0 && size.height > 0 else { return nil }

        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        guard let ctx = UIGraphicsGetCurrentContext() else {
            UIGraphicsEndImageContext()
            return nil
        }

        ctx.setLineWidth(3)
        ctx.setStrokeColor(UIColor.app.cgColor)
        ctx.setFillColor(UIColor.app.cgColor)

        func mapPointFlipped(_ p: CGPoint) -> CGPoint {
            let flipped = CGPoint(x: 1 - p.x, y: 1 - p.y)
            return cameraManager.previewLayer
                .layerPointConverted(fromCaptureDevicePoint: flipped)
        }

        // MARK: - Connections (кости)
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

        ctx.setLineWidth(3)
        ctx.setStrokeColor(UIColor(white: 1.0, alpha: 0.9).cgColor)

        for (a, b) in connections {
            if let pa = points[a], let pb = points[b] {
                let va = mapPointFlipped(pa)
                let vb = mapPointFlipped(pb)
                ctx.move(to: va)
                ctx.addLine(to: vb)
                ctx.strokePath()
            }
        }

        for (joint, p) in points {

            let conf = confidences[joint] ?? minVisibleConfidence

            let minR: CGFloat = 6
            let maxR: CGFloat = 16
            let radius = minR + (maxR - minR) * min(1, max(0, conf))

            let v = mapPointFlipped(p)

            ctx.saveGState()
            ctx.setShadow(
                offset: .zero,
                blur: 6,
                color: UIColor.black.withAlphaComponent(0.6).cgColor
            )

            ctx.setFillColor(UIColor.app.withAlphaComponent(0.95).cgColor)
            ctx.addEllipse(
                in: CGRect(
                    x: v.x - radius / 2,
                    y: v.y - radius / 2,
                    width: radius,
                    height: radius
                )
            )
            ctx.drawPath(using: .fill)
            ctx.restoreGState()

            ctx.setLineWidth(2)
            ctx.setStrokeColor(UIColor.white.cgColor)
            ctx.addEllipse(
                in: CGRect(
                    x: v.x - radius / 2,
                    y: v.y - radius / 2,
                    width: radius,
                    height: radius
                )
            )
            ctx.strokePath()

            // low confidence marker
            if conf < 0.2 {
                ctx.setFillColor(
                    UIColor.systemYellow.withAlphaComponent(0.9).cgColor
                )
                let innerR = radius * 0.5
                ctx.addEllipse(
                    in: CGRect(
                        x: v.x - innerR / 2,
                        y: v.y - innerR / 2,
                        width: innerR,
                        height: innerR
                    )
                )
                ctx.drawPath(using: .fill)
            }
        }

        let img = UIGraphicsGetImageFromCurrentImageContext()?.cgImage
        UIGraphicsEndImageContext()
        return img
    }

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

    private func debugSessionStatus() {
        print("=== Camera debug ===")
        let session = cameraManager.captureSession
        print("session running:", session.isRunning)
        print("inputs:", session.inputs.count)
        print("outputs:", session.outputs.count)
    }
}

extension PushupCameraViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard let pixel = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        processFrame(pixelBuffer: pixel)
    }
}
