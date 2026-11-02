import AppKit
import ApplicationServices
import LongShotCore

@MainActor final class CaptureController {
    private var panel: FloatingPanel?
    private var border: NSWindow?
    private var source: CaptureSource?
    private let worker = StitchWorker()
    private var loop: Task<Void, Never>?
    private var isFinishing = false
    private var cancelled = false
    private var capturing = false
    private var automatic = false
    private var stagnant = 0
    private var frames = 0
    private var status: NSTextField!
    private var dimensions: NSTextField!
    private var startButton: ActionButton!
    private var autoButton: ActionButton!
    private let region: CGRect
    private let screen: NSScreen
    private var targetApp: NSRunningApplication?
    var onResult: ((CGImage) -> Void)?
    var onCancel: (() -> Void)?
    var onReselect: (() -> Void)?

    init(region: CGRect, screen: NSScreen, targetApp: NSRunningApplication?) {
        self.region = region; self.screen = screen; self.targetApp = targetApp
    }
    func show() {
        let b = NSWindow(contentRect: region.insetBy(dx: -2, dy: -2), styleMask: .borderless, backing: .buffered, defer: false)
        b.isOpaque = false; b.backgroundColor = .clear; b.hasShadow = false; b.ignoresMouseEvents = true
        b.level = .floating; b.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        b.contentView = BorderView(); b.orderFrontRegardless(); border = b
        let p = FloatingPanel(contentRect: CGRect(x: 0, y: 0, width: 556, height: 124), styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        p.title = "ScrollShot · 区域滚动截图"; p.isOpaque = false; p.backgroundColor = .clear
        p.isFloatingPanel = true; p.level = .floating; p.hidesOnDeactivate = false; p.hasShadow = true
        p.isMovableByWindowBackground = true; p.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        let hud = CaptureHUDView(start: { [weak self] in self?.startOrFinish() },
                                 automatic: { [weak self] in self?.toggleAuto() },
                                 reselect: { [weak self] in self?.reselect() },
                                 cancel: { [weak self] in self?.cancel() })
        p.contentView = hud
        startButton = hud.startButton; autoButton = hud.autoButton
        status = hud.status; dimensions = hud.dimensions
        let safe = screen.visibleFrame
        let desiredY = region.minY - p.frame.height - 12
        p.setFrameOrigin(CGPoint(x: max(safe.minX, min(region.midX - 278, safe.maxX - 556)), y: max(safe.minY, min(desiredY, safe.maxY - p.frame.height))))
        dimensions.stringValue = "\(Int(region.width)) × \(Int(region.height)) pt"
        status.stringValue = "点击开始后，在选区内缓慢向下滚动。工具条可拖动。"
        p.makeKeyAndOrderFront(nil); panel = p
    }
    func startOrFinish() {
        if capturing { finish(); return }
        guard loop == nil, !isFinishing else { return }
        startButton.isEnabled = false; status.stringValue = "正在连接屏幕…"
        loop = Task { [weak self] in
            guard let self else { return }
            do {
                let src = try await CaptureSource.prepare(region: region, screen: screen)
                guard !Task.isCancelled, !cancelled else { return }
                source = src
                let first = try await src.image()
                guard !Task.isCancelled, !cancelled else { return }
                let (_, w, h) = await worker.ingest(first)
                capturing = true; frames = 1
                dimensions.stringValue = "\(w) × \(h) px"
                startButton.title = "完成"; startButton.iconName = "checkmark"; startButton.isEnabled = true
                status.stringValue = "正在捕获 · 请在选区内缓慢向下滚动"
                targetApp?.activate(options: [])
                while !Task.isCancelled, !cancelled, !isFinishing {
                    if automatic { scrollDown() }
                    try await Task.sleep(nanoseconds: 180_000_000)
                    let image = try await src.image()
                    guard !Task.isCancelled, !cancelled else { return }
                    let (state, width, height) = await worker.ingest(image)
                    dimensions.stringValue = "\(width) × \(height) px · \(frames) 段"
                    switch state {
                    case .first: break
                    case .appended:
                        frames += 1; stagnant = 0
                        status.stringValue = "正在捕获 · \(automatic ? "自动滚动中" : "缓慢向下滚动，点击完成结束")"
                    case .stationary:
                        stagnant += 1
                        if automatic && stagnant >= 12 {
                            automatic = false; updateAutoButton()
                            status.stringValue = "画面已停止变化 · 可能已到底部，点击完成保存"
                        }
                    case .reversed:
                        automatic = false; updateAutoButton()
                        status.stringValue = "请向下滚动回到刚才位置，再继续捕获"
                    case .unmatched:
                        automatic = false; updateAutoButton()
                        status.stringValue = "画面未衔接 · 请缓慢向上回滚一些，再向下继续"
                    case .limit:
                        automatic = false; updateAutoButton(); isFinishing = true
                        status.stringValue = "已达图片大小上限，正在生成已有内容…"
                    }
                }
                guard !cancelled else { return }
                let result = await worker.result()
                guard !cancelled else { return }
                close()
                if let result { onResult?(result) }
                else { inform("未能生成图片", "请重新选择区域并开始捕获。"); onCancel?() }
            } catch {
                guard !cancelled else { return }
                let existing = await worker.result()
                guard !cancelled else { return }
                close()
                if let existing {
                    onResult?(existing)
                    inform("捕获已中断，已保留现有内容", error.localizedDescription)
                } else {
                    inform("无法捕获屏幕", "请在系统设置中开启 ScrollShot 的屏幕录制权限后重试。\n\n\(error.localizedDescription)")
                    onCancel?()
                }
            }
        }
    }
    func finish() {
        guard capturing, !isFinishing else { return }
        isFinishing = true; automatic = false; updateAutoButton()
        startButton.isEnabled = false; status.stringValue = "正在生成长图…"
        // The loop completes the in-flight capture before rendering. Do not cancel it here.
    }
    func cancel() {
        cancelled = true; automatic = false; loop?.cancel(); close(); onCancel?()
    }
    private func reselect() {
        cancelled = true; automatic = false; loop?.cancel(); close(); onReselect?()
    }
    func toggleAuto() {
        if !automatic {
            guard AXIsProcessTrusted() else {
                inform("自动滚动需要辅助功能权限", "请在「系统设置 → 隐私与安全性 → 辅助功能」中添加并开启 ScrollShot。\n\n不开启也能使用手动滚动截图。")
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") { NSWorkspace.shared.open(url) }
                return
            }
            automatic = true; stagnant = 0
        } else { automatic = false }
        updateAutoButton()
        if capturing { targetApp?.activate(options: []) }
    }
    private func updateAutoButton() {
        autoButton.title = automatic ? "自动滚动：开" : "自动滚动：关"
        autoButton.style = automatic ? .primary : .secondary
    }
    private func scrollDown() {
        guard let event = CGEvent(scrollWheelEvent2Source: nil, units: .pixel, wheelCount: 1, wheel1: -Int32(max(12, min(80, region.height / 8))), wheel2: 0, wheel3: 0) else { return }
        // Quartz event coordinates are relative to the primary display's top edge.
        event.location = CGPoint(x: region.midX, y: (NSScreen.screens.first?.frame.maxY ?? 0) - region.midY)
        event.post(tap: .cghidEventTap)
    }
    private func close() {
        capturing = false; border?.orderOut(nil); panel?.orderOut(nil); border = nil; panel = nil
    }
}
