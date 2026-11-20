// Copyright (C) 2024-2026 venera-app contributors
// SPDX-License-Identifier: GPL-3.0-or-later
//
// Vendored from https://github.com/venera-app/venera (lib/pages/reader/)
// and modified for Tsumiru on 2026-11-20:
//  - Rewrote import section: removed all `package:venera/*`,
//    flutter_memory_info, window_frame, battery_plus,
//    flutter_staggered_grid_view imports; added compat shims
//    (`../adapter/compat/*`), `../adapter/tsumiru_image_provider.dart`,
//    `../adapter/progress_bridge.dart`, `dart:io`, flutter_cache_manager,
//    share_plus.
//  - Removed `part 'chapter_comments.dart'` and all chapter-comment logic
//    (VENDOR-CUT): _shouldShowChapterCommentsAtEnd, isOnChapterCommentsPage,
//    totalPages simplified to maxPage, comments-page branches in
//    _ImagePerPageHandler removed.
//  - All settings reads bridged to compat `getReaderSetting(cid, sourceKey,
//    key)` (appdata shim).
//  - Removed setImageCacheSize() (flutter_memory_info), imageCache reset in
//    dispose, SuwayomiProgressSync flush, DataSync().onDataChanged(),
//    LocalFavoritesManager().onRead block (VENDOR-CUT).
//  - _ReaderWindow mixin simplified: WindowFrame dependency removed, only
//    window_manager.setFullScreen kept (VENDOR-CUT).
//  - updateHistory(): HistoryManager/Suwayomi/DataSync writes replaced by
//    VeneraProgressSink bridge (_progressSink); page/ep/group calculations
//    kept for M3.
//  - History/ComicType/ComicChapters types come from compat shims (plain
//    data shells).
//  - _VolumeListener now uses Tsumiru's flutter_android_volume_keydown via
//    volume shim.
//  - Added optional debugImages constructor param + injectImages()
//    controller entry (M1 debug heritage; M4 formalized both).
//  - ADAPTER(M4): added public VeneraReaderController interface; _ReaderState
//    implements it and is handed to the host via `onControllerCreated`.
//    `Reader` also gained `onExit` (host PopScope coordination) and
//    `onOpenSettings` (opens Tsumiru's settings sheet from the vendor
//    scaffold) — callbacks only, no riverpod/hooks inside vendor/.

library;

import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:share_plus/share_plus.dart';
import 'package:window_manager/window_manager.dart';

// Compat shims bridging vendored code to Tsumiru's environment.
import '../adapter/compat/app_shim.dart';
import '../adapter/compat/appdata_shim.dart';
import '../adapter/compat/comic_type_shim.dart';
import '../adapter/compat/components_shim.dart';
import '../adapter/compat/ext_shim.dart';
import '../adapter/compat/history_shim.dart';
import '../adapter/compat/volume_shim.dart';
import '../adapter/progress_bridge.dart';
import '../adapter/tsumiru_image_provider.dart';

part 'scaffold.dart';

part 'images.dart';

part 'gesture.dart';

part 'comic_image.dart';

part 'loading.dart';

part 'custom_slider.dart';

part 'chapters.dart';

// VENDOR-CUT: part 'chapter_comments.dart' removed — chapter comments depend
// on venera ComicSource; comments are out of M1 scope.

extension _ReaderContext on BuildContext {
  _ReaderState get reader => findAncestorStateOfType<_ReaderState>()!;

  _ReaderScaffoldState get readerScaffold =>
      findAncestorStateOfType<_ReaderScaffoldState>()!;
}

class Reader extends StatefulWidget {
  const Reader({
    super.key,
    required this.type,
    required this.cid,
    required this.name,
    required this.chapters,
    required this.history,
    this.initialPage,
    this.initialChapter,
    this.initialChapterGroup,
    required this.author,
    required this.tags,
    // M1 debug entry heritage: images injected directly; the formal path
    // feeds chapter data via `chapterPagesLoader` (adapter).
    this.debugImages,
    // ADAPTER(M4): host hooks — controller handle, exit coordination and
    // Tsumiru settings-sheet entry. All optional; vendor stays host-agnostic.
    this.onControllerCreated,
    this.onExit,
    this.onOpenSettings,
    // ADAPTER(M4): data/adapters injected once in initState (state fields are
    // library-private, so the host configures them through the widget).
    this.imageProviderFactory,
    this.chapterPagesLoader,
    this.progressSink,
  });

  final ComicType type;

  final String author;

  final List<String> tags;

  final String cid;

  final String name;

  final ComicChapters? chapters;

  /// Starts from 1, invalid values equal to 1
  final int? initialPage;

  /// Starts from 1, invalid values equal to 1
  final int? initialChapter;

  /// Starts from 1, invalid values equal to 1
  final int? initialChapterGroup;

  final History history;

  /// Image list injected by the M1 debug entry (host-supplied).
  final List<String>? debugImages;

  /// ADAPTER(M4): called once in initState with the public controller handle.
  final ValueChanged<VeneraReaderController>? onControllerCreated;

  /// ADAPTER(M4): host exit hook; reserved for PopScope coordination.
  final VoidCallback? onExit;

  /// ADAPTER(M4): opens the host settings panel from the vendor scaffold's
  /// settings entry (replaces the M1 placeholder sidebar).
  final VoidCallback? onOpenSettings;

  /// ADAPTER(M4): per-page image provider factory (host-injected).
  final ImageProvider Function(String imageKey)? imageProviderFactory;

  /// ADAPTER(M4): image URL list loader (0-based chapter index).
  final Future<List<String>> Function(int chapterIndex)? chapterPagesLoader;

  /// ADAPTER(M4): progress bridge to Tsumiru's persistence layer.
  final VeneraProgressSink? progressSink;

  @override
  State<Reader> createState() => _ReaderState();
}

/// ADAPTER(M4): public handle for the host to drive the vendored reader state.
/// Implemented by the library-private `_ReaderState`; deliberately narrow so
/// future host entries (M5) extend this interface instead of exposing the
/// State.
abstract interface class VeneraReaderController {
  /// Emits any debounced pending progress immediately (exit, lifecycle).
  void flushPendingProgress();

  /// Replaces the current image list (debug/adapter entry).
  void injectImages(List<String> pages);

  /// ADAPTER(M4): rebuilds the reader chrome so host-side setting changes
  /// (settings panel toggles) apply without leaving the reader.
  void updateChrome();
}

class _ReaderState extends State<Reader>
    with
        _ReaderLocation,
        _ReaderWindow,
        _VolumeListener,
        _ImagePerPageHandler
    implements VeneraReaderController {
  @override
  void update() {
    setState(() {});
  }

  /// The maximum page number (chapter comments page no longer exists).
  /// This is used for display purposes and history recording.
  @override
  int get maxPage {
    if (images == null) return 1;
    return !showSingleImageOnFirstPage()
        ? (images!.length / imagesPerPage).ceil()
        : 1 + ((images!.length - 1) / imagesPerPage).ceil();
  }

  @override
  int get totalPages => maxPage;

  @override
  ComicType get type => widget.type;

  @override
  String get cid => widget.cid;

  String get eid => widget.chapters?.ids.elementAtOrNull(chapter - 1) ?? '0';

  @override
  List<String>? images;

  /// Adapter hook: builds the per-page image provider (host-injected so the
  /// vendored engine uses Tsumiru auth headers, shared cache keys and crop).
  ImageProvider Function(String imageKey)? imageProviderFactory;

  /// Adapter hook: loads the image URL list for a chapter (0-based index).
  /// Enables Venera-native chapter switching; null = static [debugImages].
  Future<List<String>> Function(int chapterIndex)? chapterPagesLoader;

  /// Progress emits are gated until the first chapter finishes loading, so
  /// restoring a position (especially openAtEnd) never records progress.
  bool _progressActive = false;

  /// ADAPTER(M4): injects images through the public controller surface
  /// (`injectImages`); replaces the old setImagesForDebug entry.
  @override
  void injectImages(List<String> value) {
    setState(() {
      images = value;
      isLoading = true;
    });
  }

  /// M3: progress bridge to Tsumiru's persistence layer.
  VeneraProgressSink? _progressSink;

  @override
  late ReaderMode mode;

  @override
  bool get isPortrait =>
      MediaQuery.of(context).orientation == Orientation.portrait;

  History? history;

  @override
  bool isLoading = false;

  var focusNode = FocusNode();

  @override
  void initState() {
    page = widget.initialPage ?? 1;
    if (page < 1) {
      page = 1;
    }
    chapter = widget.initialChapter ?? 1;
    if (chapter < 1) {
      chapter = 1;
    }
    if (widget.initialChapterGroup != null) {
      for (int i = 0; i < (widget.initialChapterGroup! - 1); i++) {
        chapter += widget.chapters!.getGroupByIndex(i).length;
      }
    }
    if (widget.initialPage != null) {
      page = widget.initialPage!;
      if (page < 1) {
        page = 1;
      }
    }
    mode = ReaderMode.fromKey(
      getReaderSetting(cid, type.sourceKey, 'readerMode'),
    );
    history = widget.history;
    images = widget.debugImages;
    // ADAPTER(M4): copy host-injected adapters from the widget onto the
    // state (the fields are library-private; widget params are the public
    // injection surface).
    imageProviderFactory = widget.imageProviderFactory;
    chapterPagesLoader = widget.chapterPagesLoader;
    _progressSink = widget.progressSink;
    // ADAPTER(M4): hand the host its controller handle once, before the
    // first chapter load so exit/lifecycle flushes are registered in time.
    widget.onControllerCreated?.call(this);
    if (!getReaderSetting(
      cid,
      type.sourceKey,
      'showSystemStatusBar',
    )) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    }
    if (getReaderSetting(
      cid,
      type.sourceKey,
      'enableTurnPageByVolumeKey',
    )) {
      handleVolumeEvent();
    }
    // VENDOR-CUT: setImageCacheSize() removed — depends on flutter_memory_info;
    // M2 will bridge to Tsumiru's image cache policy.
    // VENDOR-CUT: LocalFavoritesManager().onRead(...) block removed — local
    // favorites are out of M1 scope.
    super.initState();
  }

  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      initImagesPerPage(widget.initialPage ?? 1);
      _isInitialized = true;
    } else {
      // For orientation changed
      _checkImagesPerPageChange();
    }
    initReaderWindow();
  }

  @override
  void dispose() {
    if (isFullscreen) {
      fullscreen();
    }
    autoPageTurningTimer?.cancel();
    focusNode.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    stopVolumeEvent();
    flushPendingProgress();
    // VENDOR-CUT: SuwayomiProgressSync.instance.flush(),
    // DataSync().onDataChanged() and imageCache.maximumSizeBytes reset
    // removed — replaced by the _progressSink bridge (M3).
    disposeReaderWindow();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _checkImagesPerPageChange();
    return KeyboardListener(
      focusNode: focusNode,
      autofocus: true,
      onKeyEvent: onKeyEvent,
      child: Overlay(
        initialEntries: [
          OverlayEntry(
            builder: (context) {
              // ADAPTER(M4): keyed so the host controller can reach the
              // scaffold's update() when host settings change.
              return _ReaderScaffold(
                key: _scaffoldKey,
                child: _ReaderGestureDetector(
                  child: _ReaderImages(key: Key(chapter.toString())),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void onKeyEvent(KeyEvent event) {
    if (event.logicalKey == LogicalKeyboardKey.f12 && event is KeyUpEvent) {
      fullscreen();
    }
    _imageViewController?.handleKeyEvent(event);
  }

  @override
  int get maxChapter => widget.chapters?.length ?? 1;

  @override
  void onPageChanged() {
    updateHistory();
  }

  /// Prevent multiple progress updates in a short time.
  Timer? _updateHistoryTimer;

  void updateHistory() {
    if (history == null) return;
    // VENDOR-CUT: HistoryManager().addHistoryAsync / SuwayomiProgressSync
    // / DataSync writes removed. Page math is kept; progress is forwarded
    // to the Tsumiru bridge instead (M3).
    _updateHistoryState();
    if (!_progressActive) return;
    final isFinished = page >= maxPage;
    if (isFinished) {
      // Last page: record immediately, never debounced (Tsumiru semantics —
      // an entire chapter must not linger unread if the app exits right now).
      _updateHistoryTimer?.cancel();
      _updateHistoryTimer = null;
      _emitProgress();
    } else {
      _updateHistoryTimer?.cancel();
      _updateHistoryTimer = Timer(const Duration(seconds: 1), () {
        _updateHistoryTimer = null;
        _emitProgress();
      });
    }
  }

  /// Updates the [history] state (page math / episode tracking) WITHOUT
  /// emitting progress — used for position restores (initial page,
  /// openAtEnd, chapter reloads) so glancing at a page never records it.
  void syncHistoryState() {
    if (history != null) {
      _updateHistoryState();
    }
  }

  void _updateHistoryState() {
    if (page >= maxPage) {
      /// Record the last image of chapter
      history!.page = images?.length ?? 1;
    } else {
      /// Record the first image of the page
      if (!showSingleImageOnFirstPage() || imagesPerPage == 1) {
        history!.page = (page - 1) * imagesPerPage + 1;
      } else {
        if (page == 1) {
          history!.page = 1;
        } else {
          history!.page = (page - 2) * imagesPerPage + 2;
        }
      }
    }
    history!.maxPage = images?.length ?? 1;
    if (widget.chapters?.isGrouped ?? false) {
      int g = 0;
      int c = chapter;
      while (c > widget.chapters!.getGroupByIndex(g).length) {
        c -= widget.chapters!.getGroupByIndex(g).length;
        g++;
      }
      history!.readEpisode.add('${g + 1}-$c');
      history!.ep = c;
      history!.group = g + 1;
    } else {
      history!.readEpisode.add(chapter.toString());
      history!.ep = chapter;
    }
    history!.time = DateTime.now();
  }

  void _emitProgress() {
    _progressSink?.onPageChanged(
      history!.page,
      maxPage: history!.maxPage,
      imageCount: images?.length ?? 1,
      chapter: chapter,
      isFinished: page >= maxPage,
    );
  }

  /// Flush any pending debounced progress immediately (chapter switch, pop,
  /// app lifecycle). Safe to call when nothing is pending.
  @override
  void flushPendingProgress() {
    if (_updateHistoryTimer != null) {
      _updateHistoryTimer!.cancel();
      _updateHistoryTimer = null;
      _emitProgress();
    }
  }

  /// ADAPTER(M4): scaffold key for the host controller's updateChrome().
  final GlobalKey<_ReaderScaffoldState> _scaffoldKey =
      GlobalKey<_ReaderScaffoldState>();

  @override
  void updateChrome() {
    // ADAPTER: re-read the live reading mode so panel changes apply in
    // place (imagesPerPage is handled by _checkImagesPerPageChange in
    // build; the gallery widget is keyed by mode + per-page count).
    final newMode = ReaderMode.fromKey(
      getReaderSetting(cid, type.sourceKey, 'readerMode'),
    );
    if (newMode != mode) {
      mode = newMode;
      initImagesPerPage(page);
    }
    _scaffoldKey.currentState?.update();
    setState(() {});
  }

  bool get isFirstChapterOfGroup {
    if (widget.chapters?.isGrouped ?? false) {
      int c = chapter - 1;
      int g = 1;
      while (c > 0) {
        c -= widget.chapters!.getGroupByIndex(g - 1).length;
        g++;
      }
      if (c == 0) {
        return true;
      } else {
        return false;
      }
    }
    return chapter == 1;
  }

  bool get isLastChapterOfGroup {
    if (widget.chapters?.isGrouped ?? false) {
      int c = chapter;
      int g = 1;
      while (c > 0) {
        c -= widget.chapters!.getGroupByIndex(g - 1).length;
        g++;
      }
      if (c == 0) {
        return true;
      } else {
        return false;
      }
    }
    return chapter == maxChapter;
  }

  /// Get the size of the reader.
  /// The size is not always the same as the size of the screen.
  Size get size {
    var renderBox = context.findRenderObject() as RenderBox;
    return renderBox.size;
  }
}

abstract mixin class _ImagePerPageHandler {
  late int _lastImagesPerPage;

  late bool _lastOrientation;

  bool get isPortrait;

  int get page;

  set page(int value);

  ReaderMode get mode;

  String get cid;

  ComicType get type;

  /// Get the max page
  int get maxPage;

  /// Get images list for calculating maxPage
  List<String>? get images;

  void initImagesPerPage(int initialPage) {
    _lastImagesPerPage = imagesPerPage;
    _lastOrientation = isPortrait;
    if (imagesPerPage != 1) {
      if (showSingleImageOnFirstPage()) {
        page = ((initialPage - 1) / imagesPerPage).ceil() + 1;
      } else {
        page = (initialPage / imagesPerPage).ceil();
      }
    }
  }

  bool showSingleImageOnFirstPage() => getReaderSetting(
    cid,
    type.sourceKey,
    'showSingleImageOnFirstPage',
  );

  /// The number of images displayed on one screen
  int get imagesPerPage {
    if (mode.isContinuous) return 1;
    if (isPortrait) {
      return getReaderSetting(
        cid,
        type.sourceKey,
        'readerScreenPicNumberForPortrait',
      );
    } else {
      return getReaderSetting(
        cid,
        type.sourceKey,
        'readerScreenPicNumberForLandscape',
      );
    }
  }

  /// Check if the number of images per page has changed
  void _checkImagesPerPageChange() {
    int currentImagesPerPage = imagesPerPage;
    bool currentOrientation = isPortrait;

    if (_lastImagesPerPage != currentImagesPerPage ||
        _lastOrientation != currentOrientation) {
      _adjustPageForImagesPerPageChange(
        _lastImagesPerPage,
        currentImagesPerPage,
      );
      _lastImagesPerPage = currentImagesPerPage;
      _lastOrientation = currentOrientation;
    }
  }

  /// Adjust the page number when the number of images per page changes
  void _adjustPageForImagesPerPageChange(
    int oldImagesPerPage,
    int newImagesPerPage,
  ) {
    int previousImageIndex = 1;
    if (!showSingleImageOnFirstPage() || oldImagesPerPage == 1) {
      previousImageIndex = (page - 1) * oldImagesPerPage + 1;
    } else {
      if (page == 1) {
        previousImageIndex = 1;
      } else {
        previousImageIndex = (page - 2) * oldImagesPerPage + 2;
      }
    }

    int newPage;
    if (newImagesPerPage != 1) {
      if (showSingleImageOnFirstPage()) {
        newPage = ((previousImageIndex - 1) / newImagesPerPage).ceil() + 1;
      } else {
        newPage = (previousImageIndex / newImagesPerPage).ceil();
      }
    } else {
      newPage = previousImageIndex;
    }

    // Clamp to valid range (1 to maxPage)
    page = newPage.clamp(1, maxPage);
  }
}

abstract mixin class _VolumeListener {
  bool toNextPage();

  bool toPrevPage();

  bool toNextChapter();

  bool toPrevChapter({bool toLastPage = false});

  VolumeListener? volumeListener;

  void onDown() {
    if (!toNextPage()) {
      toNextChapter();
    }
  }

  void onUp() {
    if (!toPrevPage()) {
      toPrevChapter(toLastPage: true);
    }
  }

  void handleVolumeEvent() {
    if (!App.isAndroid) {
      // Currently only support Android
      return;
    }
    if (volumeListener != null) {
      volumeListener?.cancel();
    }
    volumeListener = VolumeListener(onDown: onDown, onUp: onUp)..listen();
  }

  void stopVolumeEvent() {
    if (volumeListener != null) {
      volumeListener?.cancel();
      volumeListener = null;
    }
  }
}

abstract mixin class _ReaderLocation {
  int _page = 1;
  int? _pendingPage;

  /// Flag to indicate that the page should jump to the last page after images are loaded.
  bool _jumpToLastPageOnLoad = false;

  int get page => _page;

  set page(int value) {
    _page = value;
    onPageChanged();
  }

  int chapter = 1;

  int get maxPage;

  int get totalPages;

  int get maxChapter;

  bool get isLoading;

  String get cid;

  ComicType get type;

  void update();

  bool enablePageAnimation(String cid, ComicType type) => getReaderSetting(
        cid,
        type.sourceKey,
        'enablePageAnimation',
      );

  _ImageViewController? _imageViewController;

  void onPageChanged();

  void setPage(int page) {
    // Prevent page change during animation
    if (_animationCount > 0 && _pendingPage != null && page != _pendingPage) {
      return;
    }
    this.page = page;
  }

  bool _validatePage(int page) {
    return page >= 1 && page <= totalPages;
  }

  /// Returns true if the page is changed
  bool toNextPage() {
    return toPage(page + 1);
  }

  /// Returns true if the page is changed
  bool toPrevPage() {
    return toPage(page - 1);
  }

  int _animationCount = 0;

  bool toPage(int page) {
    if (_validatePage(page)) {
      if (page == this.page && page != 1 && page != totalPages) {
        return false;
      }
      final hasAnimation = enablePageAnimation(cid, type);
      if (hasAnimation) {
        _pendingPage = page;
        _animationCount++;
        update();
        _imageViewController!.animateToPage(page).then((_) {
          _animationCount--;
          if (_pendingPage == page) {
            _pendingPage = null;
          }
          update();
        });
      } else {
        this.page = page;
        update();
        _imageViewController!.toPage(page);
      }
      return true;
    }
    return false;
  }

  bool get isPageAnimating => _animationCount > 0;

  bool _validateChapter(int chapter) {
    return chapter >= 1 && chapter <= maxChapter;
  }

  /// Returns true if the chapter is changed
  bool toNextChapter() {
    return toChapter(chapter + 1);
  }

  /// Returns true if the chapter is changed
  /// If [toLastPage] is true, the page will be set to the last page of the previous chapter.
  bool toPrevChapter({bool toLastPage = false}) {
    return toChapter(chapter - 1, toLastPage: toLastPage);
  }

  bool toChapter(int c, {bool toLastPage = false}) {
    if (_validateChapter(c) && !isLoading) {
      // Emit the old chapter's pending progress before switching, so it is
      // recorded against the correct chapter (the sink carries the chapter).
      flushPendingProgress();
      chapter = c;
      page = 1;
      _jumpToLastPageOnLoad = toLastPage;
      update();
      return true;
    }
    return false;
  }

  Timer? autoPageTurningTimer;

  /// Implemented by [_ReaderState]: emits pending progress immediately.
  void flushPendingProgress();

  void autoPageTurning(String cid, ComicType type) {
    if (autoPageTurningTimer != null) {
      autoPageTurningTimer!.cancel();
      autoPageTurningTimer = null;
    } else {
      int interval = getReaderSetting(
        cid,
        type.sourceKey,
        'autoPageTurningInterval',
      );
      autoPageTurningTimer = Timer.periodic(Duration(seconds: interval), (_) {
        if (page == maxPage) {
          autoPageTurningTimer!.cancel();
        }
        toNextPage();
      });
    }
  }
}

mixin class _ReaderWindow {
  bool isFullscreen = false;

  bool _isInit = false;

  // VENDOR-CUT: WindowFrame integration removed (windowFrame field,
  // addCloseListener, onWindowClose). Kept as a no-op so the
  // didChangeDependencies call site stays untouched.
  void initReaderWindow() {
    if (!App.isDesktop || _isInit) return;
    _isInit = true;
  }

  void fullscreen() async {
    if (!App.isDesktop) return;
    // VENDOR-CUT: WindowFrame hide/show wrap removed; plain window_manager
    // fullscreen toggle.
    await windowManager.setFullScreen(!isFullscreen);
    isFullscreen = !isFullscreen;
  }

  // VENDOR-CUT: disposeReaderWindow / onWindowClose removed along with the
  // WindowFrame dependency.
  void disposeReaderWindow() {
    _isInit = false;
  }
}

enum ReaderMode {
  galleryLeftToRight('galleryLeftToRight'),
  galleryRightToLeft('galleryRightToLeft'),
  galleryTopToBottom('galleryTopToBottom'),
  continuousTopToBottom('continuousTopToBottom'),
  continuousLeftToRight('continuousLeftToRight'),
  continuousRightToLeft('continuousRightToLeft');

  final String key;

  bool get isGallery => key.startsWith('gallery');

  bool get isContinuous => key.startsWith('continuous');

  const ReaderMode(this.key);

  static ReaderMode fromKey(String key) {
    for (var mode in values) {
      if (mode.key == key) {
        return mode;
      }
    }
    return galleryLeftToRight;
  }
}

abstract interface class _ImageViewController {
  void toPage(int page);

  Future<void> animateToPage(int page);

  void handleDoubleTap(Offset location);

  void handleLongPressDown(Offset location);

  void handleLongPressUp(Offset location);

  void handleKeyEvent(KeyEvent event);

  /// Returns true if the event is handled.
  bool handleOnTap(Offset location);

  Future<Uint8List?> getImageByOffset(Offset offset);

  String? getImageKeyByOffset(Offset offset);
}
