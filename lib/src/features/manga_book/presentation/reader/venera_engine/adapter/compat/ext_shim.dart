// Copyright (c) 2026 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
// Compat shim for Tsumiru (created 2026-11-20).
// Extensions from venera/utils/ext.dart + utils/translations.dart used by
// the vendored reader. M1: `.tl` returns the source string (English text);
// M4 may add a translation table.

import 'package:flutter/material.dart';

/// Translation extension (venera `.tl`). M1: identity mapping.
extension VeneraTranslationExt on String {
  String get tl => this;
}

/// Text style helpers mirroring venera's `ts` object.
class _Ts {
  const _Ts();

  TextStyle get s12 => const TextStyle(fontSize: 12);
  TextStyle get s16 => const TextStyle(fontSize: 16);
  TextStyle get s18 => const TextStyle(fontSize: 18);
  TextStyle get bold => const TextStyle(fontWeight: FontWeight.bold);
  TextStyle withColor(Color color) => TextStyle(color: color);
}

const ts = _Ts();

extension VeneraTextStyleExt on TextStyle {
  TextStyle get s12 => copyWith(fontSize: 12);
  TextStyle get s16 => copyWith(fontSize: 16);
  TextStyle get s18 => copyWith(fontSize: 18);
  TextStyle get bold => copyWith(fontWeight: FontWeight.bold);
}

extension VeneraColorExt on Color {
  /// Mirror of venera's `Color.toOpacity(x)` -> alpha applied.
  Color toOpacity(double opacity) => withValues(alpha: opacity);
}

extension VeneraContextExt on BuildContext {
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  EdgeInsets get padding => MediaQuery.of(this).padding;

  double get width => MediaQuery.of(this).size.width;

  double get height => MediaQuery.of(this).size.height;

  /// Pop the enclosing route (used by reader side bars / exit menu entry).
  void pop() => Navigator.of(this).maybePop();

  /// Mirror of venera's context.showMessage -> toast shim.
  void showMessage({required String message}) {
    ScaffoldMessenger.maybeOf(this)?.showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

extension VeneraWidgetPaddingExt on Widget {
  Widget paddingLeft(double value) => Padding(
        padding: EdgeInsets.only(left: value),
        child: this,
      );

  Widget paddingHorizontal(double value) => Padding(
        padding: EdgeInsets.symmetric(horizontal: value),
        child: this,
      );

  Widget paddingVertical(double value) => Padding(
        padding: EdgeInsets.symmetric(vertical: value),
        child: this,
      );
}
