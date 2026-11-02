import AVFoundation
import SwiftUI
import UIKit

/// Kamera für Foto und Live-Barcode (AVFoundation).
final class CameraModel: NSObject, ObservableObject {
    enum Access { case unknown, granted, denied, unavailable }

    let session = AVCaptureSession()
    @Published private(set) var access: Access = .unknown
    @Published private(set) var torchOn = false
    /// Zuletzt live erkannter Barcode (nur im Barcode-Modus).
    @Published var detectedBarcode: String?

    /// Wird vom Screen gesetzt; nur dann werden Barcodes gemeldet.
    var barcodeMode = false

    private let photoOutput = AVCapturePhotoOutput()
    private let metadataOutput = AVCaptureMetadataOutput()
    private let queue = DispatchQueue(label: "dosenjaeger.camera")
    private var device: AVCaptureDevice?
    private var configured = false
    private var photoContinuation: CheckedContinuation<UIImage?, Never>?

    @MainActor
    func start() async {
        var granted = AVCaptureDevice.authorizationStatus(for: .video) == .authorized
        if AVCaptureDevice.authorizationStatus(for: .video) == .notDetermined {
            granted = await AVCaptureDevice.requestAccess(for: .video)
        }
        guard granted else {
            access = .denied
            return
        }
        guard AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) != nil else {
            access = .unavailable
            return
        }
        access = .granted
        queue.async { [weak self] in
            guard let self else { return }
            self.configureIfNeeded()
            if !self.session.isRunning { self.session.startRunning() }
        }
    }

    func stop() {
        queue.async { [weak self] in
            guard let self, self.session.isRunning else { return }
            self.session.stopRunning()
        }
    }

    private func configureIfNeeded() {
        guard !configured else { return }
        configured = true
        session.beginConfiguration()
        session.sessionPreset = .photo
        defer { session.commitConfiguration() }

        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: camera),
              session.canAddInput(input) else { return }
        device = camera
        session.addInput(input)

        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
        }
        if session.canAddOutput(metadataOutput) {
            session.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(self, queue: .main)
            let wanted: [AVMetadataObject.ObjectType] = [.ean13, .ean8, .upce]
            metadataOutput.metadataObjectTypes = wanted.filter { metadataOutput.availableMetadataObjectTypes.contains($0) }
        }
    }

    /// Nimmt ein Foto auf. Liefert nil, wenn die Kamera nicht läuft.
    @MainActor
    func capturePhoto() async -> UIImage? {
        guard access == .granted, photoContinuation == nil else { return nil }
        return await withCheckedContinuation { continuation in
            photoContinuation = continuation
            queue.async { [weak self] in
                guard let self else { return }
                guard self.session.isRunning, !self.photoOutput.connections.isEmpty else {
                    DispatchQueue.main.async { self.finishCapture(nil) }
                    return
                }
                self.photoOutput.capturePhoto(with: AVCapturePhotoSettings(), delegate: self)
            }
        }
    }

    private func finishCapture(_ image: UIImage?) {
        photoContinuation?.resume(returning: image)
        photoContinuation = nil
    }

    func toggleTorch() {
        guard let device, device.hasTorch else { return }
        let newValue = !torchOn
        do {
            try device.lockForConfiguration()
            device.torchMode = newValue ? .on : .off
            device.unlockForConfiguration()
            torchOn = newValue
        } catch {
            torchOn = false
        }
    }
}

extension CameraModel: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        let image = photo.fileDataRepresentation().flatMap { UIImage(data: $0) }
        DispatchQueue.main.async { self.finishCapture(image) }
    }
}

extension CameraModel: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput,
                        didOutput metadataObjects: [AVMetadataObject],
                        from connection: AVCaptureConnection) {
        guard barcodeMode,
              let code = metadataObjects.compactMap({ ($0 as? AVMetadataMachineReadableCodeObject)?.stringValue }).first,
              code != detectedBarcode else { return }
        detectedBarcode = code
    }
}

/// Live-Vorschau der Kamera.
struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        view.backgroundColor = .black
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {}

    final class PreviewView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
    }
}
