// Copyright (c) 2026 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
// Compat shim for Tsumiru (created 2026-11-20).
// Bridges vendored reader settings reads to a host-injected snapshot.
// M1: reads returned the built-in default table. M4: `VeneraEngineScreen`
// watches Tsumiru's ReaderSettingsState, maps it into
// `VeneraSettingsBridge.instance.snapshot` before the vendored reader
// mounts; reads resolve from that snapshot with defaults as fallback.

/// Reader setting keys used by the vendored reader code, with safe defaults.
/// Keys are collected from all `getReaderSetting(...)` / `appdata.settings[...]`
/// call sites inside `vendor/`. The bridge snapshot only overrides keys the
/// host maps; every key still resolves when missing from the snapshot.
const Map<String, Object> kVeneraReaderDefaultSettings = {
  'readerMode': 'galleryLeftToRight',
  'showSingleImageOnFirstPage': false,
  'readerScreenPicNumberForPortrait': 1,
  'readerScreenPicNumberForLandscape': 1,
  'enablePageAnimation': true,
  'autoPageTurningInterval': 5,
  'showSystemStatusBar': false,
  'enableTurnPageByVolumeKey': false,
  'enableDoubleTapToZoom': true,
  'enableLongPressToZoom': true,
  'longPressZoomPosition': 'center',
  'enableTapToTurnPages': true,
  'reverseTapToTurnPages': false,
  'limitImageWidth': true,
  'preloadImageCount': 4,
  'showPageNumberInReader': true,
  'readerScrollSpeed': 1.0,
  // ADAPTER(M4): page-turn animation duration (ms), mapped from
  // Tsumiru's veneraPageAnimationMs.
  'pageAnimationMs': 250,
};

/// ADAPTER(M4): host-injectable settings snapshot. `VeneraEngineScreen`
/// rebuilds [snapshot] from Tsumiru's ReaderSettingsState (per-series
/// resolution included) on every build, so vendored reads observe the
/// current settings without any riverpod dependency inside vendor/.
class VeneraSettingsBridge {
  VeneraSettingsBridge._();

  static final VeneraSettingsBridge instance = VeneraSettingsBridge._();

  /// Keys mapped from Tsumiru settings; missing keys fall back to
  /// [kVeneraReaderDefaultSettings].
  Map<String, Object> snapshot = const {};

  Object? peek(String key) => snapshot[key] ?? kVeneraReaderDefaultSettings[key];
}

/// Drop-in replacement for `appdata.settings.getReaderSetting(cid, sourceKey, key)`.
/// [cid] and [sourceKey] are accepted for signature compatibility; the host
/// resolves per-comic settings into the bridge snapshot (M4).
T getReaderSetting<T>(String cid, String sourceKey, String key) {
  final value = VeneraSettingsBridge.instance.peek(key);
  if (value == null) {
    throw ArgumentError('Unknown vendored reader setting key: $key');
  }
  if (value is! T) {
    throw ArgumentError(
      'Reader setting "$key" is ${value.runtimeType}, expected $T',
    );
  }
  return value as T;
}
