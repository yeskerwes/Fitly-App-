// PushupCameraViewController.swift
// (полный файл — изменён для воспроизведения звуков)

import UIKit
import AVFoundation
import Vision
import CoreImage

final class PushupCameraViewController: UIViewController {

    // MARK: - Public
    weak var delegate: PushupCameraDelegate?

    /// Daily target (reps per day) passed from ChallengeDetailViewController
    var dailyTarget: Int?

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

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        l.textColor = .white
        l.text = "Push Up"
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let bigCountLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.boldSystemFont(ofSize: 120)
        l.textColor = .white
        l.text = "0"
        l.translatesAutoresizingMaskIntoConstraints = false
        l.adjustsFontSizeToFitWidth = true
        l.minimumScaleFactor = 0.4
        l.textAlignment = .right
        return l
    }()

    private let fractionLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 28, weight: .semibold)
        l.textColor = UIColor(white: 1, alpha: 0.8)
        l.text = "/0"
        l.translatesAutoresizingMaskIntoConstraints = false
        l.textAlignment = .left
        return l
    }()

    private let smallProgressBar: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(white: 1, alpha: 0.15)
        v.layer.cornerRadius = 2
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let smallProgressFill: UIView = {
        let v = UIView()
        v.backgroundColor = .systemGreen
        v.layer.cornerRadius = 2
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private var smallProgressFillWidthConstraint: NSLayoutConstraint?

    private let infoButton: UIButton = {
        let b = UIButton(type: .system)
        b.setImage(UIImage(systemName: "info"), for: .normal)
        b.tintColor = .black
        b.backgroundColor = .systemGreen
        b.layer.cornerRadius = 28
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    private let endSessionButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("END SESSION", for: .normal)
        b.setTitleColor(.white, for: .normal)
        b.backgroundColor = .systemGreen
        b.layer.cornerRadius = 28
        b.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    private let cameraWarningLabel: UILabel = {
        let l = UILabel()
        l.text = "Camera can make mistakes.\nWe recommend checking the camera position."
        l.numberOfLines = 2
        l.font = UIFont.systemFont(ofSize: 13)
        l.textColor = .white
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    // MARK: - Camera / Vision
    private let cameraManager = CameraSessionManager()
    private let videoQueue = DispatchQueue(label: "fitly.camera.queue")
    private let sequenceHandler = VNSequenceRequestHandler()

    // MARK: - Counting logic
    private var repCount: Int = 0 {
        didSet {
            DispatchQueue.main.async {
                self.countLabel.text = "\(self.repCount)"
                self.bigCountLabel.text = "\(self.repCount)"
                self.updateCounterUI()
            }
        }
    }

    // Flag to ensure congrats alert displayed only once per session
    private var didShowDailyCompleteAlert = false

    // NOTE: adjusted thresholds — easier to register
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

    // MARK: - Debug
    private var frameCounter = 0
    private var debugLogs = false

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        // Prepare sounds early (assumes files "ding" and "succes" exist in bundle)
        SoundManager.shared.prepareSounds(dingName: "ding", successName: "succes")

        setupUI()
        observeCameraNotifications()
        checkCameraPermissionAndConfigure()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        cameraManager.previewLayer.frame = previewContainer.bounds
        overlayView.frame = previewContainer.bounds
        updateCounterUI()
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

        view.addSubview(titleLabel)
        view.addSubview(bigCountLabel)
        view.addSubview(fractionLabel)
        view.addSubview(smallProgressBar)
        smallProgressBar.addSubview(smallProgressFill)
        view.addSubview(countLabel)
        view.addSubview(endSessionButton)
        view.addSubview(infoButton)
        view.addSubview(cameraWarningLabel)

        NSLayoutConstraint.activate([
            previewContainer.topAnchor.constraint(equalTo: view.topAnchor),
            previewContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            previewContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            previewContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            overlayView.topAnchor.constraint(equalTo: previewContainer.topAnchor),
            overlayView.leadingAnchor.constraint(equalTo: previewContainer.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: previewContainer.trailingAnchor),
            overlayView.bottomAnchor.constraint(equalTo: previewContainer.bottomAnchor),

            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            bigCountLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
            bigCountLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: -10),
            bigCountLabel.heightAnchor.constraint(equalToConstant: 140),
            bigCountLabel.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, multiplier: 0.8),

            fractionLabel.leadingAnchor.constraint(equalTo: bigCountLabel.trailingAnchor, constant: 6),
            fractionLabel.bottomAnchor.constraint(equalTo: bigCountLabel.bottomAnchor, constant: -28),

            smallProgressBar.topAnchor.constraint(equalTo: bigCountLabel.bottomAnchor, constant: 6),
            smallProgressBar.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            smallProgressBar.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.5),
            smallProgressBar.heightAnchor.constraint(equalToConstant: 4),

            countLabel.topAnchor.constraint(equalTo: smallProgressBar.bottomAnchor, constant: 6),
            countLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            endSessionButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -40),
            endSessionButton.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: -40),
            endSessionButton.heightAnchor.constraint(equalToConstant: 64),
            endSessionButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.6),

            infoButton.centerYAnchor.constraint(equalTo: endSessionButton.centerYAnchor),
            infoButton.leadingAnchor.constraint(equalTo: endSessionButton.trailingAnchor, constant: 12),
            infoButton.widthAnchor.constraint(equalToConstant: 56),
            infoButton.heightAnchor.constraint(equalToConstant: 56),

            cameraWarningLabel.bottomAnchor.constraint(equalTo: endSessionButton.topAnchor, constant: -12),
            cameraWarningLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            cameraWarningLabel.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.9)
        ])

        smallProgressFill.leadingAnchor.constraint(equalTo: smallProgressBar.leadingAnchor).isActive = true
        smallProgressFill.topAnchor.constraint(equalTo: smallProgressBar.topAnchor).isActive = true
        smallProgressFill.bottomAnchor.constraint(equalTo: smallProgressBar.bottomAnchor).isActive = true
        smallProgressFillWidthConstraint = smallProgressFill.widthAnchor.constraint(equalToConstant: 0)
        smallProgressFillWidthConstraint?.isActive = true

        endSessionButton.addTarget(self, action: #selector(doneTapped), for: .touchUpInside)
        infoButton.addTarget(self, action: #selector(infoTapped), for: .touchUpInside)

        let dbl = UITapGestureRecognizer(target: self, action: #selector(cancelTapped))
        dbl.numberOfTapsRequired = 2
        view.addGestureRecognizer(dbl)
    }

    private func updateCounterUI() {
        DispatchQueue.main.async {
            let total = self.dailyTarget ?? 0
            self.fractionLabel.text = "/\(total)"
            let barW = self.smallProgressBar.bounds.width
            let percent: CGFloat
            if total <= 0 { percent = 0 }
            else { percent = CGFloat(min(self.repCount, total)) / CGFloat(total) }
            let fillW = barW * percent
            self.smallProgressFillWidthConstraint?.constant = fillW
            UIView.animate(withDuration: 0.12) {
                self.smallProgressBar.layoutIfNeeded()
            }
        }
    }

    @objc private func infoTapped() {
        let ac = UIAlertController(title: "Info", message: "Camera can make mistakes. Keep full body visible.", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
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

            if self.debugLogs { self.debugSessionStatus() }

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
        endSessionButton.isEnabled = false
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

    // MARK: - Pose handling (capture-device normalized coords)
    private func handlePoseObservation(_ obs: VNHumanBodyPoseObservation) {
        var detected: [VNHumanBodyPoseObservation.JointName: (point: CGPoint, confidence: CGFloat)] = [:]
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
                    let smoothedX = positionSmoothingAlpha * det.point.x + (1 - positionSmoothingAlpha) * last.x
                    let smoothedY = positionSmoothingAlpha * det.point.y + (1 - positionSmoothingAlpha) * last.y
                    mergedPoints[name] = CGPoint(x: smoothedX, y: smoothedY)
                } else {
                    mergedPoints[name] = det.point
                }
                mergedConf[name] = det.confidence
            } else if let last = lastKnownPoints[name] {
                mergedPoints[name] = last
                let lastConf = lastKnownConfidences[name] ?? 0.0
                mergedConf[name] = max( minVisibleConfidence, lastConf * 0.85 )
            }
        }

        lastKnownPoints = mergedPoints
        lastKnownConfidences = mergedConf

        var angles: [CGFloat] = []
        if let s = mergedPoints[.leftShoulder], let e = mergedPoints[.leftElbow], let w = mergedPoints[.leftWrist] {
            angles.append(angleBetween(a: s, b: e, c: w))
        }
        if let s = mergedPoints[.rightShoulder], let e = mergedPoints[.rightElbow], let w = mergedPoints[.rightWrist] {
            angles.append(angleBetween(a: s, b: e, c: w))
        }

        guard !angles.isEmpty else {
            DispatchQueue.main.async { self.overlayView.updateImage(nil) }
            return
        }

        let chosen = angles.reduce(0, +) / CGFloat(angles.count)
        smoothedAngle = angleSmoothingAlpha * chosen + (1 - angleSmoothingAlpha) * smoothedAngle

        DispatchQueue.main.async {
            if self.smoothedAngle < self.downThreshold {
                self.armWasDown = true
            } else if self.armWasDown && self.smoothedAngle > self.upThreshold {
                self.repCount += 1
                self.armWasDown = false

                // play per-rep sound
                SoundManager.shared.playDing()

                // Check daily target and show congrats
                if let target = self.dailyTarget, target > 0, self.repCount >= target, !self.didShowDailyCompleteAlert {
                    self.didShowDailyCompleteAlert = true

                    // play success sound, then show alert
                    SoundManager.shared.playSuccess()
                    self.showDailyCompletionAlert()
                }
            }

            let img = self.drawSkeleton(points: mergedPoints, confidences: mergedConf, rep: self.repCount)
            self.overlayView.updateImage(img)
        }
    }

    // show alert and then auto-finish session
    private func showDailyCompletionAlert() {
        let ac = UIAlertController(title: "Congratulations!", message: "You've completed today's target.", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            // Save & finish session as if user tapped Done
            self.cameraManager.stopRunning()
            CoreDataManager.shared.createPushupSession(count: self.repCount, date: Date())
            DispatchQueue.main.async {
                self.delegate?.pushupSessionDidFinish(count: self.repCount)
                self.dismiss(animated: true)
            }
        })
        if presentedViewController == nil {
            present(ac, animated: true)
        }
    }

    // MARK: - Draw skeleton (flip both then convert)
    private func drawSkeleton(points: [VNHumanBodyPoseObservation.JointName: CGPoint],
                              confidences: [VNHumanBodyPoseObservation.JointName: CGFloat],
                              rep: Int) -> CGImage? {
        let size = overlayView.bounds.size
        guard size.width > 0 && size.height > 0 else { return nil }

        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        guard let ctx = UIGraphicsGetCurrentContext() else { UIGraphicsEndImageContext(); return nil }

        ctx.setLineWidth(3)
        ctx.setStrokeColor(UIColor.systemGreen.cgColor)
        ctx.setFillColor(UIColor.systemGreen.cgColor)

        func mapPointFlipped(_ p: CGPoint) -> CGPoint {
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

        ctx.setLineWidth(3)
        ctx.setStrokeColor(UIColor(white: 1.0, alpha: 0.9).cgColor)
        for (a, b) in connections {
            if let pa = points[a], let pb = points[b] {
                let va = mapPointFlipped(pa)
                let vb = mapPointFlipped(pb)
                ctx.move(to: va); ctx.addLine(to: vb); ctx.strokePath()
            }
        }

        for (joint, p) in points {
            let conf = confidences[joint] ?? minVisibleConfidence
            let minR: CGFloat = 6
            let maxR: CGFloat = 16
            let radius = minR + (maxR - minR) * CGFloat(min(1.0, max(0.0, conf)))

            let v = mapPointFlipped(p)

            ctx.saveGState()
            ctx.setShadow(offset: .zero, blur: 6, color: UIColor.black.withAlphaComponent(0.6).cgColor)

            let fillColor = UIColor.systemGreen.withAlphaComponent(0.95).cgColor
            ctx.setFillColor(fillColor)
            ctx.addEllipse(in: CGRect(x: v.x - radius/2, y: v.y - radius/2, width: radius, height: radius))
            ctx.drawPath(using: .fill)

            ctx.restoreGState()

            ctx.setLineWidth(2)
            ctx.setStrokeColor(UIColor.white.cgColor)
            ctx.addEllipse(in: CGRect(x: v.x - radius/2, y: v.y - radius/2, width: radius, height: radius))
            ctx.strokePath()

            if conf < 0.2 {
                ctx.setFillColor(UIColor.systemYellow.withAlphaComponent(0.9).cgColor)
                let innerR = radius * 0.5
                ctx.addEllipse(in: CGRect(x: v.x - innerR/2, y: v.y - innerR/2, width: innerR, height: innerR))
                ctx.drawPath(using: .fill)
            }
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
        let cosA = max(-1, min(1, dot / (m1 * m2)))
        return acos(cosA) * 180 / .pi
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
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension PushupCameraViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixel = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        processFrame(pixelBuffer: pixel)
    }
}
