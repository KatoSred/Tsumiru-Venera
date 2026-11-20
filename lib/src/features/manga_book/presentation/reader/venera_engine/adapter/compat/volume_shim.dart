// Copyright (c) 2026 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.
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
