// Copyright (c) 2026 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
// Compat shim for Tsumiru (created 2026-11-20).
// Minimal replacement for `venera/components/message.dart` showToast.
// M1: renders a plain SnackBar; M4 may rewire to Tsumiru's toast system.

import 'package:material_ui/material_ui.dart';

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
