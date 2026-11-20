// Copyright (C) 2024-2026 venera-app contributors
// SPDX-License-Identifier: GPL-3.0-or-later
//
// Compat shim for Tsumiru (created 2026-11-20).
// Glue over Tsumiru's existing `flutter_android_volume_keydown` git
// dependency, reproducing the `VolumeListener` shape the vendored reader
// expects (venera/utils/volume.dart).

import 'dart:async';

import 'package:flutter_android_volume_keydown/flutter_android_volume_keydown.dart'
    show FlutterAndroidVolumeKeydown, HardwareButton;

class VolumeListener {
  VolumeListener({required this.onDown, required this.onUp});

  final void Function() onDown;
  final void Function() onUp;

  StreamSubscription<HardwareButton>? _subscription;

  void listen() {
    _subscription ??=
        FlutterAndroidVolumeKeydown.stream.listen((HardwareButton button) {
      if (button == HardwareButton.volume_down) {
        onDown();
      } else if (button == HardwareButton.volume_up) {
        onUp();
      }
    });
  }

  void cancel() {
    _subscription?.cancel();
    _subscription = null;
  }
}
