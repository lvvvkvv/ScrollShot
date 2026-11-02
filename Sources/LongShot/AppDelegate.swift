import AppKit
import Carbon

@MainActor final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var welcome: NSWindow?
    private var homeView: HomeView?
    private var selector: RegionSelector?
    private var capture: CaptureController?
    private var previews: [PreviewController] = []
    private var previousApp: NSRunningApplication?
    private var hotkey: EventHotKeyRef?
    private var escapeKey: EventHotKeyRef?
    private var handler: EventHandlerRef?
    private let signature: OSType = 0x53534350

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        setupMenu(); setupShortcut(); showWelcome()
        NotificationCenter.default.addObserver(self, selector: #selector(refreshPermissions), name: NSApplication.didBecomeActiveNotification, object: nil)
    }
    private func setupMenu() {
        let main = NSMenu()
        let appMenu = NSMenu(); let appEntry = NSMenuItem(); appEntry.submenu = appMenu
        appMenu.addItem(withTitle: "关于 ScrollShot", action: #selector(showWelcome), keyEquivalent: "")
        appMenu.addItem(.separator()); appMenu.addItem(withTitle: "退出 ScrollShot", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        main.addItem(appEntry)
        let edit = NSMenu(); let editEntry = NSMenuItem(title: "编辑", action: nil, keyEquivalent: ""); editEntry.submenu = edit
        edit.addItem(withTitle: "剪切", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        edit.addItem(withTitle: "复制", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        edit.addItem(withTitle: "粘贴", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        edit.addItem(withTitle: "全选", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        main.addItem(editEntry); NSApp.mainMenu = main
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.image = NSImage(systemSymbolName: "rectangle.dashed.badge.record", accessibilityDescription: "ScrollShot")
        statusItem.button?.toolTip = "ScrollShot · 区域滚动截图"
        let menu = NSMenu()
        let start = NSMenuItem(title: "区域滚动截图", action: #selector(beginCapture), keyEquivalent: "s")
        start.keyEquivalentModifierMask = [.command, .option, .shift]; start.target = self; menu.addItem(start)
        let help = NSMenuItem(title: "使用说明与权限", action: #selector(showWelcome), keyEquivalent: ""); help.target = self; menu.addItem(help)
        let last = NSMenuItem(title: "上次截图", action: #selector(showPrevious), keyEquivalent: "")
        last.target = self; menu.addItem(last)
        menu.addItem(.separator())
        menu.addItem(withTitle: "退出 ScrollShot", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        statusItem.menu = menu
    }
    private func setupShortcut() {
        var type = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let ref = Unmanaged.passUnretained(self).toOpaque()
        InstallEventHandler(GetApplicationEventTarget(), { _, event, userData -> OSStatus in
            guard let event, let userData else { return OSStatus(eventNotHandledErr) }
            var id = EventHotKeyID()
            GetEventParameter(event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID), nil, MemoryLayout<EventHotKeyID>.size, nil, &id)
            let app = Unmanaged<AppDelegate>.fromOpaque(userData).takeUnretainedValue()
            let value = id.id
            Task { @MainActor in
                if value == 1 { app.beginCapture() } else { app.cancelCapture() }
            }
            return noErr
        }, 1, &type, ref, &handler)
        let result = RegisterEventHotKey(UInt32(kVK_ANSI_S), UInt32(cmdKey | optionKey | shiftKey), EventHotKeyID(signature: signature, id: 1), GetApplicationEventTarget(), 0, &hotkey)
        if result != noErr { NSLog("ScrollShot: shortcut unavailable (%d); use menu bar", result) }
    }
    private func registerEscape() {
        guard escapeKey == nil else { return }
        RegisterEventHotKey(UInt32(kVK_Escape), 0, EventHotKeyID(signature: signature, id: 2), GetApplicationEventTarget(), 0, &escapeKey)
    }
    private func unregisterEscape() { if let escapeKey { UnregisterEventHotKey(escapeKey) }; escapeKey = nil }
    @objc func beginCapture() {
        guard selector == nil, capture == nil else { NSSound.beep(); return }
        guard CGPreflightScreenCaptureAccess() else { showWelcome(); requestPermission(); return }
        previousApp = NSWorkspace.shared.frontmostApplication
        if previousApp?.processIdentifier == ProcessInfo.processInfo.processIdentifier { previousApp = nil }
        welcome?.orderOut(nil); previews.forEach { $0.hide() }
        registerEscape()
        let s = RegionSelector(); selector = s
        s.onCancel = { [weak self] in self?.selector = nil; self?.unregisterEscape(); self?.showWelcome() }
        s.onSelect = { [weak self] region, screen in
            guard let self else { return }
            self.selector = nil
            let c = CaptureController(region: region, screen: screen, targetApp: self.previousApp)
            self.capture = c
            c.onResult = { [weak self, weak c] image in
                guard let self, let c, self.capture === c else { return }
                self.unregisterEscape(); self.capture = nil; self.showPreview(image)
            }
            c.onCancel = { [weak self, weak c] in
                guard let self, let c, self.capture === c else { return }
                self.unregisterEscape(); self.capture = nil; self.showWelcome()
            }
            c.onReselect = { [weak self, weak c] in
                guard let self, let c, self.capture === c else { return }
                self.unregisterEscape(); self.capture = nil; self.beginCapture()
            }
            c.show()
        }
        s.show()
    }
    private func cancelCapture() {
        if let selector { selector.dismiss(); self.selector = nil; unregisterEscape(); showWelcome() }
        else { capture?.cancel() }
    }
    @objc private func showPrevious() {
        guard capture == nil, selector == nil else { NSSound.beep(); return }
        if let latest = previews.last { latest.present() } else { showWelcome() }
    }
    private func showPreview(_ image: CGImage) {
        previews.forEach { $0.hide() }; previews.removeAll()
        let controller = PreviewController(image: image)
        controller.onNewCapture = { [weak self] in self?.beginCapture() }
        controller.onClose = { [weak self, weak controller] in self?.previews.removeAll { $0 === controller } }
        previews.append(controller); controller.show()
    }
    func application(_ sender: NSApplication, openFile filename: String) -> Bool {
        guard let image = NSImage(contentsOfFile: filename),
              let cg = image.cgImage(forProposedRect: nil, context: nil, hints: nil),
              cg.width * cg.height <= 80_000_000 else { return false }
        welcome?.orderOut(nil); showPreview(cg); return true
    }
    @objc func showWelcome() {
        if welcome == nil { createWelcome() }
        refreshPermissions(); homeView?.recentButton.isEnabled = !previews.isEmpty
        welcome?.makeKeyAndOrderFront(nil); NSApp.activate(ignoringOtherApps: true)
    }
    private func createWelcome() {
        let window = NSWindow(contentRect: CGRect(x: 0, y: 0, width: 920, height: 600), styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView], backing: .buffered, defer: false)
        window.title = "ScrollShot"; window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true; window.isReleasedWhenClosed = false
        window.backgroundColor = Theme.background
        window.standardWindowButton(.zoomButton)?.isHidden = true
        let home = HomeView(capture: { [weak self] in self?.beginCapture() },
                            previous: { [weak self] in self?.showPrevious() },
                            permission: { [weak self] in self?.showPermissionSettings() },
                            help: { [weak self] in self?.showGuide() })
        window.contentView = home; homeView = home
        window.center(); welcome = window
    }
    @objc private func refreshPermissions() {
        homeView?.updatePermission(CGPreflightScreenCaptureAccess())
    }
    private func showPermissionSettings() {
        if CGPreflightScreenCaptureAccess() {
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") { NSWorkspace.shared.open(url) }
        } else { requestPermission() }
    }
    private func showGuide() {
        inform("开始你的第一张长截图", "1. 框选需要的正文，避开固定标题栏和输入框。\n2. 点击开始捕获，在选区中缓慢向下滚动。\n3. 点击完成，复制或保存原始分辨率 PNG。\n\n⌘ ⇧ ⌥ S：唤起截图  ·  Esc：取消\n自动滚动需要辅助功能权限；手动滚动无需这项权限。\n\n遇到画面无法衔接，向上回滚一些，再缓慢向下继续。")
    }
    private func requestPermission() {
        if CGPreflightScreenCaptureAccess() { refreshPermissions(); return }
        _ = CGRequestScreenCaptureAccess()
        refreshPermissions()
        if !CGPreflightScreenCaptureAccess() {
            inform("请开启屏幕录制权限", "在「系统设置 → 隐私与安全性 → 屏幕与系统音频录制」中开启 ScrollShot。\n\n如果列表里没有它，请用 + 添加此应用。授权后重新打开 ScrollShot。")
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") { NSWorkspace.shared.open(url) }
        }
    }
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }
}
