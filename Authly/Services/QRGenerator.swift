import Foundation
import AppKit
import CoreImage
import CoreImage.CIFilterBuiltins

enum QRGenerator {
    static func generate(from string: String, size: CGFloat = 320) -> NSImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        filter.correctionLevel = "M"
        guard let output = filter.outputImage else { return nil }

        let scale = size / output.extent.width
        let scaled = output.transformed(by: CGAffineTransform(scaleX: scale, y: scale))

        let context = CIContext()
        guard let cg = context.createCGImage(scaled, from: scaled.extent) else { return nil }
        let nsImage = NSImage(size: NSSize(width: size, height: size))
        nsImage.addRepresentation(NSBitmapImageRep(cgImage: cg))
        return nsImage
    }
}
