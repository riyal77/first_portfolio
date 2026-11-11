import 'package:flutter/material.dart';

import '../../../core/assets/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/pixel_image.dart';
import '../../../data/project.dart';
import 'home_parts.dart';
import 'snap_physics.dart';

/// Susunan bagian FEATURED PROJECTS.
enum FeaturedLayout {
  /// HP portrait & Flip: carousel kartu 85% + "1 / 4" + titik.
  carousel,

  /// HP landscape: carousel kartu 282 px, "GESER ›".
  carouselLandscape,

  /// Tablet: grid [columns] kolom tanpa digeser.
  grid,
}

class FeaturedProjectsSection extends StatefulWidget {
  const FeaturedProjectsSection({
    super.key,
    required this.projects,
    required this.layout,
    required this.controller,
    required this.index,
    required this.onOpen,
    this.columns = 2,
    this.horizontalPadding = 20,
  });

  final List<Project> projects;
  final FeaturedLayout layout;

  /// Disimpan di atas pemilih tata letak agar posisi carousel bertahan.
  final ScrollController controller;

  /// Kartu yang sedang tampil; dipakai untuk mengembalikan posisi saat lebar
  /// kartu berubah (rotasi, layar depan ↔ layar utama Flip).
  final ValueNotifier<int> index;

  final ValueChanged<Project> onOpen;
  final int columns;
  final double horizontalPadding;

  @override
  State<FeaturedProjectsSection> createState() =>
      _FeaturedProjectsSectionState();
}

class _FeaturedProjectsSectionState extends State<FeaturedProjectsSection> {
  static const double _gap = 12;
  double? _extent;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(FeaturedProjectsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onScroll);
      widget.controller.addListener(_onScroll);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    final e = _extent;
    final ctrl = widget.controller;
    if (e == null || !ctrl.hasClients || ctrl.positions.length != 1) return;
    final pos = ctrl.position;
    if (!pos.hasContentDimensions) return;
    // Di ujung kanan, kartu terakhir dianggap aktif walau belum rata kiri.
    final i = pos.pixels >= pos.maxScrollExtent - 1
        ? widget.projects.length - 1
        : (pos.pixels / e).round();
    widget.index.value = i.clamp(0, widget.projects.length - 1);
  }

  /// Saat lebar kartu berubah, gulir carousel ke kartu yang sama.
  void _syncExtent(double extent) {
    if (_extent == extent) return;
    final first = _extent == null;
    _extent = extent;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctrl = widget.controller;
      if (!mounted || !ctrl.hasClients) return;
      final target = (widget.index.value * extent).clamp(
        0.0,
        ctrl.position.maxScrollExtent,
      );
      if (!first || ctrl.position.pixels != target) ctrl.jumpTo(target);
    });
  }

  @override
  Widget build(BuildContext context) {
    final hp = widget.horizontalPadding;
    final projects = widget.projects;
    if (widget.layout == FeaturedLayout.grid) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(
            'FEATURED PROJECTS',
            padding: EdgeInsets.fromLTRB(hp, 0, hp, 12),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(hp, 2, hp, 10),
            child: _Grid(
              projects: projects,
              columns: widget.columns,
              onOpen: widget.onOpen,
            ),
          ),
        ],
      );
    }

    final landscape = widget.layout == FeaturedLayout.carouselLandscape;
    return LayoutBuilder(
      builder: (context, cons) {
        final cardWidth = landscape ? 282.0 : (cons.maxWidth - hp * 2) * 0.85;
        final extent = cardWidth + _gap;
        _syncExtent(extent);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionHeader(
              'FEATURED PROJECTS',
              padding: EdgeInsets.fromLTRB(hp, 0, hp, 12),
              trailing: landscape
                  ? const SectionHint('GESER ›')
                  : ValueListenableBuilder<int>(
                      valueListenable: widget.index,
                      builder: (_, i, _) =>
                          SectionHint('${i + 1} / ${projects.length}'),
                    ),
            ),
            SingleChildScrollView(
              controller: widget.controller,
              scrollDirection: Axis.horizontal,
              physics: SnapToItemPhysics(itemExtent: extent),
              padding: EdgeInsets.fromLTRB(hp, 2, hp, 10),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < projects.length; i++) ...[
                      if (i > 0) const SizedBox(width: _gap),
                      SizedBox(
                        width: cardWidth,
                        child: ProjectCard(
                          project: projects[i],
                          descriptionFirst: landscape,
                          compactTitle: landscape,
                          onTap: () => widget.onOpen(projects[i]),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (!landscape)
              ValueListenableBuilder<int>(
                valueListenable: widget.index,
                builder: (_, i, _) => _Dots(count: projects.length, active: i),
              ),
          ],
        );
      },
    );
  }
}

class _Grid extends StatelessWidget {
  const _Grid({
    required this.projects,
    required this.columns,
    required this.onOpen,
  });

  final List<Project> projects;
  final int columns;
  final ValueChanged<Project> onOpen;

  @override
  Widget build(BuildContext context) {
    const gap = 16.0;
    final rows = <Widget>[];
    for (var start = 0; start < projects.length; start += columns) {
      final row = projects.skip(start).take(columns).toList();
      if (rows.isNotEmpty) rows.add(const SizedBox(height: gap));
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < columns; i++) ...[
                if (i > 0) const SizedBox(width: gap),
                Expanded(
                  child: i < row.length
                      ? ProjectCard(
                          project: row[i],
                          descriptionFirst: true,
                          onTap: () => onOpen(row[i]),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ],
          ),
        ),
      );
    }
    return Column(children: rows);
  }
}

/// Kartu proyek unggulan: sampul 16:9 (+ badge), judul, tag, deskripsi
/// singkat maksimal 2 baris.
class ProjectCard extends StatelessWidget {
  const ProjectCard({
    super.key,
    required this.project,
    required this.onTap,
    this.descriptionFirst = false,
    this.compactTitle = false,
  });

  final Project project;
  final VoidCallback onTap;

  /// Landscape & tablet: deskripsi di atas tag.
  final bool descriptionFirst;

  /// Landscape: judul 18 (bukan 20).
  final bool compactTitle;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final p = project;
    final tags = Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [for (final t in p.tags) _Tag(t)],
    );
    final desc = Text(
      p.summary ?? '',
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: AppText.body(13, height: 1.5, color: c.fg2),
    );
    return Semantics(
      button: true,
      label: '${p.title}. ${p.summary ?? ''}',
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: c.cardShadow,
        ),
        child: Material(
          color: c.surface,
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Cover(project: p),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.title,
                            style: AppText.pixel(
                              compactTitle ? 18 : 20,
                              weight: FontWeight.w600,
                              height: 1.1,
                              color: c.fg,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (descriptionFirst) ...[
                            desc,
                            const SizedBox(height: 8),
                            tags,
                          ] else ...[
                            tags,
                            const SizedBox(height: 8),
                            desc,
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                // Kilau tipis di sudut kiri atas kartu.
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: const Alignment(1, 0.6),
                          colors: [
                            c.shine.withValues(alpha: c.shine.a * 0.35),
                            c.shine.withValues(alpha: 0),
                          ],
                          stops: const [0, 0.28],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Cover extends StatelessWidget {
  const _Cover({required this.project});

  final Project project;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(color: c.raised),
          Image.asset(
            project.coverPath,
            fit: BoxFit.cover,
            filterQuality: project.pixelArt
                ? FilterQuality.none
                : FilterQuality.medium,
            excludeFromSemantics: true,
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x00111111), Color(0x59111111)],
                stops: [0.55, 1],
              ),
            ),
          ),
          if (project.badge != null)
            Positioned(left: 10, top: 10, child: ProjectBadge(project.badge!)),
        ],
      ),
    );
  }
}

/// Badge di atas gambar: selalu #111111 82% + teks terang.
class ProjectBadge extends StatelessWidget {
  const ProjectBadge(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      padding: const EdgeInsets.only(left: 7, right: 9),
      decoration: BoxDecoration(
        color: AppColors.badge,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const PixelIcon(PixelIcons.trophy, size: 14, color: AppColors.paper),
          const SizedBox(width: 6),
          Text(
            text,
            style: AppText.label(10, color: AppColors.paper, spacing: 0.04),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.tag,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: AppText.body(11.5, weight: FontWeight.w600, color: c.fg),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.active});

  final int count;
  final int active;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return ExcludeSemantics(
      child: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < count; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: i == active ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: i == active ? c.fg : c.raised,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
