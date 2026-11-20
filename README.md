# Tsumiru-Venera

A fork of [Suwayomi-Tsumiru](https://github.com/KatoSred/Suwayomi-Tsumiru) (a manga & webtoon reader for your [Suwayomi](https://github.com/Suwayomi/Suwayomi-Server) server) that adds a **second, fully independent reading engine** — a vendored build of [Venera](https://github.com/venera-app/venera) — alongside the native Tsumiru reader.

Works like a "default app" association: pick an engine in **Settings → Reader**, and every comic opens with it. Each engine keeps its own UI, interactions and settings.

## Features

- **Engine switch** (global, per-app): Tsumiru reader or Venera reader
- **Venera engine**: original Venera reader UI, 6 reading modes (paged LTR/RTL/TTB, continuous TTB/LTR/RTL), 1–5 images per page, dual-page with single first page, right-side settings panel, live-apply settings
- **Independent settings**: a dedicated "Venera Reader" page in app settings (16 options, zh-CN localized) plus an in-reader right-side panel; Tsumiru reader settings are untouched
- Windows desktop build

## Build

```bash
flutter build windows --release
```

## Deploy

Copy `build/windows/x64/runner/Release/` to the target folder (e.g. `D:\tsumiru\`).

## License

MPL-2.0 for the host app. The vendored Venera reader under `venera_engine/vendor/` is GPL-3.0, from [venera-app/venera](https://github.com/venera-app/venera).
