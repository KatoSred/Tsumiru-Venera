// Copyright (c) 2026 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.
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
