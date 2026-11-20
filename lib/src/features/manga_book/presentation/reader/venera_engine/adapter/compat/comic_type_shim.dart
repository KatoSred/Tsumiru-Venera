// Copyright (C) 2024-2026 venera-app contributors
// SPDX-License-Identifier: GPL-3.0-or-later
//
// Compat shim for Tsumiru (created 2026-11-20).
// Minimal replacement for `venera/foundation/comic_type.dart`. The vendored
// reader only needs `sourceKey` identity plus the `local` sentinel.

class ComicType {
  const ComicType(this.sourceKey, [this.value = 0]);

  /// Stable identifier of the comic source (e.g. 'tsumiru', 'local').
  final String sourceKey;

  /// Legacy numeric id kept for signature compatibility with vendored code.
  final int value;

  static const ComicType local = ComicType('local', 0);

  @override
  bool operator ==(Object other) =>
      other is ComicType && other.sourceKey == sourceKey;

  @override
  int get hashCode => sourceKey.hashCode;

  @override
  String toString() => 'ComicType($sourceKey)';
}
