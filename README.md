# Tsumiru-Venera

[Suwayomi-Tsumiru](https://github.com/KatoSred/Suwayomi-Tsumiru) 的分支版——为连接 [Suwayomi](https://github.com/Suwayomi/Suwayomi-Server) 服务器的漫画阅读器内置了**第二套完全独立的阅读器引擎**：整体移植的 [Venera](https://github.com/venera-app/venera) 阅读器，与原生 Tsumiru 阅读器并存。

工作方式类似"文件默认打开应用"：在 **设置 → 阅读器** 里选一个引擎，之后所有漫画都用它打开。两套引擎的界面、交互、设置互相独立。

## 功能

- **引擎切换**（全局）：Tsumiru 阅读器 / Venera 阅读器
- **Venera 引擎**：原版 Venera 界面，6 种阅读模式（分页左右/双向、连续上下/左右）、每屏 1-5 张图、双页时首页单图、右侧滑出设置面板、设置即时生效
- **独立设置**：应用设置新增专属"Venera 阅读器"页（16 项全量中文）+ 阅读器内右侧面板；Tsumiru 阅读器设置不受影响
- Windows 桌面端

## 构建

```bash
flutter build windows --release
```

## 部署

把 `build/windows/x64/runner/Release/` 整个目录复制到目标文件夹（如 `D:\tsumiru\`）即可运行。

## 许可证

宿主应用：MPL-2.0；`venera_engine/vendor/` 内的 Venera 移植代码：GPL-3.0，源自 [venera-app/venera](https://github.com/venera-app/venera)。
