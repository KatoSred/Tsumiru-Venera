// Copyright (C) 2024-2026 venera-app contributors
// SPDX-License-Identifier: GPL-3.0-or-later
//
// Compat shim for Tsumiru (created 2026-11-20).
// Minimal replacements for `venera/foundation/history.dart` (History) and
// `venera/foundation/local.dart` (ComicChapters/ComicChapter). Plain data
// shells: the vendored reader only reads/writes these fields. Persistence is
// delegated to Tsumiru in M3 via VeneraProgressSink.

/// Simple reading-history data shell.
class History {
  History({
    this.page = 1,
    this.maxPage = 1,
    this.ep = 1,
    this.group = 1,
    List<String>? readEpisode,
    DateTime? time,
    this.title = '',
    this.subtitle = '',
  })  : readEpisode = readEpisode ?? <String>[],
        time = time ?? DateTime.now();

  int page;
  int maxPage;
  int ep;
  int group;
  final List<String> readEpisode;
  DateTime time;
  String title;
  String subtitle;

  @override
  String toString() =>
      'History(page: $page, maxPage: $maxPage, ep: $ep, group: $group)';
}

/// A single chapter entry.
class ComicChapter {
  const ComicChapter({required this.id, required this.title});

  final String id;
  final String title;
}

/// Chapter collection used by the vendored reader.
/// Always carries a flat chapter list (for `ids`/`titles`/`length`); an
/// optional [grouped] map enables grouped mode (group name -> ordered
/// id -> title map), mirroring venera's structure.
class ComicChapters {
  ComicChapters({required List<ComicChapter> chapters, this.grouped})
      : _chapters = chapters;

  final List<ComicChapter> _chapters;

  /// group name -> (chapter id -> chapter title), insertion-ordered.
  final Map<String, Map<String, String>>? grouped;

  bool get isGrouped => grouped != null;

  Iterable<String> get ids => _chapters.map((c) => c.id);

  Iterable<String> get titles => _chapters.map((c) => c.title);

  int get length => _chapters.length;

  Map<String, Map<String, String>> get groups =>
      grouped ?? <String, Map<String, String>>{};

  Map<String, String> getGroup(String name) => grouped?[name] ?? const {};

  Map<String, String> getGroupByIndex(int index) {
    assert(isGrouped && index >= 0 && index < grouped!.values.length);
    return grouped!.values.elementAt(index);
  }
}
