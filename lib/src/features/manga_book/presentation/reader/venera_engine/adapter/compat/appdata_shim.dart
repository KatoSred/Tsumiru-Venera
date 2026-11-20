// Copyright (C) 2024-2026 venera-app contributors
// SPDX-License-Identifier: GPL-3.0-or-later
//
// Compat shim for Tsumiru (created 2026-11-20).
// Bridges vendored reader settings reads to a static default table.
// M1: reads return built-in defaults; M4 will rewire to Tsumiru's
// settings system (per-comic overrides included).

/// Reader setting keys used by the vendored reader code, with M1 defaults.
/// Keys are collected from all `getReaderSetting(...)` / `appdata.settings[...]`
/// call sites inside `vendor/`.
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
};

/// Drop-in replacement for `appdata.settings.getReaderSetting(cid, sourceKey, key)`.
/// [cid] and [sourceKey] are accepted for signature compatibility; M4 will use
/// them to resolve per-comic settings from Tsumiru's store.
T getReaderSetting<T>(String cid, String sourceKey, String key) {
  final value = kVeneraReaderDefaultSettings[key];
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
