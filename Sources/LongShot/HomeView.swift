import AppKit

final class HomeView: NSView {
    let permissionStatus = label("", 12, .medium)
    let permissionButton: ActionButton
    let recentButton: ActionButton
    let readyBadge = label("", 11, .medium, color: Theme.secondary)
    init(capture: @escaping () -> Void, previous: @escaping () -> Void, permission: @escaping () -> Void, help: @escaping () -> Void) {
        permissionButton = ActionButton("授权", quiet: true, action: permission)
        recentButton = ActionButton("最近结果", icon: "clock.arrow.circlepath", quiet: true, action: previous)
        super.init(frame: CGRect(x: 0, y: 0, width: 920, height: 600))
        let background = Surface(fill: Theme.background, stroke: nil, radius: 0); pin(background, to: self)
        let sidebar = Surface(fill: Theme.sidebar, stroke: nil, radius: 0)
        add(sidebar, x: 0, top: 0, width: 184, height: 600)
        let rule = Surface(fill: Theme.border, stroke: nil, radius: 0)
        add(rule, x: 183, top: 0, width: 1, height: 600)
        let icon = Surface(fill: Theme.accentFill, stroke: nil, radius: 9)
        let brandSymbol = symbol("rectangle.dashed.badge.record", size: 19, color: .white)
        pin(brandSymbol, to: icon, inset: 7)
        add(icon, x: 20, top: 56, width: 36, height: 36)
        add(label("ScrollShot", 17, .semibold), x: 65, top: 58, width: 111, height: 23)
        add(label("屏幕捕获工作台", 10, color: Theme.secondary), x: 65, top: 81, width: 112, height: 16)
        let current = Surface(fill: Theme.selection, stroke: nil, radius: 8)
        let nav = row([symbol("rectangle.dashed", size: 15, color: Theme.accent), label("新建截图", 13, .medium, color: Theme.accent)])
        pin(nav, to: current, inset: 11)
        add(current, x: 12, top: 130, width: 160, height: 40)
        recentButton.leadingContent = true; recentButton.isEnabled = false
        recentButton.toolTip = "完成截图后，可在这里重新打开最近结果"
        add(recentButton, x: 12, top: 178, width: 160, height: 40)
        let guide = ActionButton("使用指南", icon: "book.closed", quiet: true, action: help)
        guide.leadingContent = true
        add(guide, x: 12, top: 222, width: 160, height: 40)
        let local = row([symbol("lock.shield", size: 13, color: Theme.secondary), label("仅在本机处理", 11, color: Theme.secondary)], spacing: 6)
        add(local, x: 23, top: 520, width: 147, height: 22)
        add(label("ScrollShot  0.2.1", 10, color: Theme.secondary), x: 25, top: 553, width: 145, height: 20)

        add(label("新建长截图", 24, .semibold), x: 216, top: 54, width: 350, height: 32)
        add(label("将网页、对话和文档，收进一张完整图片。", 12, color: Theme.secondary), x: 216, top: 92, width: 510, height: 20)
        add(readyBadge, x: 768, top: 64, width: 120, height: 20)
        readyBadge.alignment = .right

        let hero = Surface(fill: hex(0x171826), stroke: hex(0x292A3D), radius: 16)
        add(hero, x: 216, top: 134, width: 672, height: 266)
        let eyebrow = label("SCROLLING CAPTURE", 10, .semibold, color: hex(0xAEABCF))
        hero.add(eyebrow, x: 28, top: 29, width: 280, height: 17)
        hero.add(label("长内容，一次截完整。", 23, .semibold, color: .white), x: 28, top: 62, width: 305, height: 34)
        hero.add(label("框选你需要的区域，缓慢滚动。\n剩下的交给 ScrollShot。", 12, color: hex(0xADADC2)), x: 28, top: 108, width: 286, height: 44)
        let start = ActionButton("选择截图区域", primary: true, icon: "rectangle.dashed", action: capture)
        start.buttonHeight = 40
        hero.add(start, x: 28, top: 173, width: 188, height: 40)
        hero.add(label("快捷键", 10, color: hex(0x8D8DA6)), x: 29, top: 229, width: 40, height: 15)
        let keys = row([keycap("⌘"), keycap("⇧"), keycap("⌥"), keycap("S")], spacing: 4)
        hero.add(keys, x: 75, top: 225, width: 113, height: 23)
        hero.add(CaptureIllustration(), x: 345, top: 12, width: 312, height: 242)

        let steps = row([
            step("rectangle.dashed", "框选区域", "避开固定栏和输入框"),
            step("arrow.down", "向下滚动", "手动滚动或开启自动"),
            step("square.and.arrow.down", "完成并导出", "原始分辨率 PNG")
        ], spacing: 22)
        steps.distribution = .fillEqually
        add(steps, x: 220, top: 427, width: 660, height: 51)
        let permissions = Surface(radius: 10)
        add(permissions, x: 216, top: 508, width: 672, height: 60)
        let permissionIcon = symbol("checkmark.shield", size: 19, color: Theme.secondary)
        permissions.add(permissionIcon, x: 16, top: 19, width: 23, height: 23)
        permissions.add(label("屏幕录制权限", 12, .medium), x: 51, top: 11, width: 360, height: 20)
        permissions.add(permissionStatus, x: 51, top: 33, width: 450, height: 17)
        permissions.add(permissionButton, x: 554, top: 13, width: 102, height: 34)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    private func keycap(_ key: String) -> NSView {
        let v = Surface(fill: hex(0x292A3E), stroke: hex(0x3E3E55), radius: 4)
        let text = label(key, 11, .medium, color: hex(0xD3D1E6)); text.alignment = .center
        pin(text, to: v, inset: 3)
        v.widthAnchor.constraint(equalToConstant: 24).isActive = true
        return v
    }
    private func step(_ icon: String, _ title: String, _ description: String) -> NSView {
        row([symbol(icon, size: 17, color: Theme.accent), column([label(title, 12, .medium), label(description, 10, color: Theme.secondary)], spacing: 5)], spacing: 10)
    }
    func updatePermission(_ allowed: Bool) {
        readyBadge.stringValue = allowed ? "● 准备就绪" : "○ 尚未授权"
        readyBadge.textColor = allowed ? hex(0x28765B) : Theme.secondary
        permissionStatus.stringValue = allowed ? "已开启，可以开始捕获屏幕内容" : "首次使用需授权，截图仅在本机处理"
        permissionStatus.textColor = Theme.secondary
        permissionButton.title = allowed ? "查看权限" : "前往授权"
    }
}
extension NSView {
    func add(_ view: NSView, x: CGFloat, top: CGFloat, width: CGFloat, height: CGFloat) {
        view.translatesAutoresizingMaskIntoConstraints = false; addSubview(view)
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: leadingAnchor, constant: x),
            view.topAnchor.constraint(equalTo: topAnchor, constant: top),
            view.widthAnchor.constraint(equalToConstant: width), view.heightAnchor.constraint(equalToConstant: height)
        ])
    }
}

/// Original vector artwork explaining the selection/scroll interaction, not an app screenshot.
final class CaptureIllustration: NSView {
    override func draw(_ dirtyRect: NSRect) {
        func rounded(_ rect: CGRect, _ fill: NSColor, _ radius: CGFloat = 8, stroke: NSColor? = nil) {
            let p = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
            fill.setFill(); p.fill()
            if let stroke { stroke.setStroke(); p.lineWidth = 1; p.stroke() }
        }
        // Two inset surfaces suggest content continuing beyond the capture window.
        rounded(CGRect(x: 51, y: 10, width: 220, height: 208), hex(0x292A40), 12, stroke: hex(0x3B3C54))
        rounded(CGRect(x: 37, y: 20, width: 220, height: 208), hex(0xEFEFF7), 12)
        rounded(CGRect(x: 37, y: 196, width: 220, height: 32), hex(0xFCFCFF), 12)
        hex(0xE1E1EB).setFill(); CGRect(x: 37, y: 196, width: 220, height: 1).fill()
        for (i, c) in [UInt32(0xC6C5D4),0xD6D5DF,0xE4E3EC].enumerated() {
            rounded(CGRect(x: 50 + i * 10, y: 208, width: 5, height: 5), hex(c), 2.5)
        }
        rounded(CGRect(x: 114, y: 206, width: 79, height: 8), hex(0xE9E8F1), 4)
        rounded(CGRect(x: 53, y: 41, width: 188, height: 139), .white, 7)
        for i in 0..<4 {
            let y = CGFloat(153 - i * 30)
            rounded(CGRect(x: 65, y: y - 4, width: 16, height: 16), hex(i % 2 == 0 ? 0xE4DFFB : 0xE3ECF2), 5)
            rounded(CGRect(x: 89, y: y + 4, width: CGFloat(113 - i * 9), height: 5), hex(0xB7B5CA), 2)
            rounded(CGRect(x: 89, y: y - 6, width: CGFloat(135 - i * 6), height: 4), hex(0xE2E1EA), 2)
        }
        let capture = CGRect(x: 48, y: 35, width: 198, height: 150)
        let p = NSBezierPath(roundedRect: capture, xRadius: 8, yRadius: 8)
        hex(0xAFA2FF).setStroke(); p.lineWidth = 1.5; p.stroke()
        for point in [CGPoint(x: 48,y:35),CGPoint(x:246,y:35),CGPoint(x:48,y:185),CGPoint(x:246,y:185)] {
            rounded(CGRect(x: point.x - 3, y: point.y - 3, width: 6, height: 6), .white, 1.5, stroke: hex(0x9B8AF5))
        }
        rounded(CGRect(x: 143, y: 3, width: 137, height: 32), hex(0x3D365E), 8, stroke: hex(0x67578F))
        let text = "↓  滚动以继续捕获"
        (text as NSString).draw(at: NSPoint(x: 156, y: 13), withAttributes: [.font: NSFont.systemFont(ofSize: 10, weight: .medium), .foregroundColor: hex(0xE2DBFF)])
        // Small drag cursor, drawn as a native-style pointer.
        let cursor = NSBezierPath(); cursor.move(to: CGPoint(x: 229,y:87)); cursor.line(to: CGPoint(x: 234,y:67)); cursor.line(to: CGPoint(x: 239,y:74)); cursor.line(to: CGPoint(x: 248,y:74)); cursor.close()
        NSColor.white.setFill(); cursor.fill(); hex(0x514A78).setStroke(); cursor.lineWidth = 1; cursor.stroke()
    }
}
