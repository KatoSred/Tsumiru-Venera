// Copyright (c) 2026 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../../../constants/db_keys.dart';
import '../../../../../../constants/enum.dart';
import '../../../../../../utils/mixin/shared_preferences_client_mixin.dart';

part 'venera_engine_prefs.g.dart';

/// Which engine renders the reader; per-series overrides via MangaMetaKeys.
/// Enums must use [SharedPreferenceEnumClientMixin] (index-based storage) —
/// the plain mixin's `_set` has no enum branch and silently drops the write.
@riverpod
class ReaderEngineKey extends _$ReaderEngineKey
    with SharedPreferenceEnumClientMixin<ReaderEngine> {
  @override
  ReaderEngine? build() => initialize(
        DBKeys.readerEngine,
        enumList: ReaderEngine.values,
      );
}

/// Reading mode for the Venera engine (paged/continuous, direction).
@riverpod
class VeneraReaderModeSetting extends _$VeneraReaderModeSetting
    with SharedPreferenceEnumClientMixin<VeneraReaderMode> {
  @override
  VeneraReaderMode? build() => initialize(
        DBKeys.veneraReaderMode,
        enumList: VeneraReaderMode.values,
      );
}

/// Gallery-mode images shown per screen (1-5).
@riverpod
class VeneraImagesPerPage extends _$VeneraImagesPerPage
    with SharedPreferenceClientMixin<int> {
  @override
  int? build() => initialize(DBKeys.veneraImagesPerPage);
}

/// When >1 image per screen, show a single image on the first page.
@riverpod
class VeneraSingleFirstPage extends _$VeneraSingleFirstPage
    with SharedPreferenceClientMixin<bool> {
  @override
  bool? build() => initialize(DBKeys.veneraSingleFirstPage);
}

/// Long-press zooms the current page.
@riverpod
class VeneraLongPressZoom extends _$VeneraLongPressZoom
    with SharedPreferenceClientMixin<bool> {
  @override
  bool? build() => initialize(DBKeys.veneraLongPressZoom);
}

/// Page-turn animation duration in milliseconds.
@riverpod
class VeneraPageAnimationMs extends _$VeneraPageAnimationMs
    with SharedPreferenceClientMixin<int> {
  @override
  int? build() => initialize(DBKeys.veneraPageAnimationMs);
}

/// Hardware volume keys turn pages.
@riverpod
class VeneraPageTurnVolumeKey extends _$VeneraPageTurnVolumeKey
    with SharedPreferenceClientMixin<bool> {
  @override
  bool? build() => initialize(DBKeys.veneraPageTurnVolumeKey);
}

/// Continuous-mode wheel scroll multiplier.
@riverpod
class VeneraWheelSensitivity extends _$VeneraWheelSensitivity
    with SharedPreferenceClientMixin<double> {
  @override
  double? build() => initialize(DBKeys.veneraWheelSensitivity);
}

/// Tap edges turn pages.
@riverpod
class VeneraTapToTurnPages extends _$VeneraTapToTurnPages
    with SharedPreferenceClientMixin<bool> {
  @override
  bool? build() => initialize(DBKeys.veneraTapToTurnPages);
}

/// Swap left/right tap-to-turn zones.
@riverpod
class VeneraReverseTapToTurnPages extends _$VeneraReverseTapToTurnPages
    with SharedPreferenceClientMixin<bool> {
  @override
  bool? build() => initialize(DBKeys.veneraReverseTapToTurnPages);
}

/// Cap image width in continuous modes.
@riverpod
class VeneraLimitImageWidth extends _$VeneraLimitImageWidth
    with SharedPreferenceClientMixin<bool> {
  @override
  bool? build() => initialize(DBKeys.veneraLimitImageWidth);
}

/// Pages preloaded ahead of the viewport.
@riverpod
class VeneraPreloadImageCount extends _$VeneraPreloadImageCount
    with SharedPreferenceClientMixin<int> {
  @override
  int? build() => initialize(DBKeys.veneraPreloadImageCount);
}

/// Show page number overlay.
@riverpod
class VeneraShowPageNumber extends _$VeneraShowPageNumber
    with SharedPreferenceClientMixin<bool> {
  @override
  bool? build() => initialize(DBKeys.veneraShowPageNumber);
}

/// Page-turn animation toggle.
@riverpod
class VeneraEnablePageAnimation extends _$VeneraEnablePageAnimation
    with SharedPreferenceClientMixin<bool> {
  @override
  bool? build() => initialize(DBKeys.veneraEnablePageAnimation);
}

/// Auto page turning interval in seconds.
@riverpod
class VeneraAutoPageTurningInterval extends _$VeneraAutoPageTurningInterval
    with SharedPreferenceClientMixin<int> {
  @override
  int? build() => initialize(DBKeys.veneraAutoPageTurningInterval);
}

/// Show the system status bar over the reader.
@riverpod
class VeneraShowSystemStatusBar extends _$VeneraShowSystemStatusBar
    with SharedPreferenceClientMixin<bool> {
  @override
  bool? build() => initialize(DBKeys.veneraShowSystemStatusBar);
}

/// Double-tap toggles zoom.
@riverpod
class VeneraDoubleTapToZoom extends _$VeneraDoubleTapToZoom
    with SharedPreferenceClientMixin<bool> {
  @override
  bool? build() => initialize(DBKeys.veneraDoubleTapToZoom);
}
