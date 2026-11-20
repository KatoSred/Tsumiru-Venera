// Copyright (C) 2024-2026 venera-app contributors
// SPDX-License-Identifier: GPL-3.0-or-later
//
// Vendored from https://github.com/venera-app/venera (lib/pages/reader/)
// and modified for Tsumiru on 2026-11-20:
//  - VENDOR-CUT: ImageFavoriteManager / ImageFavorite collection features
//    removed (collect button, isLiked, addImageFavorite, quickCollectImage
//    drag listener and related toasts).
//  - VENDOR-CUT: chapter-comments entry points removed
//    (shouldShowChapterComments / openChapterComments / comments icon).
//  - VENDOR-CUT: _BatteryWidget / _ClockWidget and
//    enableClockAndBatteryInfoInReader removed (battery_plus dependency).
//  - VENDOR-CUT: venera ReaderSettings page entry replaced with a M4
//    placeholder side bar.
//  - VENDOR-CUT: CustomSlider replaced by native Slider in M1, then by
//    Tsumiru's BrandPageSeekBar in M5 (which also covers the `reversed`
//    hint via `inverted`).
//  - VENDOR-CUT: CacheManager reads replaced by flutter_cache_manager
//    (DefaultCacheManager) for save/share image bytes.
//  - Settings reads bridged to compat getReaderSetting.
//  - showToast/showSideBar/BlurEffect/ts/.tl/context extensions come from
//    compat shims.
//  - M5 reskin: chrome visuals restyled to Tsumiru (layout skeleton, show/hide
//    state machine, animation timings and gesture wiring untouched). All
//    colors come from colorScheme / _readerNavSurface; icons are FluentIcons;
//    the progress seekbar is Tsumiru's BrandPageSeekBar imported directly (its
//    dependency surface is flutter/material + material_ui theme extensions
//    only — no riverpod — see reader.dart imports).

part of 'reader.dart';

/// Mirror of Tsumiru's `readerNavSurface` (utils/theme/brand.dart).
///
/// TYPE NOTE: brand.dart's helper takes material_ui's own `ColorScheme` type
/// (material_ui shadows flutter's), so calling it with the vendor shim's
/// flutter `context.colorScheme` fails to compile. The vendor keeps flutter
/// types end-to-end and re-implements the one-line formula here instead of
/// pulling material_ui into the vendored reader. Keep in sync with brand.dart.
Color _readerNavSurface(ColorScheme cs) =>
    cs.surface.withValues(
      alpha: cs.brightness == Brightness.dark ? 0.9 : 0.95,
    );

class _ReaderScaffold extends StatefulWidget {
  const _ReaderScaffold({required this.child});

  final Widget child;

  @override
  State<_ReaderScaffold> createState() => _ReaderScaffoldState();
}

class _ReaderScaffoldState extends State<_ReaderScaffold> {
  bool _isOpen = false;

  static const kTopBarHeight = 56.0;

  static const kBottomBarHeight = 105.0;

  bool get isOpen => _isOpen;

  bool get isReversed =>
      context.reader.mode == ReaderMode.galleryRightToLeft ||
      context.reader.mode == ReaderMode.continuousRightToLeft;

  int showFloatingButtonValue = 0;

  var lastValue = 0;

  _ReaderGestureDetectorState? _gestureDetectorState;

  void setFloatingButton(int value) {
    lastValue = showFloatingButtonValue;
    if (value == 0) {
      if (showFloatingButtonValue != 0) {
        showFloatingButtonValue = 0;
        update();
      }
    }
    if (value == 1 && showFloatingButtonValue == 0) {
      showFloatingButtonValue = 1;
      update();
    } else if (value == -1 && showFloatingButtonValue == 0) {
      showFloatingButtonValue = -1;
      update();
    }
  }

  @override
  void initState() {
    // M5: the sliderFocus node (venera CustomSlider focus guard) is gone with
    // the native Slider — BrandPageSeekBar is a pure GestureDetector.
    if (rotation != null) {
      SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    }
    super.initState();
    // VENDOR-CUT: Future.delayed addDragListener removed with the
    // quickCollectImage (Swipe) feature.
  }

  void openOrClose() {
    if (!_isOpen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    } else {
      if (!getReaderSetting(
        context.reader.cid,
        context.reader.type.sourceKey,
        'showSystemStatusBar',
      )) {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
      } else {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      }
    }
    setState(() {
      _isOpen = !_isOpen;
    });
  }

  bool? rotation;

  void update() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: AbsorbPointer(
            absorbing: context.reader.isPageAnimating,
            child: widget.child,
          ),
        ),
        if (getReaderSetting(
          context.reader.cid,
          context.reader.type.sourceKey,
          'showPageNumberInReader',
        ))
          buildPageInfoText(),
        // VENDOR-CUT: buildStatusInfo (clock/battery widgets) removed with
        // the battery_plus dependency.
        AnimatedPositioned(
          duration: const Duration(milliseconds: 180),
          right: 16,
          bottom: showFloatingButtonValue == 0 ? -58 : 36,
          child: buildEpChangeButton(),
        ),
        AnimatedPositioned(
          duration: const Duration(milliseconds: 180),
          top: _isOpen ? 0 : -(kTopBarHeight + context.padding.top),
          left: 0,
          right: 0,
          height: kTopBarHeight + context.padding.top,
          child: buildTop(),
        ),
        AnimatedPositioned(
          duration: const Duration(milliseconds: 180),
          bottom: _isOpen
              ? 0
              : -(kBottomBarHeight + MediaQuery.of(context).padding.bottom),
          left: 0,
          right: 0,
          child: buildBottom(),
        ),
      ],
    );
  }

  Widget buildTop() {
    final epName =
      context.reader.widget.chapters?.titles.elementAtOrNull(
        context.reader.chapter - 1,
      );
    // M5: Tsumiru chrome typography — title 16/w600 like reader_top_bar's
    // title treatment; secondary line muted. Layout skeleton unchanged.
    final colorScheme = context.colorScheme;

    return BlurEffect(
      child: Container(
        padding: EdgeInsets.only(top: context.padding.top),
        decoration: BoxDecoration(
          // Same translucent surface treatment as Tsumiru's readerNavSurface.
          color: _readerNavSurface(colorScheme),
          border: Border(
            bottom: BorderSide(
              color: colorScheme.outlineVariant,
              width: 0.5,
            ),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.only(
            left: context.padding.left,
            right: context.padding.right,
          ),
          child: Row(
            children: [
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => context.pop(),
                icon: Icon(
                  FluentIcons.ios_arrow_24_regular,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: epName == null ? Text(
                  context.reader.widget.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ) : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      context.reader.widget.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      epName,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // VENDOR-CUT: "Chapter Comments" icon button removed with the
              // chapter-comments feature.
              Tooltip(
                message: "Settings".tl,
                child: IconButton(
                  icon: Icon(
                    FluentIcons.settings_24_regular,
                    color: colorScheme.onSurface,
                  ),
                  onPressed: openSetting,
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildBottom() {
    // Use maxPage for display
    final displayPage = context.reader.page.clamp(1, context.reader.maxPage);
    var text = "E${context.reader.chapter} : P$displayPage";
    if (context.reader.widget.chapters == null) {
      text = "P$displayPage";
    }
    final colorScheme = context.colorScheme;

    final buttons = [
      // VENDOR-CUT: "Collect the image" button removed with the
      // ImageFavoriteManager feature.
      if (App.isDesktop)
        Tooltip(
          message: "${"Full Screen".tl}(F12)",
          child: IconButton(
            icon: Icon(
              FluentIcons.full_screen_maximize_24_regular,
              color: colorScheme.onSurface,
            ),
            onPressed: () {
              context.reader.fullscreen();
            },
          ),
        ),
      if (App.isAndroid)
        Tooltip(
          message: "Screen Rotation".tl,
          child: IconButton(
            icon: () {
              if (rotation == null) {
                return Icon(
                  FluentIcons.arrow_rotate_clockwise_24_regular,
                  color: colorScheme.onSurface,
                );
              } else if (rotation == false) {
                return Icon(
                  FluentIcons.arrow_autofit_height_24_regular,
                  color: colorScheme.onSurface,
                );
              } else {
                return Icon(
                  FluentIcons.arrow_autofit_width_24_regular,
                  color: colorScheme.onSurface,
                );
              }
            }.call(),
            onPressed: () {
              if (rotation == null) {
                setState(() {
                  rotation = false;
                });
                SystemChrome.setPreferredOrientations([
                  DeviceOrientation.portraitUp,
                  DeviceOrientation.portraitDown,
                ]);
              } else if (rotation == false) {
                setState(() {
                  rotation = true;
                });
                SystemChrome.setPreferredOrientations([
                  DeviceOrientation.landscapeLeft,
                  DeviceOrientation.landscapeRight,
                ]);
              } else {
                setState(() {
                  rotation = null;
                });
                SystemChrome.setPreferredOrientations(DeviceOrientation.values);
              }
            },
          ),
        ),
      Tooltip(
        message: "Auto Page Turning".tl,
        child: IconButton(
          icon: context.reader.autoPageTurningTimer != null
              ? Icon(
                  FluentIcons.timer_24_filled,
                  color: colorScheme.primary,
                )
              : Icon(
                  FluentIcons.timer_24_regular,
                  color: colorScheme.onSurface,
                ),
          onPressed: () {
            context.reader.autoPageTurning(
              context.reader.cid,
              context.reader.type,
            );
            update();
          },
        ),
      ),
      if (context.reader.widget.chapters != null)
        Tooltip(
          message: "Chapters".tl,
          child: IconButton(
            icon: Icon(
              FluentIcons.library_24_regular,
              color: colorScheme.onSurface,
            ),
            onPressed: openChapterDrawer,
          ),
        ),
      Tooltip(
        message: "Save Image".tl,
        child: IconButton(
          icon: Icon(
            FluentIcons.arrow_download_24_regular,
            color: colorScheme.onSurface,
          ),
          onPressed: saveCurrentImage,
        ),
      ),
      Tooltip(
        message: "Share".tl,
        child: IconButton(
          icon: Icon(
            FluentIcons.share_24_regular,
            color: colorScheme.onSurface,
          ),
          onPressed: share,
        ),
      ),
    ];

    Widget child = SizedBox(
      height: kBottomBarHeight,
      child: Column(
        children: [
          const SizedBox(height: 8),
          Row(
            children: [
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => !isReversed
                    ? context.reader.chapter > 1
                          ? context.reader.toPrevChapter()
                          : context.reader.toPage(1)
                    : context.reader.chapter < context.reader.maxChapter
                    ? context.reader.toNextChapter()
                    : context.reader.toPage(context.reader.maxPage),
                // Same chapter-skip glyphs as Tsumiru's chapterNavButtons.
                icon: Icon(
                  FluentIcons.previous_24_filled,
                  color: colorScheme.primary,
                ),
              ),
              Expanded(child: buildSlider()),
              IconButton(
                onPressed: () => !isReversed
                    ? context.reader.chapter < context.reader.maxChapter
                          ? context.reader.toNextChapter()
                          : context.reader.toPage(context.reader.maxPage)
                    : context.reader.chapter > 1
                    ? context.reader.toPrevChapter()
                    : context.reader.toPage(1),
                icon: Icon(
                  FluentIcons.next_24_filled,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
          LayoutBuilder(
            builder: (context, constrains) {
              final small = (constrains.maxWidth - buttons.length * 50) < 120;
              return Row(
                children: [
                  if (!small)
                    Container(
                      height: 24,
                      padding: const EdgeInsets.fromLTRB(10, 2, 10, 0),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Center(
                        child: Text(
                          text,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                            fontFeatures: const [
                              FontFeature.tabularFigures(),
                            ],
                          ),
                        ),
                      ),
                    ).paddingLeft(16),
                  const Spacer(),
                  for (var button in buttons)
                    if (!small)
                      button.paddingHorizontal(4)
                    else
                      ...[button, const Spacer()],
                  if (!small)
                    const SizedBox(width: 4),
                ],
              );
            },
          ),
        ],
      ),
    );

    return BlurEffect(
      child: Container(
        decoration: BoxDecoration(
          color: _readerNavSurface(colorScheme),
          border: isOpen
              ? Border(
                  top: BorderSide(
                    color: colorScheme.outlineVariant,
                    width: 0.5,
                  ),
                )
              : null,
        ),
        padding: EdgeInsets.only(bottom: context.padding.bottom),
        child: Padding(
          padding: EdgeInsets.only(
            left: context.padding.left,
            right: context.padding.right,
          ),
          child: child,
        ),
      ),
    );
  }

  Widget buildSlider() {
    // M5: venera CustomSlider -> native Slider (M1) -> Tsumiru's
    // BrandPageSeekBar (M5).
    //
    // IMPORT DECISION: BrandPageSeekBar is imported directly
    // (reader.dart -> ../../widgets/brand_page_seekbar.dart). Its dependency
    // surface is flutter/material + material_ui theme lookups +
    // BrandColors/readerNavSurface from utils/theme/brand.dart — no riverpod,
    // no Tsumiru controller/state layer — so direct use keeps the seekbar
    // pixel-identical with Tsumiru's reader (rounded track, brand gradient
    // fill, page ticks, glowing marker) and stays theme-aware in both modes.
    // The seekbar is 0-based, venera's reader page is 1-based; `inverted`
    // covers the RTL/reversed hint the old CustomSlider carried.
    final displayPage = context.reader.page.clamp(1, context.reader.maxPage);
    return BrandPageSeekBar(
      currentValue: displayPage - 1,
      maxValue: context.reader.maxPage.clamp(1, 1 << 16),
      onChanged: (i) {
        context.reader.toPage(i + 1);
      },
      inverted: isReversed,
      capsuleColor: _readerNavSurface(context.colorScheme),
    );
  }

  Widget buildPageInfoText() {
    var epName =
        context.reader.widget.chapters?.titles.elementAtOrNull(
          context.reader.chapter - 1,
        ) ??
        "E${context.reader.chapter}";
    if (epName.length > 8) {
      epName = "${epName.substring(0, 8)}...";
    }
    var pageText = "${context.reader.page}/${context.reader.maxPage}";
    var text = context.reader.widget.chapters != null
        ? "$epName : $pageText"
        : pageText;

    return Positioned(
      bottom: 13,
      left: 25,
      child: Stack(
        children: [
          // Keep the stroke trick for readability over page art, but derive
          // both colors from the theme surface pair.
          Text(
            text,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              foreground: Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = 1.4
                ..color = context.colorScheme.surface,
            ),
          ),
          Text(
            text,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: context.colorScheme.onSurface,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  void openChapterDrawer() {
    _openSideBar(
      context.reader.widget.chapters!.isGrouped
          ? _GroupedChaptersView(context.reader)
          : _ChaptersView(context.reader),
      width: 400,
    );
  }

  void saveCurrentImage() async {
    var result = await selectImageToData();
    if (result == null) {
      return;
    }
    var (imageIndex, data) = result;
    var fileType = detectFileType(data);
    // Save file name: ComicName_EP{chapter}_P{page}.{ext} to avoid conflict.
    // The chapter index of different group is continuous, so we use chapter number is enough.
    var filename =
        "${context.reader.widget.name}_EP${context.reader.chapter}_P${imageIndex + 1}${fileType.ext}";
    saveFile(data: data, filename: filename);
  }

  void share() async {
    var result = await selectImageToData();
    if (result == null) {
      return;
    }
    var (imageIndex, data) = result;
    var fileType = detectFileType(data);
    var filename =
        "${context.reader.widget.name}_EP${context.reader.chapter}_P${imageIndex + 1}${fileType.ext}";
    // VENDOR-CUT: venera Share.shareFile replaced by share_plus (Tsumiru's
    // existing dependency). Bytes are staged in the temp directory.
    final tempFile = File(
      '${Directory.systemTemp.path}/$filename',
    );
    await tempFile.writeAsBytes(data);
    await SharePlus.instance.share(
      ShareParams(files: [XFile(tempFile.path, mimeType: fileType.mime)]),
    );
  }

  void openSetting() {
    // ADAPTER(M4): host callback opens Tsumiru's settings sheet; the M1
    // placeholder remains only when the host supplies no callback.
    final openHostSettings = context.reader.widget.onOpenSettings;
    if (openHostSettings != null) {
      openHostSettings();
      return;
    }
    _openSideBar(
      const _ReaderSettingsPlaceholder(),
      width: 400,
    );
  }

  void _openSideBar(Widget widget, {double width = 400}) {
    _gestureDetectorState?.ignoreNextTap();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showSideBar(
        context,
        widget,
        width: width,
        dismissible: true,
      ).whenComplete(() {
        _gestureDetectorState?.clearIgnoreNextTap();
      });
    });
  }

  Widget buildEpChangeButton() {
    final extraWidth = context.padding.left + context.padding.right;
    if (context.reader.widget.chapters == null) return const SizedBox();
    switch (showFloatingButtonValue) {
      case 0:
        return Container(
          width: 58 + extraWidth,
          height: 58,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: context.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            lastValue == 1
                ? FluentIcons.ios_arrow_rtl_24_regular
                : FluentIcons.ios_arrow_24_regular,
            size: 24,
            color: context.colorScheme.onPrimaryContainer,
          ),
        );
      case -1:
      case 1:
        return SizedBox(
          width: 58 + extraWidth,
          height: 58,
          child: Material(
            color: context.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(16),
            elevation: 2,
            child: InkWell(
              onTap: () {
                if (showFloatingButtonValue == 1) {
                  context.reader.toNextChapter();
                } else if (showFloatingButtonValue == -1) {
                  context.reader.toPrevChapter();
                }
                setFloatingButton(0);
              },
              borderRadius: BorderRadius.circular(16),
              child: Center(
                child: Icon(
                  _getArrowIcon(
                    isReversed,
                    showFloatingButtonValue,
                  ),
                  size: 24,
                  color: context.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ),
        );
    }
    return const SizedBox();
  }

  IconData _getArrowIcon(bool reversed, int value) {
    if (reversed) {
      return value == 1
          ? FluentIcons.ios_arrow_24_regular
          : FluentIcons.ios_arrow_rtl_24_regular;
    } else {
      return value == 1
          ? FluentIcons.ios_arrow_rtl_24_regular
          : FluentIcons.ios_arrow_24_regular;
    }
  }

  /// If there is only one image on screen, return it.
  ///
  /// If there are multiple images on screen,
  /// show an overlay to let the user select an image.
  ///
  /// The return value is the index of the selected image.
  Future<int?> selectImage() async {
    var reader = context.reader;
    var imageViewController = context.reader._imageViewController;

    bool needsSelection = false;
    int? singleImageIndex;

    if (imageViewController is _GalleryModeState) {
      var range = imageViewController.getCurrentPageImageRange();
      if (range != null) {
        var (startIndex, endIndex) = range;
        int actualImageCount = endIndex - startIndex;
        if (actualImageCount == 1) {
          needsSelection = false;
          singleImageIndex = startIndex;
        } else {
          needsSelection = true;
        }
      }
    } else if (imageViewController is _ContinuousModeState) {
      needsSelection = false;
      singleImageIndex = reader.page - 1;
    }

    if (!needsSelection && singleImageIndex != null) {
      return singleImageIndex;
    } else {
      var location = await _showSelectImageOverlay();
      if (location == null) {
        return null;
      }
      var imageKey = imageViewController!.getImageKeyByOffset(location);
      if (imageKey == null) {
        return null;
      }
      return reader.images!.indexOf(imageKey);
    }
  }

  /// Same as [selectImage], but return the image data with its index.
  /// Returns (imageIndex, imageData) or null if cancelled.
  Future<(int, Uint8List)?> selectImageToData() async {
    var i = await selectImage();
    if (i == null) {
      return null;
    }
    var imageKey = context.reader.images![i];
    // VENDOR-CUT: venera CacheManager replaced by flutter_cache_manager
    // (Tsumiru's existing dependency) for network image bytes.
    final Uint8List data;
    if (imageKey.startsWith("file://")) {
      data = await File(imageKey.substring(7)).readAsBytes();
    } else {
      data = await DefaultCacheManager()
          .getSingleFile(imageKey)
          .then((file) => file.readAsBytes());
    }
    return (i, data);
  }

  Future<Offset?> _showSelectImageOverlay() {
    if (_isOpen) {
      openOrClose();
    }

    var completer = Completer<Offset?>();

    var overlay = Overlay.of(context);
    OverlayEntry? entry;
    entry = OverlayEntry(
      builder: (context) {
        return Positioned.fill(
          child: _SelectImageOverlayContent(
            onTap: (offset) {
              completer.complete(offset);
              entry!.remove();
            },
            onDispose: () {
              if (!completer.isCompleted) {
                completer.complete(null);
              }
            },
          ),
        );
      },
    );
    overlay.insert(entry);

    return completer.future;
  }
}

/// M1 placeholder for the reader settings side bar (replaces venera's
/// ReaderSettings page). M4 will embed Tsumiru's settings panel here.
class _ReaderSettingsPlaceholder extends StatelessWidget {
  const _ReaderSettingsPlaceholder();

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reader Settings',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Not available yet — Tsumiru settings panel will be wired in M4.',
            style: TextStyle(
              fontSize: 15,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectImageOverlayContent extends StatefulWidget {
  const _SelectImageOverlayContent({
    required this.onTap,
    required this.onDispose,
  });

  final void Function(Offset) onTap;

  final void Function() onDispose;

  @override
  State<_SelectImageOverlayContent> createState() =>
      _SelectImageOverlayContentState();
}

class _SelectImageOverlayContentState
    extends State<_SelectImageOverlayContent> {
  @override
  void dispose() {
    widget.onDispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapUp: (details) {
        widget.onTap(details.globalPosition);
      },
      child: Container(
        // Scrim over page art: theme scrim token keeps it consistent across
        // light/dark without a hardcoded black.
        color: context.colorScheme.scrim.toOpacity(0.2),
        child: Align(
          alignment: Alignment(0, -0.8),
          child: Container(
            width: 232,
            height: 42,
            decoration: BoxDecoration(
              color: context.colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: context.colorScheme.outlineVariant),
            ),
            child: Row(
              children: [
                const SizedBox(width: 12),
                Icon(
                  FluentIcons.info_24_regular,
                  size: 20,
                  color: context.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Text(
                  "Click to select an image".tl,
                  style: TextStyle(
                    fontSize: 15,
                    color: context.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
