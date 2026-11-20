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

/// Gallery-mode images shown per screen (1-5).
@riverpod
class VeneraImagesPerPage extends _$VeneraImagesPerPage
    with SharedPreferenceClientMixin<int> {
  @override
  int? build() => initialize(DBKeys.veneraImagesPerPage);
}

/// Continuous vs gallery default for the Venera engine.
@riverpod
class VeneraContinuousDefault extends _$VeneraContinuousDefault
    with SharedPreferenceClientMixin<bool> {
  @override
  bool? build() => initialize(DBKeys.veneraContinuousDefault);
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
