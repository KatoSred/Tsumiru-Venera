// Copyright (c) 2026 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
// Compat shim for Tsumiru (created 2026-11-20).
// Minimal replacement for `venera/foundation/app.dart` used by the vendored
// reader. Only exposes the members the vendored code actually touches.

import 'dart:io' show Platform;

class App {
  App._();

  static bool get isAndroid => Platform.isAndroid;
  static bool get isIOS => Platform.isIOS;
  static bool get isWindows => Platform.isWindows;
  static bool get isLinux => Platform.isLinux;
  static bool get isMacOS => Platform.isMacOS;
  static bool get isMobile => isAndroid || isIOS;
  static bool get isDesktop => isWindows || isLinux || isMacOS;
}
