// Copyright (c) 2026 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
// Compat shim for Tsumiru (created 2026-11-20).
// Minimal replacement for `venera/foundation/log.dart`.

import 'package:flutter/foundation.dart';

class Log {
  Log._();

  static void info(String tag, String message) {
    debugPrint('[INFO] [$tag] $message');
  }

  static void warning(String tag, String message, [StackTrace? stackTrace]) {
    debugPrint('[WARN] [$tag] $message');
    if (stackTrace != null) debugPrint('$stackTrace');
  }

  static void error(String tag, Object error, [StackTrace? stackTrace]) {
    debugPrint('[ERROR] [$tag] $error');
    if (stackTrace != null) debugPrint('$stackTrace');
  }
}
