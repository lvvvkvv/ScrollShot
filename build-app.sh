#!/bin/zsh
set -eu
cd "${0:A:h}"
SCROLLSHOT_DEST="${1:-$PWD/dist}"
mkdir -p "$SCROLLSHOT_DEST"
SCROLLSHOT_DEST="${SCROLLSHOT_DEST:A}"
swift build -c release --product LongShot
SCROLLSHOT_BIN="$(swift build -c release --show-bin-path)/LongShot"
SCROLLSHOT_APP="$SCROLLSHOT_DEST/ScrollShot.app"
mkdir -p "$SCROLLSHOT_APP/Contents/MacOS" "$SCROLLSHOT_APP/Contents/Resources"
cp "$SCROLLSHOT_BIN" "$SCROLLSHOT_APP/Contents/MacOS/ScrollShot"
cp Assets/ScrollShot.icns "$SCROLLSHOT_APP/Contents/Resources/ScrollShot.icns"
cat > "$SCROLLSHOT_APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleName</key><string>ScrollShot</string>
<key>CFBundleDisplayName</key><string>ScrollShot</string>
<key>CFBundleExecutable</key><string>ScrollShot</string>
<key>CFBundleIdentifier</key><string>local.scrollshot.app</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleVersion</key><string>3</string>
<key>CFBundleShortVersionString</key><string>0.2.1</string>
<key>CFBundleIconFile</key><string>ScrollShot</string>
<key>LSMinimumSystemVersion</key><string>14.0</string>
<key>LSUIElement</key><true/>
<key>NSHighResolutionCapable</key><true/>
<key>NSPrincipalClass</key><string>NSApplication</string>
<key>NSScreenCaptureUsageDescription</key><string>ScrollShot 需要捕获你框选的屏幕区域，将滚动内容拼接为长图。截图仅在本机处理。</string>
</dict></plist>
PLIST
codesign --force --sign - --identifier local.scrollshot.app "$SCROLLSHOT_APP"
codesign --verify --deep --strict "$SCROLLSHOT_APP"
print "Built: $SCROLLSHOT_APP"
