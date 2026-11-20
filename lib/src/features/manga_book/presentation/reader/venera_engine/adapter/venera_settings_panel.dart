// Copyright (c) 2026 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

// ADAPTER(M5): host-side settings panel for the vendored Venera engine.
// Opens from the vendored scaffold's settings button (onOpenSettings) so the
// Venera engine gets its own panel instead of Tsumiru's reader settings
// sheet. This file belongs to the host (MPL zone): it reads the global
// venera_* riverpod providers directly and only depends on the vendored
// layer through the showSideBar compat shim.

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../../constants/db_keys.dart';
import '../../../../../../constants/enum.dart';
import '../../../../../../features/settings/presentation/reader/widgets/venera_engine_prefs/venera_engine_prefs.dart';
import '../../../../../../utils/extensions/custom_extensions.dart';
import '../../../../../../widgets/compact_switch.dart';
import 'compat/components_shim.dart';

/// Opens the Venera engine's own settings panel (right sidebar interaction,
/// matching the original Venera reader).
Future<void> showVeneraSettingsPanel(BuildContext context, WidgetRef ref) {
  return showSideBar(context, const _VeneraSettingsPanel());
}

class _VeneraSettingsPanel extends ConsumerWidget {
  const _VeneraSettingsPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = context.theme.colorScheme;
    return Material(
      color: cs.surface,
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                context.l10n.veneraReaderSettingsTitle,
                style: context.textTheme.titleMedium?.copyWith(
                  color: cs.onSurface,
                ),
              ),
            ),
            Divider(height: 1, color: cs.outlineVariant),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 16),
                children: [
                  _GroupLabel(context.l10n.veneraGroupReadingMode),
                  const _ModeChips(),
                  _SliderTile(
                    title: context.l10n.veneraImagesPerPage,
                    value: (ref.watch(veneraImagesPerPageProvider) ??
                            DBKeys.veneraImagesPerPage.initial as int)
                        .toDouble(),
                    min: 1,
                    max: 5,
                    divisions: 4,
                    labelOf: (v) => v.round().toString(),
                    onChanged: (v) => ref
                        .read(veneraImagesPerPageProvider.notifier)
                        .update(v.round()),
                  ),
                  _SwitchTile(
                    title: context.l10n.veneraSingleFirstPage,
                    value: ref
                        .watch(veneraSingleFirstPageProvider)
                        .ifNull(DBKeys.veneraSingleFirstPage.initial as bool),
                    onChanged: (v) => ref
                        .read(veneraSingleFirstPageProvider.notifier)
                        .update(v),
                  ),

                  _GroupLabel(context.l10n.veneraGroupGestures),
                  _SwitchTile(
                    title: context.l10n.veneraTapToTurnPages,
                    value: ref
                        .watch(veneraTapToTurnPagesProvider)
                        .ifNull(DBKeys.veneraTapToTurnPages.initial as bool),
                    onChanged: (v) => ref
                        .read(veneraTapToTurnPagesProvider.notifier)
                        .update(v),
                  ),
                  _SwitchTile(
                    title: context.l10n.veneraReverseTapToTurnPages,
                    value: ref
                        .watch(veneraReverseTapToTurnPagesProvider)
                        .ifNull(DBKeys.veneraReverseTapToTurnPages.initial
                            as bool),
                    onChanged: (v) => ref
                        .read(veneraReverseTapToTurnPagesProvider.notifier)
                        .update(v),
                  ),
                  _SwitchTile(
                    title: context.l10n.veneraDoubleTapToZoom,
                    value: ref
                        .watch(veneraDoubleTapToZoomProvider)
                        .ifNull(DBKeys.veneraDoubleTapToZoom.initial as bool),
                    onChanged: (v) => ref
                        .read(veneraDoubleTapToZoomProvider.notifier)
                        .update(v),
                  ),
                  _SwitchTile(
                    title: context.l10n.veneraLongPressToZoom,
                    value: ref
                        .watch(veneraLongPressZoomProvider)
                        .ifNull(DBKeys.veneraLongPressZoom.initial as bool),
                    onChanged: (v) => ref
                        .read(veneraLongPressZoomProvider.notifier)
                        .update(v),
                  ),
                  _SwitchTile(
                    title: context.l10n.veneraLimitImageWidth,
                    value: ref
                        .watch(veneraLimitImageWidthProvider)
                        .ifNull(DBKeys.veneraLimitImageWidth.initial as bool),
                    onChanged: (v) => ref
                        .read(veneraLimitImageWidthProvider.notifier)
                        .update(v),
                  ),

                  _GroupLabel(context.l10n.veneraGroupDisplay),
                  _SwitchTile(
                    title: context.l10n.veneraShowPageNumber,
                    value: ref
                        .watch(veneraShowPageNumberProvider)
                        .ifNull(DBKeys.veneraShowPageNumber.initial as bool),
                    onChanged: (v) => ref
                        .read(veneraShowPageNumberProvider.notifier)
                        .update(v),
                  ),
                  _SwitchTile(
                    title: context.l10n.veneraShowSystemStatusBar,
                    value: ref
                        .watch(veneraShowSystemStatusBarProvider)
                        .ifNull(DBKeys.veneraShowSystemStatusBar.initial
                            as bool),
                    onChanged: (v) => ref
                        .read(veneraShowSystemStatusBarProvider.notifier)
                        .update(v),
                  ),

                  _GroupLabel(context.l10n.veneraGroupBehavior),
                  _SwitchTile(
                    title: context.l10n.veneraEnablePageAnimation,
                    value: ref
                        .watch(veneraEnablePageAnimationProvider)
                        .ifNull(DBKeys.veneraEnablePageAnimation.initial
                            as bool),
                    onChanged: (v) => ref
                        .read(veneraEnablePageAnimationProvider.notifier)
                        .update(v),
                  ),
                  _SliderTile(
                    title: context.l10n.veneraPageAnimationDuration,
                    value: (ref.watch(veneraPageAnimationMsProvider) ??
                            DBKeys.veneraPageAnimationMs.initial as int)
                        .toDouble(),
                    min: 50,
                    max: 500,
                    divisions: 45,
                    labelOf: (v) => context.l10n.veneraPageAnimationMsValue(
                      v.round(),
                    ),
                    onChanged: (v) => ref
                        .read(veneraPageAnimationMsProvider.notifier)
                        .update(v.round()),
                  ),
                  _SliderTile(
                    title: context.l10n.veneraAutoPageTurningInterval,
                    value: (ref.watch(veneraAutoPageTurningIntervalProvider) ??
                            DBKeys.veneraAutoPageTurningInterval.initial as int)
                        .toDouble(),
                    min: 1,
                    max: 30,
                    divisions: 29,
                    labelOf: (v) =>
                        context.l10n.veneraAutoPageTurningSecondsValue(
                          v.round(),
                        ),
                    onChanged: (v) => ref
                        .read(veneraAutoPageTurningIntervalProvider.notifier)
                        .update(v.round()),
                  ),
                  _SliderTile(
                    title: context.l10n.veneraPreloadImageCount,
                    value: (ref.watch(veneraPreloadImageCountProvider) ??
                            DBKeys.veneraPreloadImageCount.initial as int)
                        .toDouble(),
                    min: 1,
                    max: 8,
                    divisions: 7,
                    labelOf: (v) => v.round().toString(),
                    onChanged: (v) => ref
                        .read(veneraPreloadImageCountProvider.notifier)
                        .update(v.round()),
                  ),
                  _SwitchTile(
                    title: context.l10n.veneraPageTurnVolumeKey,
                    value: ref
                        .watch(veneraPageTurnVolumeKeyProvider)
                        .ifNull(DBKeys.veneraPageTurnVolumeKey.initial as bool),
                    onChanged: (v) => ref
                        .read(veneraPageTurnVolumeKeyProvider.notifier)
                        .update(v),
                  ),
                  _SliderTile(
                    title: context.l10n.veneraWheelSensitivity,
                    value: ref.watch(veneraWheelSensitivityProvider) ??
                        DBKeys.veneraWheelSensitivity.initial as double,
                    min: 0.25,
                    max: 4,
                    divisions: 15,
                    labelOf: (v) => v.toStringAsFixed(2),
                    onChanged: (v) => ref
                        .read(veneraWheelSensitivityProvider.notifier)
                        .update(v),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        label,
        style: context.textTheme.labelLarge?.copyWith(
          color: context.theme.colorScheme.primary,
        ),
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return CompactSwitchListTile(
      controlAffinity: ListTileControlAffinity.trailing,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      title: Text(title),
      value: value,
      onChanged: onChanged,
    );
  }
}

class _SliderTile extends StatelessWidget {
  const _SliderTile({
    required this.title,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.labelOf,
    required this.onChanged,
  });

  final String title;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String Function(double) labelOf;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      title: Text(title),
      subtitle: Row(
        children: [
          Expanded(
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              divisions: divisions,
              label: labelOf(value),
              onChanged: onChanged,
            ),
          ),
          Text(labelOf(value)),
        ],
      ),
    );
  }
}

class _ModeChips extends ConsumerWidget {
  const _ModeChips();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(veneraReaderModeSettingProvider) ??
        VeneraReaderMode.continuousTopToBottom;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          for (final mode in VeneraReaderMode.values)
            FilterChip(
              selected: mode == selected,
              showCheckmark: false,
              label: Text(mode.toLocale(context)),
              onSelected: (_) => ref
                  .read(veneraReaderModeSettingProvider.notifier)
                  .update(mode),
            ),
        ],
      ),
    );
  }
}
