// Copyright (c) 2026 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
// Compat shim for Tsumiru (created 2026-11-20).
// Minimal replacements for venera UI components used by the vendored reader:
// NetworkError / showSideBar / showMenuX / MenuEntry / BlurEffect /
// SmoothCustomScrollView / saveFile / detectFileType.
// M1: simplified implementations; M4/M5 may replace with branded widgets.

import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' show ImageFilter;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

/// Error box with retry action (replaces `venera/components/components.dart`
/// NetworkError).
class NetworkError extends StatelessWidget {
  const NetworkError({
    super.key,
    required this.message,
    this.retry,
  });

  final String message;

  final VoidCallback? retry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline,
              size: 48, color: Theme.of(context).colorScheme.error),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              message,
              textAlign: TextAlign.center,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (retry != null)
            TextButton.icon(
              onPressed: retry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
        ],
      ),
    );
  }
}

/// Replaces venera's right-side sidebar. M1 uses a modal bottom sheet; the
/// caller ignores the future value.
Future<void> showSideBar(
  BuildContext context,
  Widget widget, {
  double width = 400,
  bool dismissible = true,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    isDismissible: dismissible,
    enableDrag: dismissible,
    // ADAPTER: explicit barrier label — showModalBottomSheet would otherwise
    // read MaterialLocalizations.of(context).modalBarrierDismissLabel, which
    // is not reachable in the vendored reader subtree.
    barrierLabel: '关闭',
    builder: (sheetContext) {
      final maxHeight = MediaQuery.of(sheetContext).size.height * 0.8;
      return SizedBox(
        height: maxHeight,
        width: width,
        child: widget,
      );
    },
  );
}

class MenuEntry {
  const MenuEntry({
    this.icon,
    required this.text,
    required this.onClick,
  });

  final IconData? icon;
  final String text;
  final void Function()? onClick;
}

/// Replaces venera's popup menu. M1 maps entries to standard PopupMenuItems.
Future<void> showMenuX(
  BuildContext context,
  Offset location,
  List<MenuEntry> entries,
) async {
  final overlay =
      Overlay.of(context, rootOverlay: true).context.findRenderObject()
          as RenderBox;
  await showMenu<void>(
    context: context,
    position: RelativeRect.fromLTRB(
      location.dx,
      location.dy,
      overlay.size.width - location.dx,
      overlay.size.height - location.dy,
    ),
    items: [
      for (final entry in entries)
        PopupMenuItem<void>(
          onTap: entry.onClick,
          child: Row(
            children: [
              if (entry.icon != null) Icon(entry.icon, size: 20),
              const SizedBox(width: 12),
              Text(entry.text),
            ],
          ),
        ),
    ],
  );
}

/// Frosted-glass wrapper. Simplified implementation of venera's BlurEffect.
class BlurEffect extends StatelessWidget {
  const BlurEffect({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: child,
      ),
    );
  }
}

/// Drop-in replacement: plain CustomScrollView (no overscroll glow feature
/// from venera's SmoothScrollBehavior).
class SmoothCustomScrollView extends CustomScrollView {
  const SmoothCustomScrollView({
    super.key,
    super.controller,
    required super.slivers,
    super.scrollDirection,
    super.physics,
  });
}

/// Replaces venera's save dialog (file_selector/FlutterFileDialog). Uses
/// Tsumiru's existing file_picker dependency (v13 static API: the dialog
/// itself writes [bytes] and returns the saved Uri, or null when cancelled).
Future<void> saveFile({Uint8List? data, required String filename}) async {
  if (data == null) return;
  await FilePicker.saveFile(
    fileName: filename,
    bytes: data,
  );
}

class FileType {
  const FileType(this.ext, this.mime);

  final String ext;
  final String mime;
}

/// Minimal magic-byte sniffing (replaces venera/utils/file_type.dart for the
/// vendored reader's save/share paths).
FileType detectFileType(Uint8List data) {
  if (data.length >= 3 &&
      data[0] == 0xFF &&
      data[1] == 0xD8 &&
      data[2] == 0xFF) {
    return const FileType('.jpg', 'image/jpeg');
  }
  if (data.length >= 8 &&
      data[0] == 0x89 &&
      data[1] == 0x50 &&
      data[2] == 0x4E &&
      data[3] == 0x47) {
    return const FileType('.png', 'image/png');
  }
  if (data.length >= 6 &&
      data[0] == 0x47 &&
      data[1] == 0x49 &&
      data[2] == 0x46) {
    return const FileType('.gif', 'image/gif');
  }
  if (data.length >= 12 &&
      data[0] == 0x52 &&
      data[1] == 0x49 &&
      data[2] == 0x46 &&
      data[3] == 0x46 &&
      data[8] == 0x57 &&
      data[9] == 0x45 &&
      data[10] == 0x42 &&
      data[11] == 0x50) {
    return const FileType('.webp', 'image/webp');
  }
  return const FileType('.bin', 'application/octet-stream');
}
