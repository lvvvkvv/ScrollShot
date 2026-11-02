import AppKit

final class CaptureHUDView: NSView {
    let status = label("点击开始后，在选区中缓慢向下滚动", 11, color: Theme.secondary)
    let dimensions = label("", 11, .medium, color: Theme.secondary)
    let startButton: ActionButton
    let autoButton: ActionButton
    init(start: @escaping () -> Void, automatic: @escaping () -> Void, reselect: @escaping () -> Void, cancel: @escaping () -> Void) {
        startButton = ActionButton("开始捕获", primary: true, icon: "record.circle", action: start)
        autoButton = ActionButton("自动滚动：关", icon: "arrow.down", action: automatic)
        super.init(frame: CGRect(x: 0, y: 0, width: 556, height: 124))
        pin(Surface(radius: 14), to: self)
        let top = row([symbol("rectangle.dashed", size: 13, color: Theme.accent), label("区域滚动截图", 12, .semibold), spacer(), dimensions], spacing: 7)
        let reselectButton = ActionButton("重新框选", icon: "viewfinder", quiet: true, action: reselect)
        let cancelButton = ActionButton("取消", icon: "xmark", quiet: true, action: cancel)
        let controls = row([startButton, autoButton, spacer(), reselectButton, cancelButton], spacing: 8)
        let body = column([top, controls, status], spacing: 11)
        body.alignment = .leading
        pin(body, to: self, inset: 15)
        top.widthAnchor.constraint(equalTo: body.widthAnchor).isActive = true
        controls.widthAnchor.constraint(equalTo: body.widthAnchor).isActive = true
        startButton.widthAnchor.constraint(equalToConstant: 116).isActive = true
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
