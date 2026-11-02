import Foundation
import CoreGraphics
#if SWIFT_PACKAGE
import LongShotCore
#endif
final class ImageAccumulatorTests {
    let fixture = FrameMatcherTests()
    func image(_ start: Int, height: Int = 480) -> CGImage {
        let frame = fixture.frame(start: start, height: height)
        let data = Data(frame.pixels)
        return CGImage(width: 96, height: height, bitsPerComponent: 8, bitsPerPixel: 8, bytesPerRow: 96, space: CGColorSpaceCreateDeviceGray(), bitmapInfo: [], provider: CGDataProvider(data: data as CFData)!, decode: nil, shouldInterpolate: false, intent: .defaultIntent)!
    }
    func gray(_ image: CGImage) -> [UInt8] {
        var data = [UInt8](repeating: 0, count: image.width * image.height)
        data.withUnsafeMutableBytes { raw in
            let context = CGContext(data: raw.baseAddress, width: image.width, height: image.height, bitsPerComponent: 8, bytesPerRow: image.width, space: CGColorSpaceCreateDeviceGray(), bitmapInfo: 0)!
            context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
        }
        return data
    }
    func testCompositionKeepsPixelOrderAndNoDuplicateFrame() {
        let a = ImageAccumulator()
        XCTAssertEqual(a.ingest(image(0)), .first)
        XCTAssertEqual(a.ingest(image(100)), .appended(100))
        XCTAssertEqual(a.ingest(image(100)), .stationary)
        XCTAssertEqual(a.height, 580)
        guard let result = a.render() else { XCTAssertEqual(true, false, "missing composite"); return }
        XCTAssertEqual(result.height, 580)
        XCTAssertEqual(gray(result), gray(image(0, height: 580)), "composite pixels must be in reading order")
    }
    func testUnmatchedFrameKeepsLastGoodAnchor() {
        let a = ImageAccumulator()
        _ = a.ingest(image(0))
        XCTAssertEqual(a.ingest(image(900)), .unmatched)
        XCTAssertEqual(a.ingest(image(100)), .appended(100))
    }
    func testMemoryLimitPreservesExistingImage() {
        let a = ImageAccumulator(maxPixels: 1_000_000, maxHeight: 550)
        _ = a.ingest(image(0))
        XCTAssertEqual(a.ingest(image(100)), .limit)
        XCTAssertEqual(a.height, 480)
        XCTAssertEqual(a.render()?.height, 480)
    }
}
