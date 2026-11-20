// Copyright (c) 2026 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../constants/db_keys.dart';
import '../../../../constants/enum.dart';
import '../../../../utils/extensions/custom_extensions.dart';
import '../../../../widgets/compact_switch.dart';
import '../../../../widgets/desktop/desktop_page_frame.dart';
import '../../../../widgets/desktop/desktop_top_bar.dart';
import '../../../../widgets/shell/detail_navigation_shell_screen.dart';
import '../../search/settings_highlight_target.dart';
import '../../widgets/settings_group_card/settings_group_card.dart';
import 'widgets/venera_engine_prefs/venera_engine_prefs.dart';

/// App-level settings for the vendored Venera engine. Every tile reads its
/// global venera_* provider directly (no ReaderSettingsModel), mirroring the
/// ReaderSettingsScreen pattern.
class VeneraReaderSettingsScreen extends ConsumerWidget {
  const VeneraReaderSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final readerMode = ref.watch(veneraReaderModeSettingProvider) ??
        VeneraReaderMode.continuousTopToBottom;
    final imagesPerPage = ref.watch(veneraImagesPerPageProvider) ??
        (DBKeys.veneraImagesPerPage.initial as int);
    final singleFirstPage = ref
        .watch(veneraSingleFirstPageProvider)
        .ifNull(DBKeys.veneraSingleFirstPage.initial as bool);
    final tapToTurnPages = ref
        .watch(veneraTapToTurnPagesProvider)
        .ifNull(DBKeys.veneraTapToTurnPages.initial as bool);
    final reverseTapToTurnPages = ref
        .watch(veneraReverseTapToTurnPagesProvider)
        .ifNull(DBKeys.veneraReverseTapToTurnPages.initial as bool);
    final doubleTapToZoom = ref
        .watch(veneraDoubleTapToZoomProvider)
        .ifNull(DBKeys.veneraDoubleTapToZoom.initial as bool);
    final longPressZoom = ref
        .watch(veneraLongPressZoomProvider)
        .ifNull(DBKeys.veneraLongPressZoom.initial as bool);
    final limitImageWidth = ref
        .watch(veneraLimitImageWidthProvider)
        .ifNull(DBKeys.veneraLimitImageWidth.initial as bool);
    final showPageNumber = ref
        .watch(veneraShowPageNumberProvider)
        .ifNull(DBKeys.veneraShowPageNumber.initial as bool);
    final showSystemStatusBar = ref
        .watch(veneraShowSystemStatusBarProvider)
        .ifNull(DBKeys.veneraShowSystemStatusBar.initial as bool);
    final enablePageAnimation = ref
        .watch(veneraEnablePageAnimationProvider)
        .ifNull(DBKeys.veneraEnablePageAnimation.initial as bool);
    final pageAnimationMs = ref.watch(veneraPageAnimationMsProvider) ??
        (DBKeys.veneraPageAnimationMs.initial as int);
    final autoPageTurningInterval =
        ref.watch(veneraAutoPageTurningIntervalProvider) ??
            (DBKeys.veneraAutoPageTurningInterval.initial as int);
    final preloadImageCount = ref.watch(veneraPreloadImageCountProvider) ??
        (DBKeys.veneraPreloadImageCount.initial as int);
    final volumeKey = ref
        .watch(veneraPageTurnVolumeKeyProvider)
        .ifNull(DBKeys.veneraPageTurnVolumeKey.initial as bool);
    final wheelSensitivity = ref.watch(veneraWheelSensitivityProvider) ??
        (DBKeys.veneraWheelSensitivity.initial as double);

    final topBar = showsMergedTopBar(context);
    final title = Text(context.l10n.veneraReaderSettingsTitle);
    final scaffold = Scaffold(
      appBar: topBar
          ? null
          : AppBar(leading: detailNavigationBackButton(context), title: title),
      body: SettingsHighlightScope(
        child: Center(
          child: ConstrainedBox(
            constraints: settingsPageConstraints(context),
            child: ListView(
              padding: settingsPagePadding(context),
              children: [
                const DesktopPageLeadingGap(16),
                SettingsGroupHeading(
                  label: context.l10n.veneraGroupReadingMode,
                  first: true,
                ),
                SettingsGroupCard(
                  children: [
                    SettingsHighlightTarget(
                      id: 'veneraReaderMode',
                      child: _EnumChips<VeneraReaderMode>(
                        label: context.l10n.veneraReaderMode,
                        values: VeneraReaderMode.values,
                        selected: readerMode,
                        labelOf: (v) => v.toLocale(context),
                        onSelected: (v) => ref
                            .read(veneraReaderModeSettingProvider.notifier)
                            .update(v),
                      ),
                    ),
                    SettingsHighlightTarget(
                      id: 'veneraImagesPerPage',
                      child: _IntSliderTile(
                        title: context.l10n.veneraImagesPerPage,
                        value: imagesPerPage,
                        min: 1,
                        max: 5,
                        labelOf: (v) => v.toString(),
                        onChanged: (v) => ref
                            .read(veneraImagesPerPageProvider.notifier)
                            .update(v),
                      ),
                    ),
                    SettingsHighlightTarget(
                      id: 'veneraSingleFirstPage',
                      child: _BoolTile(
                        title: context.l10n.veneraSingleFirstPage,
                        value: singleFirstPage,
                        onChanged: (v) => ref
                            .read(veneraSingleFirstPageProvider.notifier)
                            .update(v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                SettingsGroupHeading(label: context.l10n.veneraGroupGestures),
                SettingsGroupCard(
                  children: [
                    SettingsHighlightTarget(
                      id: 'veneraTapToTurnPages',
                      child: _BoolTile(
                        title: context.l10n.veneraTapToTurnPages,
                        value: tapToTurnPages,
                        onChanged: (v) => ref
                            .read(veneraTapToTurnPagesProvider.notifier)
                            .update(v),
                      ),
                    ),
                    SettingsHighlightTarget(
                      id: 'veneraReverseTapToTurnPages',
                      child: _BoolTile(
                        title: context.l10n.veneraReverseTapToTurnPages,
                        value: reverseTapToTurnPages,
                        onChanged: (v) => ref
                            .read(veneraReverseTapToTurnPagesProvider.notifier)
                            .update(v),
                      ),
                    ),
                    SettingsHighlightTarget(
                      id: 'veneraDoubleTapToZoom',
                      child: _BoolTile(
                        title: context.l10n.veneraDoubleTapToZoom,
                        value: doubleTapToZoom,
                        onChanged: (v) => ref
                            .read(veneraDoubleTapToZoomProvider.notifier)
                            .update(v),
                      ),
                    ),
                    SettingsHighlightTarget(
                      id: 'veneraLongPressZoom',
                      child: _BoolTile(
                        title: context.l10n.veneraLongPressToZoom,
                        value: longPressZoom,
                        onChanged: (v) => ref
                            .read(veneraLongPressZoomProvider.notifier)
                            .update(v),
                      ),
                    ),
                    SettingsHighlightTarget(
                      id: 'veneraLimitImageWidth',
                      child: _BoolTile(
                        title: context.l10n.veneraLimitImageWidth,
                        value: limitImageWidth,
                        onChanged: (v) => ref
                            .read(veneraLimitImageWidthProvider.notifier)
                            .update(v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                SettingsGroupHeading(label: context.l10n.veneraGroupDisplay),
                SettingsGroupCard(
                  children: [
                    SettingsHighlightTarget(
                      id: 'veneraShowPageNumber',
                      child: _BoolTile(
                        title: context.l10n.veneraShowPageNumber,
                        value: showPageNumber,
                        onChanged: (v) => ref
                            .read(veneraShowPageNumberProvider.notifier)
                            .update(v),
                      ),
                    ),
                    SettingsHighlightTarget(
                      id: 'veneraShowSystemStatusBar',
                      child: _BoolTile(
                        title: context.l10n.veneraShowSystemStatusBar,
                        value: showSystemStatusBar,
                        onChanged: (v) => ref
                            .read(veneraShowSystemStatusBarProvider.notifier)
                            .update(v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                SettingsGroupHeading(label: context.l10n.veneraGroupBehavior),
                SettingsGroupCard(
                  children: [
                    SettingsHighlightTarget(
                      id: 'veneraEnablePageAnimation',
                      child: _BoolTile(
                        title: context.l10n.veneraEnablePageAnimation,
                        value: enablePageAnimation,
                        onChanged: (v) => ref
                            .read(veneraEnablePageAnimationProvider.notifier)
                            .update(v),
                      ),
                    ),
                    SettingsHighlightTarget(
                      id: 'veneraPageAnimationMs',
                      child: _IntSliderTile(
                        title: context.l10n.veneraPageAnimationDuration,
                        value: pageAnimationMs,
                        min: 50,
                        max: 500,
                        labelOf: (v) =>
                            context.l10n.veneraPageAnimationMsValue(v),
                        onChanged: (v) => ref
                            .read(veneraPageAnimationMsProvider.notifier)
                            .update(v),
                      ),
                    ),
                    SettingsHighlightTarget(
                      id: 'veneraAutoPageTurningInterval',
                      child: _IntSliderTile(
                        title: context.l10n.veneraAutoPageTurningInterval,
                        value: autoPageTurningInterval,
                        min: 1,
                        max: 30,
                        labelOf: (v) =>
                            context.l10n.veneraAutoPageTurningSecondsValue(v),
                        onChanged: (v) => ref
                            .read(veneraAutoPageTurningIntervalProvider.notifier)
                            .update(v),
                      ),
                    ),
                    SettingsHighlightTarget(
                      id: 'veneraPreloadImageCount',
                      child: _IntSliderTile(
                        title: context.l10n.veneraPreloadImageCount,
                        value: preloadImageCount,
                        min: 1,
                        max: 8,
                        labelOf: (v) => v.toString(),
                        onChanged: (v) => ref
                            .read(veneraPreloadImageCountProvider.notifier)
                            .update(v),
                      ),
                    ),
                    SettingsHighlightTarget(
                      id: 'veneraPageTurnVolumeKey',
                      child: _BoolTile(
                        title: context.l10n.veneraPageTurnVolumeKey,
                        value: volumeKey,
                        onChanged: (v) => ref
                            .read(veneraPageTurnVolumeKeyProvider.notifier)
                            .update(v),
                      ),
                    ),
                    SettingsHighlightTarget(
                      id: 'veneraWheelSensitivity',
                      child: _DoubleSliderTile(
                        title: context.l10n.veneraWheelSensitivity,
                        value: wheelSensitivity,
                        min: 0.25,
                        max: 4,
                        labelOf: (v) => v.toStringAsFixed(2),
                        onChanged: (v) => ref
                            .read(veneraWheelSensitivityProvider.notifier)
                            .update(v),
                      ),
                    ),
                  ],
                ),

                const Gap(128),
              ],
            ),
          ),
        ),
      ),
    );
    return titleTopBarSlot(
      topBar: topBar,
      leading: detailNavigationBackButton(context),
      title: title,
      child: scaffold,
    );
  }
}

class _BoolTile extends StatelessWidget {
  const _BoolTile({
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
      title: Text(title),
      value: value,
      onChanged: onChanged,
    );
  }
}

class _EnumChips<T> extends StatelessWidget {
  const _EnumChips({
    required this.label,
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onSelected,
  });

  final String label;
  final List<T> values;
  final T selected;
  final String Function(T) labelOf;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              label,
              style:
                  context.theme.listTileTheme.titleTextStyle ??
                  context.textTheme.titleMedium?.copyWith(
                    color: context.theme.colorScheme.onSurface,
                  ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final v in values)
                FilterChip(
                  selected: v == selected,
                  showCheckmark: false,
                  label: Text(labelOf(v)),
                  onSelected: (_) => onSelected(v),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _IntSliderTile extends StatelessWidget {
  const _IntSliderTile({
    required this.title,
    required this.value,
    required this.min,
    required this.max,
    required this.labelOf,
    required this.onChanged,
  });

  final String title;
  final int value;
  final int min;
  final int max;
  final String Function(int) labelOf;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      subtitle: Row(
        children: [
          Expanded(
            child: Slider(
              value: value.toDouble(),
              min: min.toDouble(),
              max: max.toDouble(),
              divisions: max - min,
              label: labelOf(value),
              onChanged: (v) => onChanged(v.round()),
            ),
          ),
          Text(labelOf(value)),
        ],
      ),
    );
  }
}

class _DoubleSliderTile extends StatelessWidget {
  const _DoubleSliderTile({
    required this.title,
    required this.value,
    required this.min,
    required this.max,
    required this.labelOf,
    required this.onChanged,
  });

  final String title;
  final double value;
  final double min;
  final double max;
  final String Function(double) labelOf;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      subtitle: Row(
        children: [
          Expanded(
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              divisions: ((max - min) / 0.25).round(),
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
