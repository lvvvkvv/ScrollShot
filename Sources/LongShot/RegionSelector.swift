import AppKit

@MainActor final class RegionSelector {
    private var windows: [NSWindow] = []
    private var keyMonitor: Any?
    var onSelect: ((CGRect, NSScreen) -> Void)?
    var onCancel: (() -> Void)?
    func show() {
        dismiss()
        let pointer = NSEvent.mouseLocation
        var initialWindow: NSWindow?
        NSApp.activate(ignoringOtherApps: true)
        for screen in NSScreen.screens {
            let panel = FloatingPanel(contentRect: screen.frame, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
            panel.level = .screenSaver; panel.isOpaque = false; panel.backgroundColor = .clear
            panel.acceptsMouseMovedEvents = true
            panel.hasShadow = false; panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            let view = SelectionView(frame: CGRect(origin: .zero, size: screen.frame.size))
            view.selected = { [weak self] local in
                let global = local.offsetBy(dx: screen.frame.minX, dy: screen.frame.minY)
                self?.dismiss(); self?.onSelect?(global, screen)
            }
            panel.contentView = view
            panel.orderFrontRegardless(); windows.append(panel)
            if screen.frame.contains(pointer) { initialWindow = panel }
        }
        // Focus the display where selection starts, rather than the last enumerated display.
        if let initial = initialWindow ?? windows.first, let view = initial.contentView {
            initial.makeKeyAndOrderFront(nil)
            initial.makeFirstResponder(view)
            initial.invalidateCursorRects(for: view)
        }
        NSCursor.crosshair.set()
        // The button's mouse-up/app activation can refresh the cursor later in this run loop.
        // Reassert once the overlay is ready, but never after a quick cancel or reselection.
        let displayedWindows = windows
        DispatchQueue.main.async { [weak self] in
            guard let self, self.windows.count == displayedWindows.count,
                  zip(self.windows, displayedWindows).allSatisfy({ $0 === $1 }),
                  !self.windows.isEmpty else { return }
            NSCursor.crosshair.set()
        }
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 { self?.dismiss(); self?.onCancel?(); return nil }
            return event
        }
    }
    func dismiss() {
        let wasSelecting = !windows.isEmpty
        windows.forEach { $0.orderOut(nil) }; windows.removeAll()
        if wasSelecting { NSCursor.arrow.set() }
        if let keyMonitor { NSEvent.removeMonitor(keyMonitor) }; keyMonitor = nil
    }
}
final class SelectionView: NSView {
    var selected: ((CGRect) -> Void)?
    private var start: NSPoint?
    private var selection = CGRect.zero
    private var cursorTrackingArea: NSTrackingArea?
    override var acceptsFirstResponder: Bool { true }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let cursorTrackingArea { removeTrackingArea(cursorTrackingArea) }
        // cursorUpdate is not delivered for activeAlways areas. Mouse tracking handles
        // non-key display overlays; cursor rectangles still handle the key window.
        let area = NSTrackingArea(rect: .zero, options: [.mouseEnteredAndExited, .mouseMoved, .activeAlways, .inVisibleRect, .enabledDuringMouseDrag], owner: self)
        addTrackingArea(area); cursorTrackingArea = area
    }
    private func showSelectionCursor() {
        guard window?.isVisible == true else { return }
        NSCursor.crosshair.set()
    }
    override func mouseEntered(with event: NSEvent) { showSelectionCursor() }
    override func mouseMoved(with event: NSEvent) { showSelectionCursor() }
    override func cursorUpdate(with event: NSEvent) { showSelectionCursor() }
    override func resetCursorRects() { addCursorRect(bounds, cursor: .crosshair) }
    override func draw(_ dirtyRect: NSRect) {
        NSColor.black.withAlphaComponent(0.40).setFill(); bounds.fill()
        if selection.width > 0 {
            NSColor.clear.setFill(); selection.fill(using: .copy)
            NSColor.white.setStroke(); let path = NSBezierPath(rect: selection); path.lineWidth = 1.5; path.stroke()
            let size = "\(Int(selection.width)) × \(Int(selection.height))"
            drawText(size, at: CGPoint(x: selection.minX + 8, y: max(10, selection.minY - 26)), size: 13)
        }
        drawText("拖动选择滚动区域 · 避开固定标题栏和输入框 · Esc 取消", at: CGPoint(x: 30, y: bounds.height - 62), size: 17)
    }
    private func drawText(_ text: String, at point: CGPoint, size: CGFloat) {
        (text as NSString).draw(at: point, withAttributes: [.font: NSFont.systemFont(ofSize: size, weight: .medium), .foregroundColor: NSColor.white])
    }
    override func mouseDown(with event: NSEvent) { showSelectionCursor(); start = convert(event.locationInWindow, from: nil) }
    override func mouseDragged(with event: NSEvent) {
        showSelectionCursor()
        guard let start else { return }
        let p = convert(event.locationInWindow, from: nil)
        selection = CGRect(x: min(start.x, p.x), y: min(start.y, p.y), width: abs(p.x - start.x), height: abs(p.y - start.y)).intersection(bounds).integral
        needsDisplay = true
    }
    override func mouseUp(with event: NSEvent) {
        mouseDragged(with: event)
        guard selection.width >= 80, selection.height >= 100 else { NSSound.beep(); start = nil; return }
        selected?(selection)
    }
}
final class BorderView: NSView {
    override func draw(_ dirtyRect: NSRect) {
        accent.setStroke(); let p = NSBezierPath(roundedRect: bounds.insetBy(dx: 1, dy: 1), xRadius: 4, yRadius: 4)
        p.lineWidth = 2; p.stroke()
    }
}
