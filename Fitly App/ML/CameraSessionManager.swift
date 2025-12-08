//
//  CameraSessionManager.swift
//  Fitly App
//
//  Created by Bakdaulet Yeskermes on 08.12.2025.
//

import AVFoundation
import UIKit

final class CameraSessionManager: NSObject {
    let captureSession = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let sessionQueue = DispatchQueue(label: "fitly.camera.session")
    private(set) var usingFrontCamera = false

    lazy var previewLayer: AVCaptureVideoPreviewLayer = {
        let pl = AVCaptureVideoPreviewLayer(session: captureSession)
        pl.videoGravity = .resizeAspectFill
        return pl
    }()

    override init() {
        super.init()
    }

    /// Configure session asynchronously. Completion is signaled via NotificationCenter.
    func configureSession(preferredPosition: AVCaptureDevice.Position = .front,
                          sampleBufferDelegate: AVCaptureVideoDataOutputSampleBufferDelegate?,
                          delegateQueue: DispatchQueue?) {
        sessionQueue.async {
            self.captureSession.beginConfiguration()
            self.captureSession.sessionPreset = .high

            for input in self.captureSession.inputs { self.captureSession.removeInput(input) }
            for output in self.captureSession.outputs { self.captureSession.removeOutput(output) }

            var chosen: AVCaptureDevice?
            if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: preferredPosition) {
                chosen = device
                self.usingFrontCamera = (preferredPosition == .front)
            } else if let other = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
                chosen = other
                self.usingFrontCamera = (other.position == .front)
            }

            guard let device = chosen else {
                self.captureSession.commitConfiguration()
                DispatchQueue.main.async { NotificationCenter.default.post(name: .cameraSessionConfigurationFailed, object: nil) }
                return
            }

            do {
                let input = try AVCaptureDeviceInput(device: device)
                if self.captureSession.canAddInput(input) {
                    self.captureSession.addInput(input)
                }

                self.videoOutput.alwaysDiscardsLateVideoFrames = true
                self.videoOutput.videoSettings = [
                    kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
                ]
                if let delegate = sampleBufferDelegate {
                    self.videoOutput.setSampleBufferDelegate(delegate, queue: delegateQueue ?? self.sessionQueue)
                }
                if self.captureSession.canAddOutput(self.videoOutput) {
                    self.captureSession.addOutput(self.videoOutput)
                }

                self.captureSession.commitConfiguration()
                DispatchQueue.main.async {
                    // configure output connection after commit
                    if let vConn = self.videoOutput.connection(with: .video) {
                        if vConn.automaticallyAdjustsVideoMirroring {
                            vConn.automaticallyAdjustsVideoMirroring = false
                        }
                        if vConn.isVideoOrientationSupported {
                            vConn.videoOrientation = .portrait
                        }
                        if vConn.isVideoMirroringSupported {
                            vConn.isVideoMirrored = self.usingFrontCamera
                        }
                    }
                    NotificationCenter.default.post(name: .cameraSessionConfigurationCompleted, object: nil)
                }
            } catch {
                self.captureSession.commitConfiguration()
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .cameraSessionConfigurationFailed, object: error)
                }
            }
        }
    }

    func startRunning() {
        sessionQueue.async {
            if !self.captureSession.isRunning {
                self.captureSession.startRunning()
            }
        }
    }

    func stopRunning() {
        sessionQueue.async {
            if self.captureSession.isRunning {
                self.captureSession.stopRunning()
            }
        }
    }
}

extension Notification.Name {
    static let cameraSessionConfigurationCompleted = Notification.Name("cameraSessionConfigurationCompleted")
    static let cameraSessionConfigurationFailed = Notification.Name("cameraSessionConfigurationFailed")
}
