import Foundation
import AppKit
import CoreImage

enum QRImageScanner {
    /// Scan all QR codes in an image file and return decoded string payloads.
    static func scanFile(at url: URL) -> [String] {
        guard let image = NSImage(contentsOf: url) else { return [] }
        return scan(image: image)
    }

    static func scan(image: NSImage) -> [String] {
        guard let tiff = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiff),
              let cg = bitmap.cgImage else { return [] }
        let ci = CIImage(cgImage: cg)

        let context = CIContext()
        let detector = CIDetector(
            ofType: CIDetectorTypeQRCode,
            context: context,
            options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])
        let features = detector?.features(in: ci) ?? []
        return features.compactMap { ($0 as? CIQRCodeFeature)?.messageString }
    }
}
