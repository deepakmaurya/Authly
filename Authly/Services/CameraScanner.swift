import Foundation
import AVFoundation
import CoreImage
import AppKit

final class CameraScanner: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    @Published private(set) var lastPayload: String?
    @Published private(set) var error: String?
    @Published private(set) var isAuthorized: Bool = false

    let session = AVCaptureSession()
    private let videoQueue = DispatchQueue(label: "com.mg.Authly.camera.video")
    private var configured = false
    private var seenPayloads = Set<String>()

    private let detector = CIDetector(
        ofType: CIDetectorTypeQRCode,
        context: CIContext(),
        options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])

    private var lastDetectionAt: CFTimeInterval = 0
    private let detectionInterval: CFTimeInterval = 0.25  // ~4 detections/sec is plenty

    func start() {
        requestAccess { [weak self] granted in
            guard let self else { return }
            DispatchQueue.main.async { self.isAuthorized = granted }
            guard granted else {
                DispatchQueue.main.async { self.error = "Camera access denied. Enable it in System Settings → Privacy & Security → Camera." }
                return
            }
            self.configureIfNeeded()
            if !self.session.isRunning {
                DispatchQueue.global(qos: .userInitiated).async { self.session.startRunning() }
            }
        }
    }

    func stop() {
        if session.isRunning {
            DispatchQueue.global(qos: .userInitiated).async { self.session.stopRunning() }
        }
    }

    func reset() {
        seenPayloads.removeAll()
        DispatchQueue.main.async { self.lastPayload = nil }
    }

    private func requestAccess(_ completion: @escaping (Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: completion(true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { completion($0) }
        default: completion(false)
        }
    }

    private func configureIfNeeded() {
        guard !configured else { return }
        configured = true

        session.beginConfiguration()
        session.sessionPreset = .high

        guard let device = AVCaptureDevice.default(for: .video) else {
            session.commitConfiguration()
            DispatchQueue.main.async { self.error = "No camera found." }
            return
        }

        do {
            let input = try AVCaptureDeviceInput(device: device)
            if session.canAddInput(input) { session.addInput(input) }
        } catch {
            session.commitConfiguration()
            DispatchQueue.main.async { self.error = error.localizedDescription }
            return
        }

        let output = AVCaptureVideoDataOutput()
        output.alwaysDiscardsLateVideoFrames = true
        output.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        output.setSampleBufferDelegate(self, queue: videoQueue)
        if session.canAddOutput(output) { session.addOutput(output) }

        session.commitConfiguration()
    }

    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        let now = CACurrentMediaTime()
        if now - lastDetectionAt < detectionInterval { return }
        lastDetectionAt = now

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        guard let features = detector?.features(in: ciImage) else { return }

        for case let qr as CIQRCodeFeature in features {
            guard let payload = qr.messageString else { continue }
            if seenPayloads.insert(payload).inserted {
                DispatchQueue.main.async { self.lastPayload = payload }
            }
        }
    }
}
