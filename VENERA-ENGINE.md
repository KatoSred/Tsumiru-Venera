# Venera 阅读器引擎 · 收尾文档

> 双阅读器引擎方案（M1–M4 及后续修复轮）的架构、机制与遗留事项汇总。
> 开发过程明细见 `HANDOFF.md`；本文是交付快照。

## 一句话定位

Tsumiru 内置第二套阅读器引擎——vendored Venera（GPL 原版代码整体移植），与原生 Tsumiru 阅读器并存，按"默认打开应用"模型工作：应用级设置选择全局默认引擎，两套阅读器的界面、交互与设置完全独立。

## 架构

```
lib/src/features/manga_book/presentation/reader/
├── venera_engine/
│   ├── vendor/                  # Venera 原版代码（GPL-3.0），part 文件形式
│   │   ├── reader.dart          #   Reader 主状态机 + 控制器接口
│   │   ├── scaffold.dart        #   顶栏/底栏/页码徽章/浮动按钮
│   │   ├── images.dart          #   分页(_GalleryMode)/连续(_ContinuousMode)视图
│   │   ├── comic_image.dart     #   图片组件（宿主 cacheManager）
│   │   ├── gesture.dart         #   手势菜单
│   │   ├── chapters.dart        #   章节侧栏
│   │   └── custom_slider.dart   #   原版滑杆（RTL 支持）
│   └── adapter/
│       ├── venera_engine_screen.dart   # 引擎宿主屏：设置快照注入 + 生命周期桥
│       ├── venera_settings_panel.dart  # Venera 专属设置面板（右滑）
│       └── compat/                     # MPL 兼容层（零 riverpod 进 vendor）
│           ├── appdata_shim.dart       #   getReaderSetting → VeneraSettingsBridge
│           ├── components_shim.dart    #   showSideBar(右滑)/NetworkError/BlurEffect 等
│           └── ext_shim.dart           #   .tl 翻译表/ts/context 扩展
└── controller/reader_settings_model.dart  # 引擎选择 + venera 设置接入模型
```

分区规则：`vendor/` 零 riverpod、零宿主依赖（GPL）；`adapter/compat/` 为宿主侧桥（MPL）；vendor 内对原版的每处改动都带 `VENDOR-CUT` 注释。

## 功能清单

- **引擎切换**：全局唯一真源 `readerEngineKeyProvider`（SharedPreferences `appTheme` 同款枚举存储）；入口仅应用级「设置 → 阅读器」页顶部。引擎为全局设置，无 per-series 覆盖（早期 per-series meta 已移除，残留 `flutter_readerEngine` meta 被忽略）。
- **应用级「Venera 阅读器」设置页**（侧边栏新开一栏，路由 `venera-reader`）：四分组 16 项全量暴露——阅读模式（六模式 chips）/每页图片数/双页首页单图、手势 5 项、显示 2 项、行为 6 项；已注册设置搜索。
- **阅读器内两套面板完全独立**：Venera 引擎的设置按钮弹出右侧滑出面板（`showVeneraSettingsPanel`，移植原版 SideBarRoute）；Tsumiru 引擎行为零变化。
- **设置即时生效**：面板改动 → 模型重建 → `syncLiveSettings()` 在子树构建前同步重映射页码/模式 → 视图按新设置挂载。阅读模式与每页图片数均实时生效，无需重进。
- **Venera 设置中文化**：全部条目 zh/zh_Hant 已译；vendored `.tl` 界面串（全屏/自动翻页/章节/保存图片等）有中文映射表。

## 关键机制

### 设置桥接

`VeneraSettingsBridge.instance.snapshot`（`venera_engine_screen.dart` 每次 build 重算）是 vendored 读取设置的唯一数据源；`appdata_shim.getReaderSetting()` 查表，vendored 17 个 key 全部由 Venera 专属 DBKeys 驱动。

### 切模式页码映射（syncLiveSettings）

两模式页码语义不同：分页一屏 `imagesPerPage` 张图（`maxPage = ceil(N/per)`，含"首页单图"修正），连续一图一页（`maxPage = N`）。切模式时：旧模式页 → 图片索引（公式同 `_updateHistoryState`）→ 新模式页码，双向 clamp。**必须在宿主屏 build 内、子树构建之前同步执行**（`controllerRef.value?.syncLiveSettings()`）——postFrame 补救会让新视图带旧页码挂载、页码修正后视图也不会跳转（已踩坑两轮）。

### 样式隔离

vendored 子树内 `MaterialLocalizations` 不可达（深层原因未查明）：所有隐式依赖 ML 的组件已替换（BackButton → IconButton、AppBar 禁自动 leading、showModalBottomSheet → 自研 PopupRoute）。vendored 子树内所有可见 `Text` 必须 `TextStyle(inherit: false, ...)` 显式声明——继承链会泄漏黄色下划线 decoration（症状："红字黄底"）。

## 已裁剪功能（决策记录）

章节评论、图片快藏（心形收藏）、时钟/电量显示、JS 引擎——均为用户确认丢弃；恢复心形收藏需本地化实现。

## 已知限制与遗留

1. 其余 21 种语言的 Venera 设置 l10n 回退英文（zh/zh_Hant 已译全）。
2. vendored 子树拿不到 `MaterialLocalizations` 的深层原因未查明（防御性修复已覆盖全部受影响组件）。
3. `flutter.veneraContinuousDefault` 为已废弃的 SharedPreferences 键，无读取方，残留无害。
4. vendored 自动翻页定时器的 `autoPageTurningInterval` 快照已通，行为按原版。

## 提交里程碑（venera-engine 分支）

| 阶段 | 提交 | 内容 |
|---|---|---|
| M1–M3 | `8ba768c`–`fda0e44` | vendor 骨架、图片管线（共享缓存+进度）、进度/章节桥 |
| M4 | `f97eeb5` | 引擎切换 + 设置接入 |
| M4.5 | `4d2207f` | 六模式选择器 |
| 定位变更 | `81ad567`–`4c9ec25` | 撤销重皮恢复原版视觉 → 设置独立化（侧边栏/全量暴露/双面板） |
| 修复轮 | `7b818a0`–`0a64dfa` | 枚举持久化、面板引擎纯净、切模式页码映射（时序）、本地化隔离等 |

## 部署

构建产物 `build/windows/x64/runner/Release/` → 部署目标 `D:\tsumiru\`（全量覆盖，进程须先关闭）；验收由用户手动进行。
