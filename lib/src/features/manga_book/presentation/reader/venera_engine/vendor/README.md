# venera_engine/vendor — Venera 阅读器 vendored 代码

> **⚠️ 许可证声明（GPL-3.0）**
>
> 本目录下的代码来自 [venera](https://github.com/venera-app/venera)（`lib/pages/reader/`），原项目许可证为 **GPL-3.0-or-later**（全文见本目录 [LICENSE](LICENSE)）。
>
> GPL-3.0 与宿主项目 Tsumiru 的 MPL-2.0 不兼容：**本目录代码一经与宿主合并，合并作品整体必须以 GPL-3.0 对外**。因此约定：
>
> 1. 本功能只在本地分支 `venera-engine` 上存在，**永不推送 GitHub 公开仓库、不进入公开 Release 构建产物**；
> 2. 含本目录的构建仅用于本机部署自用（不分发 → GPL 合规）；
> 3. 若未来需要分发，必须先重估许可（整体转 GPL-3.0，或按 Venera 思路重写实现）。
>
> 每个 vendored 文件头部保留了原版权声明并附加 `SPDX-License-Identifier: GPL-3.0-or-later` 与 vendored-and-modified 修改说明。

## 修改说明（相对上游 venera）

- 删除：`chapter_comments.dart`（Suwayomi 无评论数据源）、JS 自定义图片处理（flutter_qjs）、HistoryManager/WebDAV 同步（改桥接 Tsumiru 进度链路）、时钟/电量显示、图片快藏、window_frame。
- 替换：`ReaderImageProvider` → `TsumiruImageProvider`（adapter/，复用 Tsumiru 缓存与鉴权）；`appdata.settings`/`getReaderSetting` → Tsumiru ReaderSettingsState 桥接（adapter/compat/）；scaffold UI 重皮为 Tsumiru 风格。
- 保留：手势系统（gesture.dart）、连续/分页模式与图片加载 UI（images.dart/comic_image.dart）核心逻辑。

## 目录结构

- `reader.dart` — library 根，全部 import 集中于此（唯一系统性修改点，指向 adapter/compat shim）
- 其余文件为 `part of 'reader.dart'`
- `../adapter/` — Tsumiru ↔ Venera 桥接层（MPL-2.0，自有代码，不属于本 GPL 目录）
