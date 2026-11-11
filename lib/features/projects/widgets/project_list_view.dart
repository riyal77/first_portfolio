import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/layout/device_layout.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/app_banner.dart';
import '../../../data/project.dart';
import '../project_filter.dart';
import 'filter_bar.dart';
import 'project_cards.dart';

/// Daftar proyek: App Banner "Game Projects" + jumlah, filter yang menempel
/// di bawah banner, lalu kartu (susunannya mengikuti [layout]).
class ProjectListView extends StatelessWidget {
  const ProjectListView({
    super.key,
    required this.layout,
    required this.landscape,
    required this.projects,
    required this.total,
    required this.filter,
    required this.onFilter,
    required this.controller,
    required this.filterVisible,
    required this.filterStuck,
    required this.cardKeys,
    required this.onOpen,
  });

  final DeviceLayout layout;

  /// Tablet landscape (grid 3 kolom).
  final bool landscape;

  /// Proyek yang lolos filter, dalam urutan tampil.
  final List<Project> projects;
  final int total;
  final ProjectFilter filter;
  final ValueChanged<ProjectFilter> onFilter;
  final ScrollController controller;

  /// Filter bersembunyi saat scroll ke bawah, muncul saat scroll ke atas.
  final ValueListenable<bool> filterVisible;

  /// Konten sudah tergulir di bawah filter: latar kaca.
  final ValueListenable<bool> filterStuck;

  /// Kunci tiap kartu (per id) untuk pemetaan scroll per kartu.
  final Map<String, GlobalKey> cardKeys;
  final ValueChanged<Project> onOpen;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final pad = MediaQuery.paddingOf(context);
    final bannerTotal = AppBanner.totalHeight(context);
    final cover = layout == DeviceLayout.flipCover;
    final phoneLandscape = layout == DeviceLayout.phoneLandscape;
    final filterHeight = FilterBar.heightFor(
      compact: cover,
      landscape: phoneLandscape,
    );
    final hp = switch (layout) {
      DeviceLayout.tablet => 24.0,
      DeviceLayout.flipCover => 16.0,
      _ => 20.0,
    };

    final Widget cards = switch (layout) {
      DeviceLayout.phonePortrait => _column(gap: 16),
      DeviceLayout.flipCover => _column(gap: 10, compactCards: true),
      DeviceLayout.phoneLandscape => _grid(columns: 3, gap: 14, compact: true),
      DeviceLayout.tablet => _grid(columns: landscape ? 3 : 2, gap: 16),
    };

    final endPad = pad.bottom + (layout.usesBottomBar ? 34 : 24);

    return Stack(
      children: [
        Positioned.fill(
          child: SingleChildScrollView(
            controller: controller,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                hp,
                bannerTotal + filterHeight + 4,
                hp,
                endPad,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  cards,
                  Padding(
                    padding: const EdgeInsets.only(top: 22),
                    child: Text(
                      '$total PROYEK · 2023–2025',
                      textAlign: TextAlign.center,
                      style: AppText.label(10, color: c.muted, spacing: 0.06),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Filter menempel di bawah banner; bersembunyi ke balik banner.
        Positioned(
          top: bannerTotal,
          left: 0,
          right: 0,
          child: ValueListenableBuilder<bool>(
            valueListenable: filterVisible,
            builder: (context, visible, child) => AnimatedSlide(
              offset: visible ? Offset.zero : const Offset(0, -1.1),
              duration: const Duration(milliseconds: 250),
              curve: Curves.ease,
              child: IgnorePointer(ignoring: !visible, child: child),
            ),
            child: ValueListenableBuilder<bool>(
              valueListenable: filterStuck,
              builder: (context, stuck, _) => FilterBar(
                selected: filter,
                onSelected: onFilter,
                stuck: stuck,
                compact: cover,
                landscape: phoneLandscape,
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          child: AppBanner(
            leading: BannerTitle(
              'Game Projects',
              subtitle: ProjectFilter.countLabel(
                filter,
                projects.length,
                total,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _card(Project p, {bool compact = false, bool horizontal = false}) {
    final key = cardKeys[p.id];
    final card = horizontal
        ? ProjectCompactCard(project: p, onTap: () => onOpen(p))
        : ProjectListCard(project: p, compact: compact, onTap: () => onOpen(p));
    return KeyedSubtree(key: key, child: card);
  }

  Widget _column({required double gap, bool compactCards = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < projects.length; i++) ...[
          if (i > 0) SizedBox(height: gap),
          _card(projects[i], horizontal: compactCards),
        ],
      ],
    );
  }

  /// Grid dengan tinggi kartu sebaris disamakan.
  Widget _grid({
    required int columns,
    required double gap,
    bool compact = false,
  }) {
    final rows = <Widget>[];
    for (var start = 0; start < projects.length; start += columns) {
      final row = projects.skip(start).take(columns).toList();
      if (rows.isNotEmpty) rows.add(SizedBox(height: gap));
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < columns; i++) ...[
                if (i > 0) SizedBox(width: gap),
                Expanded(
                  child: i < row.length
                      ? _card(row[i], compact: compact)
                      : const SizedBox.shrink(),
                ),
              ],
            ],
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rows,
    );
  }
}
