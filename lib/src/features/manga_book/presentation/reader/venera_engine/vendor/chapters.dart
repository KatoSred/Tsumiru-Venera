// Copyright (C) 2024-2026 venera-app contributors
// SPDX-License-Identifier: GPL-3.0-or-later
//
// Vendored from https://github.com/venera-app/venera (lib/pages/reader/)
// and modified for Tsumiru on 2026-11-20:
//  - VENDOR-CUT: LocalManager().find(...) downloaded-chapter marks removed
//    (no local-comic concept in M1; `downloaded` stays empty).
//  - VENDOR-CUT: venera SmoothCustomScrollView / SliverAppbar / Appbar /
//    AppTabBar / TabViewBody replaced by compat shim + native material
//    widgets (CustomScrollView shim, AppBar, TabBar, TabBarView). Grouped
//    view keeps the same tab/group structure.
//  - "Chapters"/etc translations and ts/context extensions come from the
//    compat shims.
//  - M5 reskin: sidebar visuals restyled to Tsumiru — surface background,
//    FluentIcons glyphs, chapter rows aligned with Tsumiru's chapter sheet
//    (current chapter highlighted in primary, downloaded marks use the brand
//    success color). List structure/order toggling unchanged.
//    NOTE: the vendored reader has no per-chapter "read" state (VENDOR-CUT of
//    HistoryManager in M1), so read/unread iconography can't be reproduced;
//    the downloaded mark fills that slot.

part of 'reader.dart';

class _ChaptersView extends StatefulWidget {
  const _ChaptersView(this.reader);

  final _ReaderState reader;

  @override
  State<_ChaptersView> createState() => _ChaptersViewState();
}

class _ChaptersViewState extends State<_ChaptersView> {
  bool desc = false;

  late final ScrollController _scrollController;

  var downloaded = <String>[];

  @override
  void initState() {
    super.initState();
    int epIndex = widget.reader.chapter - 2;
    _scrollController = ScrollController(
      initialScrollOffset: (epIndex * 48.0 + 52).clamp(0, double.infinity),
    );
    // VENDOR-CUT: LocalManager().find(...) downloaded marks removed.
  }

  @override
  Widget build(BuildContext context) {
    var chapters = widget.reader.widget.chapters!;
    var current = widget.reader.chapter - 1;
    final colorScheme = context.colorScheme;
    return Scaffold(
      // M5: sidebar surface matches Tsumiru's sheet styling.
      backgroundColor: colorScheme.surface,
      body: SmoothCustomScrollView(
        controller: _scrollController,
        slivers: [
          // VENDOR-CUT: venera SliverAppbar replaced by SliverToBoxAdapter +
          // native AppBar.
          SliverToBoxAdapter(
            child: AppBar(
              title: Text(
                "Chapters".tl,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              backgroundColor: colorScheme.surface,
              foregroundColor: colorScheme.onSurface,
              elevation: 0,
              actions: [
                Tooltip(
                  message: "Click to change the order".tl,
                  child: TextButton.icon(
                    icon: Icon(
                      !desc
                          ? FluentIcons.arrow_up_24_regular
                          : FluentIcons.arrow_down_24_regular,
                      size: 18,
                      color: colorScheme.primary,
                    ),
                    label: Text(
                      !desc ? "Ascending".tl : "Descending".tl,
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        desc = !desc;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (desc) {
                  index = chapters.length - 1 - index;
                }
                var chapter = chapters.titles.elementAt(index);
                return _ChapterListTile(
                  onTap: () {
                    widget.reader.toChapter(index + 1);
                    Navigator.of(context).pop();
                  },
                  title: chapter,
                  isActive: current == index,
                  isDownloaded:
                      downloaded.contains(chapters.ids.elementAt(index)),
                );
              },
              childCount: chapters.length,
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupedChaptersView extends StatefulWidget {
  const _GroupedChaptersView(this.reader);

  final _ReaderState reader;

  @override
  State<_GroupedChaptersView> createState() => _GroupedChaptersViewState();
}

class _GroupedChaptersViewState extends State<_GroupedChaptersView>
    with SingleTickerProviderStateMixin {
  ComicChapters get chapters => widget.reader.widget.chapters!;

  late final TabController tabController;

  late final ScrollController _scrollController;

  late final String initialGroupName;

  var downloaded = <String>[];

  @override
  void initState() {
    super.initState();
    int index = 0;
    int epIndex = widget.reader.chapter - 1;
    while (epIndex >= 0) {
      epIndex -= chapters.getGroupByIndex(index).length;
      index++;
    }
    tabController = TabController(
      length: chapters.groups.length,
      vsync: this,
      initialIndex: index - 1,
    );
    initialGroupName = chapters.groups.keys.elementAt(index - 1);
    var epIndexAtGroup = widget.reader.chapter - 1;
    for (var i = 0; i < index - 1; i++) {
      epIndexAtGroup -= chapters.getGroupByIndex(i).length;
    }
    _scrollController = ScrollController(
      initialScrollOffset: (epIndexAtGroup * 48.0).clamp(0, double.infinity),
    );
    // VENDOR-CUT: LocalManager().find(...) downloaded marks removed.
  }

  @override
  Widget build(BuildContext context) {
    // VENDOR-CUT: venera Appbar / AppTabBar / TabViewBody replaced by native
    // material widgets.
    final colorScheme = context.colorScheme;
    return Column(
      children: [
        AppBar(
          title: Text(
            "Chapters".tl,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          backgroundColor: colorScheme.surface,
          foregroundColor: colorScheme.onSurface,
          elevation: 0,
        ),
        TabBar(
          controller: tabController,
          tabs: chapters.groups.keys.map((e) => Tab(text: e)).toList(),
        ),
        Expanded(
          child: TabBarView(
            controller: tabController,
            children: chapters.groups.keys.map(buildGroup).toList(),
          ),
        ),
      ],
    );
  }

  Widget buildGroup(String groupName) {
    var group = chapters.getGroup(groupName);
    return SmoothCustomScrollView(
      controller: initialGroupName == groupName ? _scrollController : null,
      slivers: [
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              var name = group.values.elementAt(index);
              var i = 0;
              for (var g in chapters.groups.keys) {
                if (g == groupName) {
                  break;
                }
                i += chapters.getGroup(g).length;
              }
              i += index + 1;
              return _ChapterListTile(
                onTap: () {
                  widget.reader.toChapter(i);
                  context.pop();
                },
                title: name,
                isActive: widget.reader.chapter == i,
                isDownloaded: downloaded.contains(group.keys.elementAt(index)),
              );
            },
            childCount: group.length,
          ),
        ),
      ],
    );
  }
}

class _ChapterListTile extends StatelessWidget {
  const _ChapterListTile({
    required this.title,
    required this.isActive,
    required this.isDownloaded,
    required this.onTap,
  });

  final String title;

  final bool isActive;

  final bool isDownloaded;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // M5: row style mirrors Tsumiru's reader chapter sheet — current chapter
    // keeps the primary edge bar and gets primary semibold text; the
    // downloaded mark uses the brand success hue.
    final colorScheme = context.colorScheme;
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isActive
              ? colorScheme.primaryContainer.toOpacity(0.35)
              : Colors.transparent,
          border: Border(
            left: BorderSide(
              color: isActive ? colorScheme.primary : Colors.transparent,
              width: 4,
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  color: isActive
                      ? colorScheme.primary
                      : colorScheme.onSurface,
                ),
              ),
            ),
            if (isDownloaded)
              Icon(
                FluentIcons.checkmark_circle_24_regular,
                size: 18,
                color: BrandColors.of(context).success,
              ),
          ],
        ),
      ),
    );
  }
}
