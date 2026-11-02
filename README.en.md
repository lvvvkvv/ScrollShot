# ScrollShot

A native macOS app for regional scrolling screenshots. Select an area, scroll downward, then preview, copy or save a full-resolution PNG. Chinese UI, light/dark workspace, no account or upload.

[Download](https://github.com/lvvvkvv/ScrollShot/releases/latest) · [中文说明](README.md) · [MIT License](LICENSE)

![ScrollShot](docs/images/ScrollShot-home-light.png)

## Requirements

macOS 14 or later. The supplied prebuilt app targets Apple Silicon (M1 and newer).

The current release is an early preview with an ad hoc local signature; it is not Developer ID signed or notarized. Screen Recording permission may need to be removed and granted again after an update. A stable Developer ID identity is needed for production distribution.

## Use

1. Allow Screen Recording in System Settings → Privacy & Security, then relaunch.
2. Choose a scrollable content region. Exclude fixed headers, input bars and scrollbars.
3. Start capture, scroll downward slowly, then finish.
4. Preview, copy, or save PNG. Command–Shift–Option–S starts selection; Escape cancels. In preview, Command–S saves and Command–C copies.

Auto-scroll additionally requires Accessibility permission. Manual scrolling does not.

## Build and test

Install Apple Command Line Tools or Xcode, then run:

```sh
./test.sh
./build-app.sh "$PWD/dist"
```

The app is written to `dist/ScrollShot.app`. There are no external dependencies. Internal Swift Package targets retain the names LongShot and LongShotCore.

```sh
./test-selection.sh
```

The extra AppKit cursor checks briefly display selection overlays and require an interactive logged-in Mac desktop.

## Limits

Downward vertical capture only. Animated content, repeated patterns, blank regions, sticky elements, lazy loading and virtualized lists can prevent matching. Keep frames overlapping; scroll back slightly to reconnect after a mismatch. Do not resize/move the target or change zoom/displays during capture. Each image is limited to 80 million pixels or 40,000 px height. Only the most recent preview is retained; save images you need.

Full cross-app, multi-display and auto-scroll compatibility has not yet been validated. UI preview images are native view renders with synthetic document content.

## License and contributions

MIT. Issues and contributions are welcome. Include macOS version, chip, target app and reproduction steps; avoid sharing private screenshots. Code and artwork were created for ScrollShot. CleanShot X is a workflow reference only; no CleanShot code or assets are included.
