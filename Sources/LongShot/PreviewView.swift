import AppKit

final class PreviewView: NSView {
    let scroll = NSScrollView()
    let notice = label("⌘S 保存  ·  ⌘C 复制", 11, color: Theme.secondary)
    let saveButton: ActionButton
    let copyButton: ActionButton
    init(image: CGImage, save: @escaping () -> Void, copy: @escaping () -> Void, fit: @escaping () -> Void, actualSize: @escaping () -> Void, newCapture: @escaping () -> Void) {
        saveButton = ActionButton("保存图片…", primary: true, icon: "square.and.arrow.down", action: save)
        copyButton = ActionButton("复制", icon: "doc.on.doc", action: copy)
        super.init(frame: CGRect(x: 0, y: 0, width: 1000, height: 740))
        pin(Surface(fill: Theme.background, stroke: nil, radius: 0), to: self)
        let title = column([label("长图预览", 17, .semibold), label("\(image.width.formatted()) × \(image.height.formatted()) px", 11, color: Theme.secondary)], spacing: 5)
        let header = row([title, spacer(), copyButton, saveButton], spacing: 10)
        copyButton.keyEquivalent = "c"; copyButton.keyEquivalentModifierMask = .command
        saveButton.keyEquivalent = "s"; saveButton.keyEquivalentModifierMask = .command
        header.translatesAutoresizingMaskIntoConstraints = false; addSubview(header)
        let new = ActionButton("继续截图", icon: "plus", quiet: true, action: newCapture)
        let fitButton = ActionButton("适合宽度", icon: "arrow.left.and.right", quiet: true, action: fit)
        let actualButton = ActionButton("100%", quiet: true, action: actualSize)
        new.buttonHeight = 28; fitButton.buttonHeight = 28; actualButton.buttonHeight = 28
        let zoom = row([fitButton, separator(height: 16), actualButton], spacing: 3)
        let tools = row([new, spacer(), zoom, spacer(), label("PNG  /  原始分辨率", 10, color: Theme.secondary)], spacing: 10)
        tools.translatesAutoresizingMaskIntoConstraints = false; addSubview(tools)
        let topRule = Surface(fill: Theme.border, stroke: nil, radius: 0)
        let canvasRule = Surface(fill: Theme.border, stroke: nil, radius: 0)
        for rule in [topRule, canvasRule] { rule.translatesAutoresizingMaskIntoConstraints = false; addSubview(rule) }
        scroll.contentView = CenteringClipView()
        scroll.documentView = PreviewDocument(image: image)
        scroll.hasVerticalScroller = true; scroll.hasHorizontalScroller = true; scroll.autohidesScrollers = true
        scroll.scrollerStyle = .overlay; scroll.allowsMagnification = true
        scroll.minMagnification = 0.01; scroll.maxMagnification = 4
        scroll.drawsBackground = true; scroll.backgroundColor = Theme.canvas
        scroll.borderType = .noBorder; scroll.translatesAutoresizingMaskIntoConstraints = false; addSubview(scroll)
        let footer = row([symbol("checkmark.circle.fill", size: 11, color: hex(0x3F9C7D)), label("捕获完成", 11, color: Theme.secondary), spacer(), notice], spacing: 7)
        footer.translatesAutoresizingMaskIntoConstraints = false; addSubview(footer)
        NSLayoutConstraint.activate([
            header.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24), header.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24),
            header.topAnchor.constraint(equalTo: topAnchor, constant: 18), header.heightAnchor.constraint(equalToConstant: 44),
            topRule.leadingAnchor.constraint(equalTo: leadingAnchor), topRule.trailingAnchor.constraint(equalTo: trailingAnchor),
            topRule.topAnchor.constraint(equalTo: header.bottomAnchor, constant: 16), topRule.heightAnchor.constraint(equalToConstant: 1),
            tools.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14), tools.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24),
            tools.topAnchor.constraint(equalTo: topRule.bottomAnchor, constant: 8), tools.heightAnchor.constraint(equalToConstant: 28),
            zoom.centerXAnchor.constraint(equalTo: centerXAnchor),
            canvasRule.leadingAnchor.constraint(equalTo: leadingAnchor), canvasRule.trailingAnchor.constraint(equalTo: trailingAnchor),
            canvasRule.topAnchor.constraint(equalTo: tools.bottomAnchor, constant: 8), canvasRule.heightAnchor.constraint(equalToConstant: 1),
            scroll.topAnchor.constraint(equalTo: canvasRule.bottomAnchor), scroll.leadingAnchor.constraint(equalTo: leadingAnchor), scroll.trailingAnchor.constraint(equalTo: trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: footer.topAnchor, constant: -9),
            footer.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 18), footer.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            footer.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10), footer.heightAnchor.constraint(equalToConstant: 18)
        ])
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    private func separator(height: CGFloat) -> NSView {
        let view = Surface(fill: Theme.border, stroke: nil, radius: 0)
        view.widthAnchor.constraint(equalToConstant: 1).isActive = true
        view.heightAnchor.constraint(equalToConstant: height).isActive = true
        return view
    }
}
final class PreviewDocument: NSView {
    private let image: NSImage
    private let imageSize: NSSize
    override var isFlipped: Bool { true }
    init(image: CGImage) {
        imageSize = NSSize(width: image.width, height: image.height)
        self.image = NSImage(cgImage: image, size: imageSize)
        super.init(frame: CGRect(x: 0, y: 0, width: image.width + 96, height: image.height + 96))
        setAccessibilityRole(.image); setAccessibilityLabel("捕获的长截图")
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override func draw(_ dirtyRect: NSRect) {
        NSGraphicsContext.saveGraphicsState()
        let shadow = NSShadow(); shadow.shadowColor = NSColor.black.withAlphaComponent(0.14)
        shadow.shadowBlurRadius = 18; shadow.shadowOffset = NSSize(width: 0, height: 5); shadow.set()
        image.draw(in: CGRect(origin: NSPoint(x: 48, y: 48), size: imageSize), from: .zero, operation: .sourceOver, fraction: 1, respectFlipped: true, hints: nil)
        NSGraphicsContext.restoreGraphicsState()
    }
}
final class CenteringClipView: NSClipView {
    override func constrainBoundsRect(_ proposedBounds: NSRect) -> NSRect {
        var rect = super.constrainBoundsRect(proposedBounds)
        if let doc = documentView {
            if proposedBounds.width > doc.frame.width { rect.origin.x = (doc.frame.width - proposedBounds.width) / 2 }
            if proposedBounds.height > doc.frame.height { rect.origin.y = (doc.frame.height - proposedBounds.height) / 2 }
        }
        return rect
    }
}
