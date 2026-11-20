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
@riverpod
class ReaderEngineKey extends _$ReaderEngineKey
    with SharedPreferenceClientMixin<ReaderEngine> {
  @override
  ReaderEngine? build() => initialize(DBKeys.readerEngine);
}

/// Reading mode for the Venera engine (paged/continuous, direction).
@riverpod
class VeneraReaderModeSetting extends _$VeneraReaderModeSetting
    with SharedPreferenceClientMixin<VeneraReaderMode> {
  @override
  VeneraReaderMode? build() => initialize(DBKeys.veneraReaderMode);
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
