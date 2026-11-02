import AppKit
import UniformTypeIdentifiers

@MainActor final class PreviewController: NSObject, NSWindowDelegate {
    private let image: CGImage
    private var window: NSWindow!
    private var preview: PreviewView!
    private var scroll: NSScrollView { preview.scroll }
    private var notice: NSTextField { preview.notice }
    var onNewCapture: (() -> Void)?
    var onClose: (() -> Void)?
    init(image: CGImage) { self.image = image; super.init() }
    func show() {
        let w = NSWindow(contentRect: CGRect(x: 0, y: 0, width: 1000, height: 740), styleMask: [.titled, .closable, .miniaturizable, .resizable], backing: .buffered, defer: false)
        w.title = "ScrollShot · 长图预览"; w.minSize = CGSize(width: 700, height: 460)
        w.titlebarAppearsTransparent = true; w.backgroundColor = Theme.background
        w.isReleasedWhenClosed = false; w.delegate = self; window = w
        preview = PreviewView(image: image,
                              save: { [weak self] in self?.save() },
                              copy: { [weak self] in self?.copy() },
                              fit: { [weak self] in self?.fitWidth() },
                              actualSize: { [weak self] in self?.scroll.setMagnification(1, centeredAt: .zero) },
                              newCapture: { [weak self] in self?.onNewCapture?() })
        w.contentView = preview
        w.center(); w.makeKeyAndOrderFront(nil); NSApp.activate(ignoringOtherApps: true)
        preview.layoutSubtreeIfNeeded(); fitWidth()
    }
    func hide() { window?.orderOut(nil) }
    func present() { window?.makeKeyAndOrderFront(nil); NSApp.activate(ignoringOtherApps: true) }
    private func fitWidth() {
        let factor = min(1, max(0.01, scroll.contentSize.width / (CGFloat(image.width) + 96)))
        scroll.setMagnification(factor, centeredAt: .zero)
        let reset = scroll.contentView.constrainBoundsRect(CGRect(origin: .zero, size: scroll.contentView.bounds.size))
        scroll.contentView.scroll(to: reset.origin)
        scroll.reflectScrolledClipView(scroll.contentView)
    }
    private func encodedPNG() async -> Data? {
        let image = self.image
        return await Task.detached(priority: .userInitiated) {
            NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:])
        }.value
    }
    private func copy() {
        notice.stringValue = "正在复制图片…"
        Task { [weak self] in
            guard let self else { return }
            guard let data = await encodedPNG() else { inform("复制失败", "图片过大，无法编码，请尝试重新截图。"); return }
            let board = NSPasteboard.general; board.clearContents()
            if board.setData(data, forType: .png) { notice.stringValue = "已复制原始分辨率图片" }
            else { inform("复制失败", "无法写入系统剪贴板，请尝试保存 PNG。") }
        }
    }
    private func save() {
        let panel = NSSavePanel(); panel.allowedContentTypes = [.png]
        let format = DateFormatter(); format.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        panel.nameFieldStringValue = "ScrollShot_\(format.string(from: Date())).png"
        panel.beginSheetModal(for: window) { [weak self] response in
            guard response == .OK, let self, let url = panel.url else { return }
            self.notice.stringValue = "正在保存图片…"
            Task {
                do {
                    guard let data = await self.encodedPNG() else { throw CaptureFailure(message: "图片编码失败") }
                    try await Task.detached(priority: .userInitiated) { try data.write(to: url, options: .atomic) }.value
                    self.notice.stringValue = "已保存：\(url.lastPathComponent)"
                } catch { inform("保存失败", error.localizedDescription) }
            }
        }
    }
    func windowWillClose(_ notification: Notification) { onClose?() }
}
