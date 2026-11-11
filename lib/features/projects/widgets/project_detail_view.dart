import 'package:flutter/material.dart';

import '../../../core/assets/app_assets.dart';
import '../../../core/external_link.dart';
import '../../../core/layout/device_layout.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/app_banner.dart';
import '../../../core/widgets/pixel_image.dart';
import '../../../data/project.dart';
import 'project_gallery.dart';

/// Urutan kunci bagian detail (untuk pemetaan scroll per bagian).
abstract final class DetailSection {
  static const gallery = 0;
  static const head = 1;
  static const about = 2;
  static const info = 3;
  static const roles = 4;
  static const links = 5;
  static const count = 6;
}

/// Detail proyek.
///
/// HP portrait & layar depan Flip: satu kolom selebar layar. HP landscape:
/// satu kolom maks. 560 px di tengah. Tablet: dua kolom; kiri (galeri,
/// strip thumbnail, Tautan) diam sementara kolom info kanan di-scroll.
class ProjectDetailView extends StatelessWidget {
  const ProjectDetailView({
    super.key,
    required this.project,
    required this.layout,
    required this.tabletLandscape,
    required this.scrollController,
    required this.galleryController,
    required this.galleryIndex,
    required this.sectionKeys,
    required this.onBack,
    required this.onFullscreen,
  });

  final Project project;
  final DeviceLayout layout;
  final bool tabletLandscape;
  final ScrollController scrollController;
  final PageController galleryController;
  final ValueNotifier<int> galleryIndex;
  final List<GlobalKey> sectionKeys;
  final VoidCallback onBack;
  final ValueChanged<int> onFullscreen;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final bannerTotal = AppBanner.totalHeight(context);
    return ColoredBox(
      color: c.bg,
      child: Stack(
        children: [
          Positioned.fill(
            child: layout == DeviceLayout.tablet
                ? _twoColumns(context, bannerTotal)
                : _oneColumn(context, bannerTotal),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: AppBanner(leading: AppBackButton(onPressed: onBack)),
          ),
        ],
      ),
    );
  }

  Widget _keyed(int section, Widget child) =>
      KeyedSubtree(key: sectionKeys[section], child: child);

  Widget _gallery({bool thumbnails = false}) => ProjectGallery(
    project: project,
    controller: galleryController,
    index: galleryIndex,
    onFullscreen: onFullscreen,
    thumbnails: thumbnails,
  );

  Widget _oneColumn(BuildContext context, double bannerTotal) {
    final pad = MediaQuery.paddingOf(context);
    final landscape = layout == DeviceLayout.phoneLandscape;
    final cover = layout == DeviceLayout.flipCover;
    final h = cover ? 16.0 : 20.0;
    final titleSize = switch (layout) {
      DeviceLayout.phoneLandscape => 28.0,
      DeviceLayout.flipCover => 26.0,
      _ => 30.0,
    };
    final endPad = pad.bottom + (layout.usesBottomBar ? 38 : 28);

    return SingleChildScrollView(
      controller: scrollController,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: landscape ? 600 : double.infinity,
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(h, bannerTotal + 16, h, endPad),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _keyed(DetailSection.gallery, _gallery()),
                const SizedBox(height: 18),
                _keyed(
                  DetailSection.head,
                  _DetailHead(project: project, titleSize: titleSize),
                ),
                _keyed(DetailSection.about, _About(project: project)),
                _keyed(DetailSection.info, _InfoSection(project: project)),
                _keyed(DetailSection.roles, _RolesSection(project: project)),
                if (project.links.isNotEmpty)
                  _keyed(DetailSection.links, _LinksSection(project: project)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _twoColumns(BuildContext context, double bannerTotal) {
    final pad = MediaQuery.paddingOf(context);
    const outer = 24.0;
    const gap = 28.0;
    return LayoutBuilder(
      builder: (context, cons) {
        final available = cons.maxWidth - outer * 2 - gap;
        // Landscape: galeri besar 600; portrait: kolom kiri 380, tetapi
        // tidak lebih dari ±48% agar kolom info tetap lega.
        final left = tabletLandscape
            ? (available * 0.53).clamp(0.0, 600.0)
            : (available * 0.48).clamp(0.0, 380.0);
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Kolom kiri diam (sticky): galeri, thumbnail, Tautan.
            SizedBox(
              width: left + outer,
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  outer,
                  bannerTotal + 20,
                  0,
                  pad.bottom + 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _keyed(DetailSection.gallery, _gallery(thumbnails: true)),
                    if (project.links.isNotEmpty)
                      _keyed(
                        DetailSection.links,
                        _LinksSection(project: project),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: gap),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: EdgeInsets.fromLTRB(
                  0,
                  bannerTotal + 20,
                  outer,
                  pad.bottom + 32,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _keyed(
                      DetailSection.head,
                      _DetailHead(project: project, titleSize: 30),
                    ),
                    _keyed(DetailSection.about, _About(project: project)),
                    _keyed(DetailSection.info, _InfoSection(project: project)),
                    _keyed(
                      DetailSection.roles,
                      _RolesSection(project: project),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Judul, "genre · tahun", badge penghargaan.
class _DetailHead extends StatelessWidget {
  const _DetailHead({required this.project, required this.titleSize});

  final Project project;
  final double titleSize;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final p = project;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            p.title,
            style: AppText.pixel(
              titleSize,
              weight: FontWeight.w600,
              height: 1.05,
              color: c.fg,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text('${p.genre} · ${p.year}', style: AppText.body(13.5, color: c.fg2)),
        if (p.award != null) ...[
          const SizedBox(height: 10),
          _AwardBadge(p.award!),
        ],
      ],
    );
  }
}

class _AwardBadge extends StatelessWidget {
  const _AwardBadge(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      constraints: const BoxConstraints(minHeight: 28),
      padding: const EdgeInsets.fromLTRB(8, 5, 11, 5),
      decoration: BoxDecoration(
        color: c.btn,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PixelIcon(PixelIcons.trophy, size: 16, color: c.onBtn),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              text.toUpperCase(),
              style: AppText.label(
                10.5,
                color: c.onBtn,
                spacing: 0.04,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Paragraf tentang game, tanpa judul bagian.
class _About extends StatelessWidget {
  const _About({required this.project});

  final Project project;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Text(
        project.about,
        style: AppText.paragraph(color: AppColors.of(context).fg),
      ),
    );
  }
}

/// Judul bagian detail (Silkscreen 13) dengan jarak atas 26.
class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Semantics(
              header: true,
              child: Text(
                title,
                style: AppText.label(13, color: AppColors.of(context).fg),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

/// Info Singkat: 4 ubin 2 kolom.
class _InfoSection extends StatelessWidget {
  const _InfoSection({required this.project});

  final Project project;

  @override
  Widget build(BuildContext context) {
    final p = project;
    final tiles = [
      ('Engine / bahasa', p.engineLine),
      ('Platform', p.platform),
      ('Konteks', p.contextLong),
      ('Tim', p.team),
    ];
    Widget row(int i) => IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: _InfoTile(tiles[i].$1, tiles[i].$2)),
          const SizedBox(width: 10),
          Expanded(child: _InfoTile(tiles[i + 1].$1, tiles[i + 1].$2)),
        ],
      ),
    );
    return _Section(
      title: 'INFO SINGKAT',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [row(0), const SizedBox(height: 10), row(2)],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 11),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: c.shadow1,
            offset: const Offset(0, 1),
            blurRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: AppText.label(9.5, color: c.fg2, spacing: 0.06),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppText.body(
              14,
              weight: FontWeight.w700,
              height: 1.3,
              color: c.fg,
            ),
          ),
        ],
      ),
    );
  }
}

/// Peran & Kontribusiku: chip peran berbingkai, lalu poin kontribusi.
class _RolesSection extends StatelessWidget {
  const _RolesSection({required this.project});

  final Project project;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final para = AppText.paragraph(color: c.fg);
    return _Section(
      title: 'PERAN & KONTRIBUSIKU',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final r in project.roles)
                Container(
                  height: 32,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: c.fg, width: 1.5),
                  ),
                  child: Text(
                    r,
                    style: AppText.body(
                      13,
                      weight: FontWeight.w600,
                      color: c.fg,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: c.shadow1,
                  offset: const Offset(0, 1),
                  blurRadius: 2,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < project.contributions.length; i++) ...[
                  if (i > 0) const SizedBox(height: 9),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Penanda kotak pixel 6 px, sejajar baris pertama.
                      Padding(
                        padding: EdgeInsets.only(
                          left: 2,
                          right: 10,
                          top: (para.fontSize! * para.height! - 6) / 2,
                        ),
                        child: Container(width: 6, height: 6, color: c.fg),
                      ),
                      Expanded(
                        child: Text(project.contributions[i], style: para),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Tautan: tombol per tautan (membuka browser). Tidak ditampilkan bila
/// proyek tidak punya tautan.
class _LinksSection extends StatelessWidget {
  const _LinksSection({required this.project});

  final Project project;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return _Section(
      title: 'TAUTAN',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < project.links.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: c.shadow2,
                    offset: const Offset(0, 8),
                    blurRadius: 18,
                    spreadRadius: -10,
                  ),
                ],
              ),
              child: Material(
                color: c.btn,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => openExternal(project.links[i].url),
                  child: SizedBox(
                    height: 48,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            project.links[i].label.toUpperCase(),
                            overflow: TextOverflow.ellipsis,
                            style: AppText.label(
                              13,
                              color: c.onBtn,
                              spacing: 0.06,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        PixelIcon(
                          PixelIcons.externalLink,
                          size: 18,
                          color: c.onBtn,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text('Membuka browser.', style: AppText.body(12, color: c.fg2)),
        ],
      ),
    );
  }
}
