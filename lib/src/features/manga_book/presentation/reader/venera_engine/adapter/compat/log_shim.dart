// Copyright (C) 2024-2026 venera-app contributors
// SPDX-License-Identifier: GPL-3.0-or-later
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
