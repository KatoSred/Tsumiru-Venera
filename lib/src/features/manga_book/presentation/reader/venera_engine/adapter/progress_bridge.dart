// Copyright (c) 2026 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
// Progress bridge between the vendored Venera reader (GPL-3.0, see
// vendor/README.md) and Tsumiru's progress pipeline. The vendored reader
// reports page/chapter changes here; this file never touches Tsumiru's
// riverpod providers directly — the host screen (M4) wires the callbacks.

import 'package:flutter/foundation.dart';

/// Implemented by the host app (Tsumiru) and injected into the vendored
/// reader via `_ReaderState._progressSink`.
abstract interface class VeneraProgressSink {
  /// Called whenever the reader's page/chapter state changes and progress
  /// should be persisted.
  ///
  /// [page] is the 1-based reader page within the chapter (already mapped to
  /// an image index by the vendored reader's history math; may span multiple
  /// images when imagesPerPage > 1). [maxPage] is the chapter's image count.
  /// [chapter] is the 1-based vendored chapter index — resolve the Tsumiru
  /// chapter id with `chapters.ids[chapter - 1]`. [isFinished] is true when
  /// the reader is on the final page (Tsumiru marks the chapter read).
  Future<void> onPageChanged(
    int page, {
    required int maxPage,
    required int imageCount,
    required int chapter,
    required bool isFinished,
  });
}

/// Thin glue: turns the sink contract into plain callbacks that the host
/// screen supplies from its riverpod context (ReaderProgressQueue +
/// recordReadingProgress).
class ReaderProgressBridge implements VeneraProgressSink {
  ReaderProgressBridge({
    required this.record,
    this.debugLabel = 'venera-engine',
  });

  /// Persist progress for the chapter resolved by the caller.
  final Future<void> Function(
    int page, {
    required int maxPage,
    required int chapter,
    required bool isFinished,
  }) record;

  final String debugLabel;

  @override
  Future<void> onPageChanged(
    int page, {
    required int maxPage,
    required int imageCount,
    required int chapter,
    required bool isFinished,
  }) {
    debugPrint('[$debugLabel] progress: ch$chapter page $page/$maxPage '
        '${isFinished ? '(finished)' : ''}');
    return record(
      page,
      maxPage: maxPage,
      chapter: chapter,
      isFinished: isFinished,
    );
  }
}
