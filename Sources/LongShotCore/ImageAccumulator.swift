import Foundation
import CoreGraphics

public enum IngestStatus: Equatable { case first, appended(Int), stationary, reversed, unmatched, limit }
public final class ImageAccumulator {
    public private(set) var height = 0
    public private(set) var width = 0
    private let maxPixels: Int, maxHeight: Int
    private var previous: GrayFrame?
    private var strips: [CGImage] = []
    public init(maxPixels: Int = 80_000_000, maxHeight: Int = 40_000) {
        self.maxPixels = maxPixels; self.maxHeight = maxHeight
    }
    private func grayscale(_ image: CGImage) -> GrayFrame? {
        let w = min(128, image.width), h = image.height
        var data = [UInt8](repeating: 0, count: w * h)
        let success = data.withUnsafeMutableBytes { raw -> Bool in
            guard let ctx = CGContext(data: raw.baseAddress, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w, space: CGColorSpaceCreateDeviceGray(), bitmapInfo: 0) else { return false }
            ctx.interpolationQuality = .low
            ctx.draw(image, in: CGRect(x: 0, y: 0, width: w, height: h))
            return true
        }
        return success ? GrayFrame(width: w, height: h, pixels: data) : nil
    }
    public func ingest(_ image: CGImage) -> IngestStatus {
        guard image.width > 0, image.height > 0, image.height <= maxHeight,
              image.width <= maxPixels / image.height,
              let frame = grayscale(image) else { return .limit }
        guard let prior = previous else {
            width = image.width; height = image.height; previous = frame; strips = [image]
            return .first
        }
        guard image.width == width else { return .unmatched }
        switch FrameMatcher.match(previous: prior, next: frame) {
        case .stationary: return .stationary
        case .reversed: return .reversed
        case .unmatched: return .unmatched
        case .moved(let dy):
            guard height + dy <= maxHeight, width <= maxPixels / (height + dy) else { return .limit }
            guard let crop = image.cropping(to: CGRect(x: 0, y: image.height - dy, width: width, height: dy)),
                  let ctx = Self.context(width: width, height: dy) else { return .unmatched }
            // Detach the crop from the full-frame provider to keep memory proportional to output.
            ctx.draw(crop, in: CGRect(x: 0, y: 0, width: width, height: dy))
            guard let detached = ctx.makeImage() else { return .unmatched }
            strips.append(detached); height += dy; previous = frame
            return .appended(dy)
        }
    }
    public func render() -> CGImage? {
        guard width > 0, height > 0, let ctx = Self.context(width: width, height: height) else { return nil }
        var top = 0
        for strip in strips {
            ctx.draw(strip, in: CGRect(x: 0, y: height - top - strip.height, width: width, height: strip.height))
            top += strip.height
        }
        return ctx.makeImage()
    }
    private static func context(width: Int, height: Int) -> CGContext? {
        CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4, space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
    }
}
