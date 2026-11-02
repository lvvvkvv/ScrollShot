import AppKit
import ScreenCaptureKit
import LongShotCore

struct CaptureFailure: LocalizedError {
    let message: String
    var errorDescription: String? { message }
}
struct CaptureSource {
    let filter: SCContentFilter
    let configuration: SCStreamConfiguration
    static func prepare(region: CGRect, screen: NSScreen) async throws -> CaptureSource {
        guard let displayID = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID,
              let rect = CaptureGeometry.sourceRect(selection: region, screen: screen.frame) else { throw CaptureFailure(message: "选区已失效，请重新选择。") }
        let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
        guard let display = content.displays.first(where: { $0.displayID == displayID }) else { throw CaptureFailure(message: "显示器已断开，请重新选择。") }
        let ownApps = content.applications.filter { $0.processID == ProcessInfo.processInfo.processIdentifier }
        let filter = SCContentFilter(display: display, excludingApplications: ownApps, exceptingWindows: [])
        let config = SCStreamConfiguration()
        config.sourceRect = rect
        config.width = Int((rect.width * screen.backingScaleFactor).rounded())
        config.height = Int((rect.height * screen.backingScaleFactor).rounded())
        config.showsCursor = false
        config.scalesToFit = true
        config.pixelFormat = kCVPixelFormatType_32BGRA
        config.colorSpaceName = CGColorSpace.sRGB
        return CaptureSource(filter: filter, configuration: config)
    }
    func image() async throws -> CGImage {
        try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: configuration)
    }
}
actor StitchWorker {
    private let accumulator = ImageAccumulator()
    func ingest(_ image: CGImage) -> (IngestStatus, Int, Int) {
        let status = accumulator.ingest(image)
        return (status, accumulator.width, accumulator.height)
    }
    func result() -> CGImage? { accumulator.render() }
}
