// Copyright (C) 2024-2026 venera-app contributors
// SPDX-License-Identifier: GPL-3.0-or-later
//
// Compat shim for Tsumiru (created 2026-11-20).
// Minimal replacement for `venera/components/message.dart` showToast.
// M1: renders a plain SnackBar; M4 may rewire to Tsumiru's toast system.

import 'package:flutter/material.dart';

void showToast({
  required String message,
  required BuildContext context,
  int? seconds,
}) {
  ScaffoldMessenger.maybeOf(context)?.showSnackBar(
    SnackBar(
      content: Text(message),
      duration: Duration(seconds: seconds ?? 2),
    ),
  );
}
