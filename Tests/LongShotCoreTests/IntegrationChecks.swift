import Foundation
import AppKit
#if SWIFT_PACKAGE
import LongShotCore
#endif
func runIntegrationChecks() {
    XCTAssertEqual(CaptureGeometry.sourceRect(selection: CGRect(x: 100, y: 200, width: 600, height: 400), screen: CGRect(x: 0, y: 0, width: 1920, height: 1080)), CGRect(x: 100, y: 480, width: 600, height: 400))
    XCTAssertEqual(CaptureGeometry.sourceRect(selection: CGRect(x: -1500, y: 300, width: 600, height: 400), screen: CGRect(x: -1920, y: 100, width: 1920, height: 1080)), CGRect(x: 420, y: 480, width: 600, height: 400))
    XCTAssertEqual(CaptureGeometry.sourceRect(selection: CGRect(x: -20, y: 200, width: 600, height: 400), screen: CGRect(x: 0, y: 0, width: 1920, height: 1080)), nil)
    let w = 960, h = 4200
    let context = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4, space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    context.setFillColor(NSColor.white.cgColor); context.fill(CGRect(x: 0, y: 0, width: w, height: h))
    NSGraphicsContext.saveGraphicsState(); NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: false)
    for i in 0..<92 {
        let text = "\(String(format: "%03d", i + 1))  ScrollShot · 截图测试：段落 \(i * 31 + 7)  页面内容应当连续完整。"
        (text as NSString).draw(at: CGPoint(x: 48, y: h - 100 - i * 43), withAttributes: [.font: NSFont.systemFont(ofSize: 22), .foregroundColor: NSColor(calibratedWhite: CGFloat(i % 4) * 0.06 + 0.12, alpha: 1)])
        if i % 7 == 0 {
            accentStripe(context, y: h - 113 - i * 43, width: 310 + i * 3)
        }
    }
    NSGraphicsContext.restoreGraphicsState()
    let page = context.makeImage()!
    let a = ImageAccumulator()
    XCTAssertEqual(a.ingest(page.cropping(to: CGRect(x: 0, y: 0, width: w, height: 1100))!), .first)
    var offset = 0
    for dy in [1, 17, 67, 133, 300, 530] {
        offset += dy
        XCTAssertEqual(a.ingest(page.cropping(to: CGRect(x: 0, y: offset, width: w, height: 1100))!), .appended(dy), "real text offset \(dy)")
    }
    XCTAssertEqual(a.height, 2148)
    let checks = ImageAccumulatorTests()
    if let output = a.render() {
        XCTAssertEqual(checks.gray(output), checks.gray(page.cropping(to: CGRect(x: 0, y: 0, width: w, height: 2148))!), "text output must be lossless and ordered")
        if let path = ProcessInfo.processInfo.environment["SCROLLSHOT_FIXTURE"] {
            try? NSBitmapImageRep(cgImage: output).representation(using: .png, properties: [:])?.write(to: URL(fileURLWithPath: path))
        }
    } else { XCTAssertEqual(true, false, "missing text composite") }
}
private func accentStripe(_ c: CGContext, y: Int, width: Int) {
    c.setFillColor(NSColor(calibratedRed: 0.28, green: 0.35, blue: 0.90, alpha: 1).cgColor)
    c.fill(CGRect(x: 48, y: y, width: width, height: 3))
}
