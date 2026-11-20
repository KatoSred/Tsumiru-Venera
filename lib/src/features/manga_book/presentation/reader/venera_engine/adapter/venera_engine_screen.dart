// Copyright (c) 2026 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../../../../constants/db_keys.dart';
import '../../../../../../constants/enum.dart';
import '../../../../../../utils/extensions/custom_extensions.dart';
import '../../../../../../utils/misc/toast/toast.dart';
import '../../../../../../widgets/cover_cache/cover_cache.dart';
import '../../../../../../widgets/emoticons.dart';
import '../../../../../../widgets/server_image.dart';
import '../../../../../history/presentation/history_controller.dart';
import '../../../../../library/presentation/library/controller/library_controller.dart';
import '../../../../../library/presentation/library/controller/library_manga_list.dart';
import '../../../../../offline/data/offline_download_providers.dart';
import '../../../../../settings/presentation/general/widgets/force_portrait_tile.dart';
import '../../../../../settings/presentation/incognito/incognito_mode.dart';
import '../../../../../settings/presentation/reader/widgets/reader_general_prefs/reader_general_prefs.dart';
import '../../../../../settings/presentation/reader/widgets/reader_ignore_safe_area_tile/reader_ignore_safe_area_tile.dart';
import '../../../../../settings/presentation/reader/widgets/reader_keep_screen_on_tile/reader_keep_screen_on_tile.dart';
import '../../../../../settings/presentation/reader/widgets/reader_orientation/reader_orientation.dart';
import '../../../../../tracking/domain/track_progress_gate.dart';
import '../../../../domain/manga/manga_model.dart';
import '../../../manga_details/controller/manga_details_controller.dart';
import '../../controller/display_cutout.dart';
import '../../controller/reader_controller.dart';
import '../../controller/reader_settings_model.dart';
import '../../crop/cropped_image_provider.dart';
import '../../utils/flush_progress_on_lifecycle.dart';
import '../../widgets/chrome/reader_chrome.dart' show hiddenChromeUiMode;
import '../vendor/reader.dart';
import 'compat/appdata_shim.dart';
import 'compat/comic_type_shim.dart';
import 'compat/history_shim.dart';
import 'progress_bridge.dart';
import 'tsumiru_image_provider.dart';
import 'venera_settings_panel.dart';

/// Formal host screen for the vendored Venera engine (M4).
///
/// Mirrors [ReaderScreen]'s settings consumption (fullscreen, orientation,
/// wakelock, cutout) and progress pipeline, but renders the vendored reader
/// with host-injected data: chapter pages come from Tsumiru's
/// `chapterPagesProvider` (offline-first), page bytes flow through
/// [TsumiruImageProvider] with ServerImage-identical auth headers and cache
/// keys, and progress is persisted via [ReaderProgressBridge].
class VeneraEngineScreen extends HookConsumerWidget {
  const VeneraEngineScreen({
    super.key,
    required this.mangaId,
    required this.chapterId,
    this.readerScanlatorGroup,
    this.showReaderLayoutAnimation = false,
    this.openAtEnd = false,
  });

  final int mangaId;
  final int chapterId;
  final String? readerScanlatorGroup;

  /// Accepted for ReaderRoute parity; the vendored chrome has no layout
  /// animation to toggle yet.
  final bool showReaderLayoutAnimation;
  final bool openAtEnd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final providerContainer = ProviderScope.containerOf(context, listen: false);
    final settings = ref.watch(readerSettingsModelProvider(mangaId));

    // ADAPTER(M4): map Tsumiru's resolved settings into the vendored engine's
    // settings snapshot. Runs before the vendored Reader builds, so its
    // initState reads current values. Fixed keys follow the M4 mapping table;
    // `readerScrollSpeed` carries veneraWheelSensitivity so the wheel slider
    // reaches the vendored continuous-mode scroll handler.
    VeneraSettingsBridge.instance.snapshot = {
      'readerMode': settings.veneraReaderMode.key,
      'showSingleImageOnFirstPage': settings.veneraSingleFirstPage,
      'readerScreenPicNumberForPortrait':
          settings.veneraImagesPerPage.clamp(1, 5),
      'readerScreenPicNumberForLandscape':
          settings.veneraImagesPerPage.clamp(1, 5),
      'enablePageAnimation': settings.veneraEnablePageAnimation,
      'pageAnimationMs': settings.veneraPageAnimationMs.clamp(50, 500),
      'autoPageTurningInterval': settings.veneraAutoPageTurningInterval,
      'showSystemStatusBar': settings.veneraShowSystemStatusBar,
      'enableTurnPageByVolumeKey': settings.veneraPageTurnVolumeKey,
      'enableDoubleTapToZoom': settings.veneraDoubleTapToZoom,
      'enableLongPressToZoom': settings.veneraLongPressZoom,
      'longPressZoomPosition': 'center',
      'enableTapToTurnPages': settings.veneraTapToTurnPages,
      'reverseTapToTurnPages': settings.veneraReverseTapToTurnPages,
      'limitImageWidth': settings.veneraLimitImageWidth,
      'preloadImageCount': settings.veneraPreloadImageCount,
      'showPageNumberInReader': settings.veneraShowPageNumber,
      'readerScrollSpeed': settings.veneraWheelSensitivity,
    };

    final mangaAsync = ref.watch(mangaWithIdProvider(mangaId: mangaId));
    final chapterAsync = ref.watch(chapterProvider(chapterId: chapterId));
    final chapterPagesAsync = ref.watch(
      chapterPagesProvider(chapterId: chapterId),
    );
    final chapterListAsync = ref.watch(
      mangaChapterListProvider(mangaId: mangaId),
    );

    // --- Global reader chrome settings shared with ReaderScreen ---
    final ignoreSafeArea = ref.watch(readerIgnoreSafeAreaProvider).ifNull();
    useEffect(() {
      final fullscreen =
          ref.read(readerFullscreenProvider) ??
          DBKeys.readerFullscreen.initial as bool;
      SystemChrome.setEnabledSystemUIMode(
        hiddenChromeUiMode(fullscreen: fullscreen),
      );
      return null;
    }, []);

    final underCutout =
        ref.watch(drawUnderCutoutProvider) ??
        DBKeys.drawUnderCutout.initial as bool;
    useEffect(() {
      setDrawUnderCutout(underCutout);
      return () => setDrawUnderCutout(false);
    }, [underCutout]);

    final mangaData = mangaAsync.value;
    final readerOrientation = mangaData == null
        ? null
        : mangaData.metaData.readerOrientation ??
              ref.watch(readerOrientationKeyProvider) ??
              ReaderOrientation.defaultRotation;
    useEffect(() {
      final lock = readerOrientation?.deviceOrientations;
      if (lock == null) return null;
      SystemChrome.setPreferredOrientations(lock);
      final forcePortrait = ref.read(forcePortraitProvider).ifNull();
      return () => applyForcePortrait(forcePortrait);
    }, [readerOrientation]);

    final keepScreenOn = ref.watch(keepScreenOnProvider).ifNull(false);
    useEffect(() {
      if (!keepScreenOn) return null;
      WakelockPlus.enable().ignore();
      return () => WakelockPlus.disable().ignore();
    }, [keepScreenOn]);

    // --- Chapter data feeding the vendored engine ---
    final chapter = chapterAsync.value;
    final chapterPages = chapterPagesAsync.value;
    final chapterList = chapterListAsync.value;

    // Latest chapter id list; the loader/sink closures survive reader-internal
    // chapter switches, so they resolve ids dynamically.
    final chapterIdsRef = useRef<List<int>>(const []);
    chapterIdsRef.value = chapterList == null
        ? const <int>[]
        : [for (final c in chapterList) c.id];

    final comicChapters = chapterList == null
        ? null
        : ComicChapters(
            chapters: [
              for (final c in chapterList)
                ComicChapter(id: '${c.id}', title: c.name),
            ],
          );

    final initialChapterIndex = chapterIdsRef.value.indexOf(chapterId) + 1;
    final lastPageRead =
        (chapter?.user.lastPageRead).getValueOnNullOrNegative();
    // initialPage is a 1-based image index for the vendored engine.
    final initialPage = openAtEnd
        ? (chapterPages?.pages.length ?? lastPageRead + 1)
        : lastPageRead + 1;

    // Pending record future, awaited on pop so exit invalidations see the
    // flushed write.
    final pendingRecord = useRef<Future<void>?>(null);
    final controllerRef = useRef<VeneraReaderController?>(null);
    final toast = ref.watch(toastProvider);

    // ADAPTER(M4): apply live settings to the vendored reader state BEFORE
    // the subtree rebuilds — a reading-mode switch then mounts the new view
    // directly at the remapped page (a postFrame remap mounted it stale
    // first: page number and content diverged — user report).
    controllerRef.value?.syncLiveSettings();

    Future<void> recordProgress(
      int page, {
      required int maxPage,
      required int chapter,
      required bool isFinished,
    }) async {
      // Incognito suppresses progress/history writes (mirrors ReaderScreen).
      if (ref.read(incognitoModeProvider)) return;
      final ids = chapterIdsRef.value;
      if (chapter < 1 || chapter > ids.length) return;
      final targetChapterId = ids[chapter - 1];

      if (isFinished) {
        unawaited(
          maybeTrackProgressOnReadFetch(
            ref.read,
            mangaId: mangaId,
            isRead: true,
            manual: false,
          ).catchError((Object error) {
            debugPrint('$error');
          }),
        );
      }

      // Vendored history page is a 1-based image index; Tsumiru stores 0-based.
      final recordFuture = () async {
        final result = await recordReadingProgress(
          ref,
          mangaId: mangaId,
          chapterId: targetChapterId,
          lastPageRead: page - 1,
          isRead: isFinished,
        );
        if (result.hasError && context.mounted) {
          toast?.showError(context.l10n.errorSomethingWentWrong);
        }
        if (isFinished && context.mounted) {
          await noteChapterFinishedInReader(
            ref,
            mangaId: mangaId,
            chapterId: targetChapterId,
          );
        }
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => providerContainer.invalidate(readingHistoryProvider),
        );
      }();
      pendingRecord.value = recordFuture;
      await recordFuture;
    }

    Future<List<String>> loadChapterPages(int chapterIndex) async {
      final ids = chapterIdsRef.value;
      if (chapterIndex < 0 || chapterIndex >= ids.length) return const [];
      final pages = await ref.read(
        chapterPagesProvider(chapterId: ids[chapterIndex]).future,
      );
      return pages?.pages ?? const [];
    }

    final cropBorders = settings.cropBorders && !kIsWeb;
    final cacheManager = ref.read(serverPageCacheManagerProvider);

    ImageProvider buildPageImageProvider(String imageKey) {
      // Local pages need no headers; byte identity matches ServerImage.
      if (imageKey.startsWith('file://')) {
        final localPath = Uri.parse(imageKey).toFilePath();
        if (cropBorders) {
          return CroppedImageProvider(
            fetchUrl: imageKey,
            cacheKey: localPath,
            localPath: localPath,
          );
        }
        return TsumiruImageProvider(imageKey, cacheKey: localPath);
      }
      // Network branch: ServerImage's exact header/cache-key computation
      // (authType → basic/simpleLogin/uiLogin, custom headers, versioned key).
      final request = serverImageRequest(ref, imageKey);
      if (cropBorders) {
        return CroppedImageProvider(
          fetchUrl: request.fetchUrl,
          cacheKey: request.cacheKey,
          cacheManager: cacheManager,
          headers: request.headers,
        );
      }
      return TsumiruImageProvider(
        request.fetchUrl,
        headers: request.headers ?? const {},
        cacheKey: request.cacheKey,
        cacheManager: cacheManager,
      );
    }

    void openSettings() {
      // ADAPTER(M5): the Venera engine opens its own panel instead of
      // Tsumiru's showReaderSettingsSheet; both engines' panels stay
      // independent.
      unawaited(showVeneraSettingsPanel(context, ref));
    }

    // Desktop window close may skip pop/dispose; flush the vendored engine's
    // debounced progress on background and exit too.
    useFlushProgressOnAppLifecycle(() async {
      controllerRef.value?.flushPendingProgress();
      final pending = pendingRecord.value;
      if (pending != null) {
        await pending.timeout(const Duration(seconds: 3));
      }
    });

    return PopScope(
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) {
          SystemChrome.setEnabledSystemUIMode(
            SystemUiMode.manual,
            overlays: SystemUiOverlay.values,
          );
          // Flush the vendored engine's debounced progress BEFORE invalidating
          // lists, so they refetch the saved read state.
          try {
            controllerRef.value?.flushPendingProgress();
            final pending = pendingRecord.value;
            if (pending != null) await pending;
          } finally {
            unawaited(flushPendingReadDeletes(providerContainer));
            unawaited(reconcileMangaContainer(providerContainer, mangaId));
            WidgetsBinding.instance.addPostFrameCallback((_) {
              providerContainer.invalidate(
                chapterProvider(chapterId: chapterId),
              );
              providerContainer.invalidate(
                mangaChapterListProvider(mangaId: mangaId),
              );
              providerContainer.invalidate(libraryMangaListProvider);
              providerContainer.invalidate(categoryMangaListProvider);
            });
          }
        }
      },
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
        child: SafeArea(
          top: !ignoreSafeArea,
          bottom: !ignoreSafeArea,
          left: !ignoreSafeArea,
          right: !ignoreSafeArea,
          child: mangaAsync.showUiWhenData(
            context,
            (manga) {
              if (manga == null) return const SizedBox.shrink();
              return chapterAsync.showUiWhenData(
                context,
                (chapterValue) {
                  if (chapterValue == null) return const SizedBox.shrink();
                  return chapterPagesAsync.showUiWhenData(
                    context,
                    (pages) {
                      if (pages == null) return const SizedBox.shrink();
                      // Empty chapters never mount the reader.
                      if (pages.pages.isEmpty) {
                        return Scaffold(
                          appBar: AppBar(),
                          body: Emoticons(
                            title: context.l10n.readerNoPages,
                            subTitle: context.l10n.readerNoPagesSubtitle,
                          ),
                        );
                      }
                      return Reader(
                        type: const ComicType('tsumiru'),
                        // Per-series cid: vendored per-comic settings resolve
                        // against this identity.
                        cid: 'tsumiru-$mangaId',
                        name: manga.title,
                        chapters: comicChapters,
                        history: History(
                          page: initialPage,
                          ep: initialChapterIndex,
                        ),
                        initialPage: initialPage,
                        initialChapter: initialChapterIndex,
                        author: manga.author ?? '',
                        tags: [for (final g in manga.genre) g],
                        imageProviderFactory: buildPageImageProvider,
                        chapterPagesLoader: loadChapterPages,
                        progressSink: ReaderProgressBridge(
                          record: recordProgress,
                        ),
                        onControllerCreated: (controller) =>
                            controllerRef.value = controller,
                        onOpenSettings: openSettings,
                      );
                    },
                    refresh: () => ref.refresh(
                      chapterPagesProvider(chapterId: chapterId).future,
                    ),
                    addScaffoldWrapper:
                        chapterPagesAsync.hasError &&
                        !chapterPagesAsync.isLoading,
                  );
                },
                refresh: () =>
                    ref.refresh(chapterProvider(chapterId: chapterId).future),
                addScaffoldWrapper: true,
              );
            },
            refresh: () =>
                ref.refresh(mangaWithIdProvider(mangaId: mangaId).future),
            skipLoadingOnReload: true,
            addScaffoldWrapper: true,
          ),
        ),
      ),
    );
  }
}
