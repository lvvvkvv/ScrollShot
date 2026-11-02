import Foundation

public struct GrayFrame {
    public let width: Int
    public let height: Int
    public let pixels: [UInt8]
    public init(width: Int, height: Int, pixels: [UInt8]) {
        self.width = width; self.height = height; self.pixels = pixels
    }
}
public enum FrameMatch: Equatable {
    case stationary, moved(Int), reversed, unmatched
}
public enum FrameMatcher {
    public static func match(previous a: GrayFrame, next b: GrayFrame) -> FrameMatch {
        guard a.width == b.width, a.height == b.height, a.width >= 16, a.height >= 48,
              a.width <= 4096, a.height <= 50000,
              a.pixels.count == a.width * a.height, b.pixels.count == b.width * b.height else { return .unmatched }
        let w = a.width, h = a.height
        let inset = max(2, h / 25), xInset = max(2, w / 8)
        let yStep = max(1, h / 100), xStep = max(1, w / 24)
        func score(_ shift: Int) -> Double {
            let lo = max(inset, -shift + inset)
            let hi = min(h - inset, h - shift - inset)
            guard hi - lo >= h / 5 else { return .infinity }
            var total = 0, count = 0
            for y in stride(from: lo, to: hi, by: yStep) {
                let ai = (y + shift) * w, bi = y * w
                for x in stride(from: xInset, to: w - xInset, by: xStep) {
                    total += abs(Int(a.pixels[ai + x]) - Int(b.pixels[bi + x])); count += 1
                }
            }
            return count > 0 ? Double(total) / Double(count) : .infinity
        }
        if score(0) < 0.45 { return .stationary }
        let limit = h * 3 / 4
        var best = Double.infinity, offset = 0, scores: [(Int, Double)] = []
        // Search every physical pixel: sub-point Retina offsets must not accumulate seams.
        for shift in -limit...limit where shift != 0 {
            let error = score(shift)
            scores.append((shift, error))
            if error < best { best = error; offset = shift }
        }
        guard best < 4.5 else { return .unmatched }
        // Repeated text/blank patterns can have several equally good joins. Do not guess.
        let alternative = scores.filter { abs($0.0 - offset) > 3 }.map(\.1).min() ?? .infinity
        guard alternative - best > 0.15 else { return .unmatched }
        return offset > 0 ? .moved(offset) : .reversed
    }
}
