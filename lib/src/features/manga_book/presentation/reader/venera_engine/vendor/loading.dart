// Copyright (C) 2024-2026 venera-app contributors
// SPDX-License-Identifier: GPL-3.0-or-later
//
// Vendored from https://github.com/venera-app/venera (lib/pages/reader/)
// and modified for Tsumiru on 2026-11-20:
//  - VENDOR-CUT: ReaderWithLoading / _ReaderWithLoadingState removed — the
//    M1 debug entry constructs Reader directly with injected data, and the
//    original loadData() depends on venera ComicSource/HistoryManager/
//    LocalManager. ReaderProps is kept for M4 host wiring.

part of 'reader.dart';

class ReaderProps {
  final ComicType type;

  final String cid;

  final String name;

  final ComicChapters? chapters;

  final History history;

  final String author;

  final List<String> tags;

  const ReaderProps({
    required this.type,
    required this.cid,
    required this.name,
    required this.chapters,
    required this.history,
    required this.author,
    required this.tags,
  });
}
