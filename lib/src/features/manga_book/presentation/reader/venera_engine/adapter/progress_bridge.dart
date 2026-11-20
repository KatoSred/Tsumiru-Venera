// Copyright (C) 2024-2026 venera-app contributors
// SPDX-License-Identifier: GPL-3.0-or-later
//
// Progress bridge contract for Tsumiru (created 2026-11-20).
// The vendored reader reports reading progress through this interface
// instead of venera's HistoryManager / SuwayomiProgressSync / DataSync.
// M1: definition skeleton only; the concrete Tsumiru-side implementation
// (persisting to Tsumiru's progress store) lands in M3.

/// Implemented by the host app (Tsumiru) and injected into the vendored
/// reader via `_ReaderState._progressSink`.
abstract interface class VeneraProgressSink {
  /// Called whenever the reader's page/chapter state changes.
  ///
  /// [page] is the 1-based reader page (may span multiple images),
  /// [maxPage] is the total page count for the current chapter,
  /// [imageCount] is the number of images in the current chapter.
  void onPageChanged(
    int page, {
    required int maxPage,
    required int imageCount,
  });
}
