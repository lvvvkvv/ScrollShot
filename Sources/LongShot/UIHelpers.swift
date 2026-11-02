import AppKit

private func adaptive(_ light: UInt32, _ dark: UInt32) -> NSColor {
    NSColor(name: nil) { appearance in
        let value = appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua ? dark : light
        return hex(value)
    }
}
func hex(_ value: UInt32, alpha: CGFloat = 1) -> NSColor {
    NSColor(calibratedRed: CGFloat((value >> 16) & 255) / 255, green: CGFloat((value >> 8) & 255) / 255, blue: CGFloat(value & 255) / 255, alpha: alpha)
}
enum Theme {
    static let background = adaptive(0xFAFAFC, 0x18191F)
    static let sidebar = adaptive(0xF1F2F6, 0x14151A)
    static let surface = adaptive(0xFFFFFF, 0x22232B)
    static let subtle = adaptive(0xF5F5F9, 0x2A2B35)
    static let border = adaptive(0xE5E6ED, 0x34353F)
    static let text = adaptive(0x242532, 0xF0F0F5)
    static let secondary = adaptive(0x6F7283, 0x9B9EAF)
    static let accent = adaptive(0x6C5CE7, 0xA092FF)
    static let accentFill = hex(0x6C5CE7)
    static let selection = adaptive(0xE8E5FA, 0x302A48)
    static let canvas = adaptive(0xEBEDF3, 0x111217)
}
let accent = Theme.accent
func label(_ text: String, _ size: CGFloat = 14, _ weight: NSFont.Weight = .regular, color: NSColor = Theme.text) -> NSTextField {
    let field = NSTextField(wrappingLabelWithString: text)
    field.font = .systemFont(ofSize: size, weight: weight); field.textColor = color
    field.isSelectable = false
    return field
}
func symbol(_ name: String, size: CGFloat = 16, color: NSColor = Theme.secondary) -> NSImageView {
    let image = NSImageView()
    image.image = NSImage(systemSymbolName: name, accessibilityDescription: nil)?.withSymbolConfiguration(.init(pointSize: size, weight: .medium))
    image.contentTintColor = color
    image.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([image.widthAnchor.constraint(equalToConstant: size + 4), image.heightAnchor.constraint(equalToConstant: size + 4)])
    return image
}
final class Surface: NSView {
    var fill: NSColor
    var stroke: NSColor?
    var radius: CGFloat
    init(fill: NSColor = Theme.surface, stroke: NSColor? = Theme.border, radius: CGFloat = 12) {
        self.fill = fill; self.stroke = stroke; self.radius = radius
        super.init(frame: .zero)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override func viewDidChangeEffectiveAppearance() { super.viewDidChangeEffectiveAppearance(); needsDisplay = true }
    override func draw(_ dirtyRect: NSRect) {
        let path = NSBezierPath(roundedRect: bounds.insetBy(dx: 0.5, dy: 0.5), xRadius: radius, yRadius: radius)
        fill.setFill(); path.fill()
        if let stroke { stroke.setStroke(); path.lineWidth = 1; path.stroke() }
    }
}
final class ActionButton: NSButton {
    enum Style { case primary, secondary, quiet }
    var actionHandler: (() -> Void)?
    var style: Style { didSet { needsDisplay = true } }
    var iconName: String? { didSet { invalidateIntrinsicContentSize(); needsDisplay = true } }
    var leadingContent = false
    var buttonHeight: CGFloat = 36 { didSet { invalidateIntrinsicContentSize() } }
    private var hovered = false
    private var tracking: NSTrackingArea?
    init(_ title: String, primary: Bool = false, icon: String? = nil, quiet: Bool = false, action: @escaping () -> Void) {
        self.style = primary ? .primary : (quiet ? .quiet : .secondary); self.iconName = icon
        super.init(frame: .zero)
        self.title = title; self.actionHandler = action; bezelStyle = .regularSquare
        isBordered = false; font = .systemFont(ofSize: 13, weight: .medium)
        target = self; self.action = #selector(invoke)
        if primary { keyEquivalent = "\r" }
        setContentHuggingPriority(.required, for: .horizontal)
        setAccessibilityLabel(title)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override var title: String { didSet { invalidateIntrinsicContentSize(); setAccessibilityLabel(title); needsDisplay = true } }
    override var isEnabled: Bool { didSet { needsDisplay = true } }
    override var isHighlighted: Bool { didSet { needsDisplay = true } }
    override var intrinsicContentSize: NSSize {
        let textWidth = (title as NSString).size(withAttributes: [.font: font ?? NSFont.systemFont(ofSize: 13)]).width
        return NSSize(width: ceil(textWidth) + (iconName == nil ? 28 : 51), height: buttonHeight)
    }
    override func updateTrackingAreas() {
        if let tracking { removeTrackingArea(tracking) }
        tracking = NSTrackingArea(rect: bounds, options: [.mouseEnteredAndExited, .activeInActiveApp, .inVisibleRect], owner: self)
        addTrackingArea(tracking!); super.updateTrackingAreas()
    }
    override func viewDidChangeEffectiveAppearance() { super.viewDidChangeEffectiveAppearance(); needsDisplay = true }
    override func mouseEntered(with event: NSEvent) { hovered = true; needsDisplay = true }
    override func mouseExited(with event: NSEvent) { hovered = false; needsDisplay = true }
    override func draw(_ dirtyRect: NSRect) {
        let primary = style == .primary
        let pressed = isHighlighted
        let fill: NSColor
        if primary { fill = pressed ? hex(0x5444C6) : hovered ? hex(0x7969F2) : Theme.accentFill }
        else if pressed { fill = Theme.selection }
        else if hovered { fill = Theme.subtle }
        else { fill = style == .quiet ? .clear : Theme.surface }
        let path = NSBezierPath(roundedRect: bounds.insetBy(dx: 0.5, dy: 0.5), xRadius: 8, yRadius: 8)
        fill.withAlphaComponent(fill.alphaComponent * (isEnabled ? 1 : 0.48)).setFill(); path.fill()
        if style == .secondary { Theme.border.setStroke(); path.lineWidth = 1; path.stroke() }
        let foreground = (primary ? NSColor.white : Theme.text).withAlphaComponent(isEnabled ? 1 : 0.4)
        let attrs: [NSAttributedString.Key: Any] = [.font: font ?? NSFont.systemFont(ofSize: 13), .foregroundColor: foreground]
        let textSize = (title as NSString).size(withAttributes: attrs)
        let iconWidth: CGFloat = iconName == nil ? 0 : (leadingContent ? 26 : 23)
        let x: CGFloat = leadingContent ? 14 : (bounds.width - textSize.width - iconWidth) / 2
        if let iconName, let image = NSImage(systemSymbolName: iconName, accessibilityDescription: nil)?.withSymbolConfiguration(.init(pointSize: 14, weight: .medium).applying(.init(paletteColors: [foreground]))) {
            image.draw(in: CGRect(x: x, y: (bounds.height - 16) / 2, width: 16, height: 16))
        }
        (title as NSString).draw(at: NSPoint(x: x + iconWidth, y: (bounds.height - textSize.height) / 2), withAttributes: attrs)
        if window?.firstResponder === self {
            Theme.accent.withAlphaComponent(0.65).setStroke()
            let focus = NSBezierPath(roundedRect: bounds.insetBy(dx: 2, dy: 2), xRadius: 6, yRadius: 6); focus.lineWidth = 2; focus.stroke()
        }
    }
    @objc func invoke() { guard isEnabled else { return }; actionHandler?() }
}
func row(_ views: [NSView], spacing: CGFloat = 10) -> NSStackView {
    let s = NSStackView(views: views); s.orientation = .horizontal; s.spacing = spacing; s.alignment = .centerY
    return s
}
func column(_ views: [NSView], spacing: CGFloat = 16) -> NSStackView {
    let s = NSStackView(views: views); s.orientation = .vertical; s.spacing = spacing; s.alignment = .leading
    return s
}
func spacer() -> NSView {
    let view = NSView(); view.setContentHuggingPriority(.defaultLow, for: .horizontal)
    return view
}
func pin(_ view: NSView, to parent: NSView, inset: CGFloat = 0) {
    view.translatesAutoresizingMaskIntoConstraints = false; parent.addSubview(view)
    NSLayoutConstraint.activate([
        view.leadingAnchor.constraint(equalTo: parent.leadingAnchor, constant: inset),
        view.trailingAnchor.constraint(equalTo: parent.trailingAnchor, constant: -inset),
        view.topAnchor.constraint(equalTo: parent.topAnchor, constant: inset),
        view.bottomAnchor.constraint(equalTo: parent.bottomAnchor, constant: -inset)
    ])
}
func inform(_ title: String, _ detail: String) {
    NSApp.activate(ignoringOtherApps: true)
    let alert = NSAlert(); alert.messageText = title; alert.informativeText = detail
    alert.addButton(withTitle: "知道了"); alert.runModal()
}
final class FloatingPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}
