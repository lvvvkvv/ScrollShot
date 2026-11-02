import Foundation
#if SWIFT_PACKAGE
import LongShotCore
#endif
var failures = 0
func XCTAssertEqual<T: Equatable>(_ actual: T, _ expected: T, _ message: String = "") {
    if actual != expected { failures += 1; print("FAIL: \(message) expected \(expected), got \(actual)") }
}

final class FrameMatcherTests {
    // Wrong sign, rounded offset or accepting nonmatching frames corrupts the final image.
    func frame(start: Int, height: Int = 480, width: Int = 96) -> GrayFrame {
        let data = (0..<(height * width)).map { n -> UInt8 in
            let x = n % width, y = n / width + start
            var v = UInt64(y &* 9211 &+ x &* 6733 &+ (y / 7) &* x &* 331)
            v = (v ^ (v >> 13)) &* 1274126177
            return UInt8(truncatingIfNeeded: v >> 11)
        }
        return GrayFrame(width: width, height: height, pixels: data)
    }
    func testFindsExactPixelOffsets() {
        for offset in [1, 17, 61, 137, 319] {
            XCTAssertEqual(FrameMatcher.match(previous: frame(start: 0), next: frame(start: offset)), .moved(offset), "offset \(offset)")
        }
    }
    func testIdenticalFrameDoesNotAppend() {
        XCTAssertEqual(FrameMatcher.match(previous: frame(start: 0), next: frame(start: 0)), .stationary)
    }
    func testReverseScrollDoesNotAppend() {
        XCTAssertEqual(FrameMatcher.match(previous: frame(start: 100), next: frame(start: 0)), .reversed)
    }
    func testLargeJumpCannotSilentlyJoin() {
        XCTAssertEqual(FrameMatcher.match(previous: frame(start: 0), next: frame(start: 800)), .unmatched)
    }
    func testFlatPageDoesNotInventMovement() {
        let a = GrayFrame(width: 96, height: 480, pixels: Array(repeating: 240, count: 46080))
        XCTAssertEqual(FrameMatcher.match(previous: a, next: a), .stationary)
    }
    func testMalformedFrameIsRejected() {
        XCTAssertEqual(FrameMatcher.match(previous: frame(start: 0), next: GrayFrame(width: 96, height: 480, pixels: [])), .unmatched)
    }
}
