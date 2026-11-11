import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/project_widgets.dart';
import '../../../data/project.dart';

/// Baris kedua kartu: "tahun · peran" (tahun tebal), dipotong "…".
class ProjectMeta extends StatelessWidget {
  const ProjectMeta(this.project, {super.key, this.size = 12.5});

  final Project project;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '${project.year}',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: c.fg,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          TextSpan(text: ' · ${project.roles.join(', ')}'),
        ],
      ),
      maxLines: 1,
      softWrap: false,
      overflow: TextOverflow.ellipsis,
      style: AppText.body(size, color: c.fg2),
    );
  }
}

/// Kartu daftar proyek: sampul 16:9 (+ badge), judul, "tahun · peran", tag.
/// [compact]: HP landscape (grid 3 kolom).
class ProjectListCard extends StatelessWidget {
  const ProjectListCard({
    super.key,
    required this.project,
    required this.onTap,
    this.compact = false,
  });

  final Project project;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final p = project;
    return _CardShell(
      label: '${p.title}, ${p.year}',
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ProjectCover(
            project: p,
            gradientStart: 0.6,
            gradientAlpha: 0x4D,
            compactBadge: compact,
          ),
          Padding(
            padding: compact
                ? const EdgeInsets.fromLTRB(12, 10, 12, 12)
                : const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.title,
                  style: AppText.pixel(
                    compact ? 17 : 20,
                    weight: FontWeight.w600,
                    height: 1.1,
                    color: c.fg,
                  ),
                ),
                SizedBox(height: compact ? 5 : 6),
                ProjectMeta(p, size: compact ? 12 : 12.5),
                SizedBox(height: compact ? 7 : 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final t in p.tags) TagChip(t, compact: compact),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Kartu horizontal ringkas untuk layar depan Flip: sampul 16:9 kecil di
/// kiri; judul, "tahun · peran", dan 2 tag pertama di kanan.
class ProjectCompactCard extends StatelessWidget {
  const ProjectCompactCard({
    super.key,
    required this.project,
    required this.onTap,
  });

  final Project project;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final p = project;
    return _CardShell(
      label: '${p.title}, ${p.year}',
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 112,
                child: ProjectCover(
                  project: p,
                  gradientStart: 0.6,
                  gradientAlpha: 0x4D,
                  showBadge: false,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.pixel(
                      16,
                      weight: FontWeight.w600,
                      height: 1.15,
                      color: c.fg,
                    ),
                  ),
                  const SizedBox(height: 3),
                  ProjectMeta(p, size: 12),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final t in p.tags.take(2)) TagChip(t, compact: true),
                    ],
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

/// Latar kartu: surface, sudut 12, bayangan lembut, efek tekan.
class _CardShell extends StatelessWidget {
  const _CardShell({
    required this.label,
    required this.onTap,
    required this.child,
  });

  final String label;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Semantics(
      button: true,
      label: label,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: c.cardShadow,
        ),
        child: Material(
          color: c.surface,
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.antiAlias,
          child: InkWell(onTap: onTap, child: child),
        ),
      ),
    );
  }
}
