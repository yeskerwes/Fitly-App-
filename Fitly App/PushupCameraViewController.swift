//
//  Untitled.swift
//  Fitly App
//
//  Created by Bakdaulet Yeskermes on 07.12.2025.
//

//import UIKit
//import AVFoundation
//import Vision
//
//protocol PushupCameraDelegate: AnyObject {
//    func pushupSessionDidFinish(count: Int)
//    func pushupSessionDidCancel()
//}
//
//final class PushupCameraViewController: UIViewController {
//
//    // MARK: - Public
//    weak var delegate: PushupCameraDelegate?
//
//    // MARK: - UI
//    private let previewView = UIView()
//    private let overlayLayer = CALayer()
//    private let countLabel: UILabel = {
//        let l = UILabel()
//        l.font = .boldSystemFont(ofSize: 34)
//        l.textColor = .white
//        l.text = "0"
//        l.translatesAutoresizingMaskIntoConstraints = false
//        return l
//    }()
//    private let doneButton: UIButton = {
//        let b = UIButton(type: .system)
//        b.setTitle("Done", for: .normal)
//        b.setTitleColor(.white, for: .normal)
//        b.backgroundColor = UIColor.systemBlue
//        b.layer.cornerRadius = 10
//        b.translatesAutoresizingMaskIntoConstraints = false
//        return b
//    }()
//
//    // MARK: - AV / Vision
//    private let captureSession = AVCaptureSession()
//    private var previewLayer: AVCaptureVideoPreviewLayer?
//    private var videoOutput: AVCaptureVideoDataOutput?
//    private let videoQueue = DispatchQueue(label: "fitly.camera.queue")
//    private let sequenceHandler = VNSequenceRequestHandler()
//    private var usingFrontCamera = false
//
//    // MARK: - Counting logic
//    private var repCount: Int = 0 {
//        didSet { DispatchQueue.main.async { self.countLabel.text = "\(self.repCount)" } }
//    }
//    private var smoothedAngle: CGFloat = 170
//    private var armWasDown = false
//    private let downThreshold: CGFloat = 80
//    private let upThreshold: CGFloat = 150
//    private let smoothingAlpha: CGFloat = 0.2
//
//    // MARK: - Lifecycle
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        view.backgroundColor = .black
//        setupUI()
//        checkCameraPermissionAndConfigure()
//    }
//
//    override func viewDidLayoutSubviews() {
//        super.viewDidLayoutSubviews()
//        previewLayer?.frame = previewView.bounds
//        overlayLayer.frame = previewView.bounds
//    }
//
//    deinit {
//        stopSession()
//    }
//
//    // MARK: - UI
//    private func setupUI() {
//        previewView.translatesAutoresizingMaskIntoConstraints = false
//        previewView.clipsToBounds = true
//        view.addSubview(previewView)
//        view.addSubview(countLabel)
//        view.addSubview(doneButton)
//
//        overlayLayer.frame = previewView.bounds
//        previewView.layer.addSublayer(overlayLayer)
//
//        NSLayoutConstraint.activate([
//            previewView.topAnchor.constraint(equalTo: view.topAnchor),
//            previewView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//            previewView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
//            previewView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
//
//            countLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
//            countLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//
//            doneButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
//            doneButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//            doneButton.widthAnchor.constraint(equalToConstant: 120),
//            doneButton.heightAnchor.constraint(equalToConstant: 44)
//        ])
//
//        doneButton.addTarget(self, action: #selector(doneTapped), for: .touchUpInside)
//
//        let dblTap = UITapGestureRecognizer(target: self, action: #selector(cancelTapped))
//        dblTap.numberOfTapsRequired = 2
//        view.addGestureRecognizer(dblTap)
//    }
//
//    // MARK: - Permissions & Session
//    private func checkCameraPermissionAndConfigure() {
//        switch AVCaptureDevice.authorizationStatus(for: .video) {
//        case .authorized:
//            configureSession()
//        case .notDetermined:
//            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
//                DispatchQueue.main.async {
//                    granted ? self?.configureSession() : self?.showPermissionAlert()
//                }
//            }
//        default:
//            showPermissionAlert()
//        }
//    }
//
//    private func showPermissionAlert() {
//        let ac = UIAlertController(title: "Camera Access Required",
//                                   message: "Enable camera access in Settings to count push-ups.",
//                                   preferredStyle: .alert)
//        ac.addAction(UIAlertAction(title: "OK", style: .default) { _ in
//            self.delegate?.pushupSessionDidCancel()
//            self.dismiss(animated: true, completion: nil)
//        })
//        present(ac, animated: true, completion: nil)
//    }
//
//    private func configureSession() {
//        videoQueue.async { [weak self] in
//            guard let self = self else { return }
//            self.captureSession.beginConfiguration()
//            self.captureSession.sessionPreset = .high
//
//            // Clear previous inputs/outputs
//            for input in self.captureSession.inputs { self.captureSession.removeInput(input) }
//            for output in self.captureSession.outputs { self.captureSession.removeOutput(output) }
//
//            // Prefer front camera
//            var chosenDevice: AVCaptureDevice?
//            if let front = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) {
//                chosenDevice = front
//                self.usingFrontCamera = true
//            } else if let back = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
//                chosenDevice = back
//                self.usingFrontCamera = false
//            }
//
//            guard let device = chosenDevice else {
//                self.captureSession.commitConfiguration()
//                DispatchQueue.main.async {
//                    self.presentErrorAndClose("No camera device available.")
//                }
//                return
//            }
//
//            do {
//                let input = try AVCaptureDeviceInput(device: device)
//                if self.captureSession.canAddInput(input) {
//                    self.captureSession.addInput(input)
//                }
//
//                let vOutput = AVCaptureVideoDataOutput()
//                vOutput.alwaysDiscardsLateVideoFrames = true
//                vOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
//                vOutput.setSampleBufferDelegate(self, queue: self.videoQueue)
//
//                if self.captureSession.canAddOutput(vOutput) {
//                    self.captureSession.addOutput(vOutput)
//                    self.videoOutput = vOutput
//                }
//
//                self.captureSession.commitConfiguration()
//
//                // attach preview and start on main thread
//                DispatchQueue.main.async {
//                    self.attachPreviewLayer(usingFront: self.usingFrontCamera)
//                    // set video orientation and mirroring for output connection
//                    if let outConn = self.videoOutput?.connection(with: .video) {
//                        outConn.videoOrientation = .portrait
//                        outConn.isVideoMirrored = self.usingFrontCamera
//                    }
//                    // start running on background queue
//                    self.videoQueue.async {
//                        if !self.captureSession.isRunning {
//                            self.captureSession.startRunning()
//                        }
//                    }
//                }
//            } catch {
//                self.captureSession.commitConfiguration()
//                DispatchQueue.main.async {
//                    self.presentErrorAndClose("Failed to access camera input: \(error.localizedDescription)")
//                }
//            }
//        }
//    }
//
//    private func attachPreviewLayer(usingFront: Bool) {
//        // remove previous preview layer
//        previewLayer?.removeFromSuperlayer()
//
//        let pl = AVCaptureVideoPreviewLayer(session: captureSession)
//        pl.videoGravity = .resizeAspectFill
//        pl.frame = previewView.bounds
//
//        if let conn = pl.connection {
//            conn.videoOrientation = .portrait
//            conn.isVideoMirrored = usingFront
//        } else if usingFront {
//            // fallback: flip horizontally
//            pl.setAffineTransform(CGAffineTransform(scaleX: -1, y: 1))
//        }
//
//        previewView.layer.insertSublayer(pl, at: 0)
//        previewLayer = pl
//
//        // bring overlay above preview
//        overlayLayer.removeFromSuperlayer()
//        previewView.layer.addSublayer(overlayLayer)
//        overlayLayer.frame = previewView.bounds
//    }
//
//    private func presentErrorAndClose(_ message: String) {
//        let ac = UIAlertController(title: "Camera error", message: message, preferredStyle: .alert)
//        ac.addAction(UIAlertAction(title: "OK", style: .default) { _ in
//            self.delegate?.pushupSessionDidCancel()
//            self.dismiss(animated: true, completion: nil)
//        })
//        present(ac, animated: true, completion: nil)
//    }
//
//    private func stopSession() {
//        videoQueue.async {
//            if self.captureSession.isRunning {
//                self.captureSession.stopRunning()
//            }
//        }
//    }
//
//    // MARK: - Actions
//    @objc private func doneTapped() {
//        stopSession()
//        delegate?.pushupSessionDidFinish(count: repCount)
//        dismiss(animated: true, completion: nil)
//    }
//
//    @objc private func cancelTapped() {
//        stopSession()
//        delegate?.pushupSessionDidCancel()
//        dismiss(animated: true, completion: nil)
//    }
//
//    // MARK: - Vision processing (single entry point)
//    private func processFrame(pixelBuffer: CVPixelBuffer) {
//        // single implementation — no duplicates
//        let request = VNDetectHumanBodyPoseRequest()
//        do {
//            try sequenceHandler.perform([request], on: pixelBuffer)
//            guard let observation = request.results?.first else {
//                DispatchQueue.main.async { [weak self] in self?.overlayLayer.contents = nil }
//                return
//            }
//            handlePoseObservation(observation)
//        } catch {
//            // ignore transient vision errors
//        }
//    }
//
//    private func handlePoseObservation(_ obs: VNHumanBodyPoseObservation) {
//        // Try to read left and right elbow angles; draw full-body overlay
//        var points: [VNHumanBodyPoseObservation.JointName: CGPoint] = [:]
//        let jointNames: [VNHumanBodyPoseObservation.JointName] = [
//            .nose, .leftEye, .rightEye, .leftEar, .rightEar,
//            .leftShoulder, .rightShoulder, .leftElbow, .rightElbow,
//            .leftWrist, .rightWrist, .leftHip, .rightHip,
//            .leftKnee, .rightKnee, .leftAnkle, .rightAnkle
//        ]
//        for name in jointNames {
//            if let p = try? obs.recognizedPoint(name), p.confidence >= 0.15 {
//                // convert to top-left normalized coords
//                points[name] = CGPoint(x: p.x, y: 1 - p.y)
//            }
//        }
//
//        // compute elbow angles (if available)
//        var angles: [CGFloat] = []
//        if let s = points[.leftShoulder], let e = points[.leftElbow], let w = points[.leftWrist] {
//            angles.append(angleBetween(a: s, b: e, c: w))
//        }
//        if let s = points[.rightShoulder], let e = points[.rightElbow], let w = points[.rightWrist] {
//            angles.append(angleBetween(a: s, b: e, c: w))
//        }
//
//        guard !angles.isEmpty else {
//            DispatchQueue.main.async { self.overlayLayer.contents = nil }
//            return
//        }
//
//        // average available elbow angles
//        let chosen = angles.reduce(0, +) / CGFloat(angles.count)
//        smoothedAngle = smoothingAlpha * chosen + (1 - smoothingAlpha) * smoothedAngle
//
//        // FSM for rep counting
//        DispatchQueue.main.async {
//            if self.smoothedAngle < self.downThreshold {
//                self.armWasDown = true
//            } else if self.armWasDown && self.smoothedAngle > self.upThreshold {
//                self.repCount += 1
//                self.armWasDown = false
//            }
//            self.drawOverlay(points: points)
//        }
//    }
//
//    // MARK: - Drawing overlay
//    private func drawOverlay(points: [VNHumanBodyPoseObservation.JointName: CGPoint]) {
//        let size = overlayLayer.bounds.size
//        guard size.width > 0 && size.height > 0 else { return }
//        UIGraphicsBeginImageContextWithOptions(size, false, 0)
//        guard let ctx = UIGraphicsGetCurrentContext() else { UIGraphicsEndImageContext(); return }
//
//        ctx.setLineWidth(2)
//        ctx.setStrokeColor(UIColor.systemGreen.cgColor)
//        ctx.setFillColor(UIColor.systemGreen.cgColor)
//
//        func toView(_ p: CGPoint) -> CGPoint {
//            // if using front camera, mirror x so overlay matches preview
//            let normalizedX = usingFrontCamera ? (1 - p.x) : p.x
//            return CGPoint(x: normalizedX * size.width, y: p.y * size.height)
//        }
//
//        // skeleton connections
//        let connections: [(VNHumanBodyPoseObservation.JointName, VNHumanBodyPoseObservation.JointName)] = [
//            (.nose, .leftEye), (.nose, .rightEye),
//            (.leftEye, .leftEar), (.rightEye, .rightEar),
//            (.leftShoulder, .leftElbow), (.leftElbow, .leftWrist),
//            (.rightShoulder, .rightElbow), (.rightElbow, .rightWrist),
//            (.leftShoulder, .rightShoulder),
//            (.leftShoulder, .leftHip), (.rightShoulder, .rightHip),
//            (.leftHip, .rightHip),
//            (.leftHip, .leftKnee), (.leftKnee, .leftAnkle),
//            (.rightHip, .rightKnee), (.rightKnee, .rightAnkle)
//        ]
//
//        for (a, b) in connections {
//            if let pa = points[a], let pb = points[b] {
//                ctx.move(to: toView(pa)); ctx.addLine(to: toView(pb)); ctx.strokePath()
//            }
//        }
//
//        // draw points
//        for (_, p) in points {
//            let v = toView(p)
//            let r: CGFloat = 6
//            ctx.addEllipse(in: CGRect(x: v.x - r/2, y: v.y - r/2, width: r, height: r))
//            ctx.drawPath(using: .fill)
//        }
//
//        // draw rep count
//        let text = "Reps: \(repCount)"
//        let attrs: [NSAttributedString.Key: Any] = [
//            .font: UIFont.boldSystemFont(ofSize: 14),
//            .foregroundColor: UIColor.white
//        ]
//        text.draw(at: CGPoint(x: 8, y: 8), withAttributes: attrs)
//
//        let image = UIGraphicsGetImageFromCurrentImageContext()
//        UIGraphicsEndImageContext()
//        overlayLayer.contents = image?.cgImage
//    }
//
//    // MARK: - Math helper
//    private func angleBetween(a: CGPoint, b: CGPoint, c: CGPoint) -> CGFloat {
//        let v1 = CGVector(dx: a.x - b.x, dy: a.y - b.y)
//        let v2 = CGVector(dx: c.x - b.x, dy: c.y - b.y)
//        let dot = v1.dx * v2.dx + v1.dy * v2.dy
//        let m1 = hypot(v1.dx, v1.dy)
//        let m2 = hypot(v2.dx, v2.dy)
//        guard m1 > 1e-4 && m2 > 1e-4 else { return 180 }
//        let cosA = max(-1, min(1, dot / (m1 * m2)))
//        return acos(cosA) * 180 / .pi
//    }
//}
//
//// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
//extension PushupCameraViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
//    public func captureOutput(_ output: AVCaptureOutput,
//                              didOutput sampleBuffer: CMSampleBuffer,
//                              from connection: AVCaptureConnection) {
//        // single framed entry point — no other process functions
//        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
//        processFrame(pixelBuffer: pixelBuffer)
//    }
//}
