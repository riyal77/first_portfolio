import 'package:flutter/material.dart';

import '../../data/project.dart';
import '../assets/app_assets.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import 'pixel_image.dart';

/// Gambar proyek: pixel art tanpa penghalusan, lainnya dihaluskan.
class ProjectImage extends StatelessWidget {
  const ProjectImage(
    this.project,
    this.index, {
    super.key,
    this.fit = BoxFit.cover,
  });

  final Project project;
  final int index;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      project.imagePath(index),
      fit: fit,
      filterQuality: project.pixelArt
          ? FilterQuality.none
          : FilterQuality.medium,
      gaplessPlayback: true,
      excludeFromSemantics: true,
    );
  }
}

/// Sampul 16:9 kartu proyek: gambar ke-0, gradien gelap di bawah, dan
/// badge penghargaan (bila ada) di kiri atas.
class ProjectCover extends StatelessWidget {
  const ProjectCover({
    super.key,
    required this.project,
    this.gradientStart = 0.55,
    this.gradientAlpha = 0x59,
    this.compactBadge = false,
    this.showBadge = true,
  });

  final Project project;

  /// Titik mulai gradien gelap (0..1 dari atas).
  final double gradientStart;

  /// Kepekatan gradien di dasar (0..255).
  final int gradientAlpha;

  /// Badge lebih kecil (HP landscape).
  final bool compactBadge;
  final bool showBadge;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final inset = compactBadge ? 8.0 : 10.0;
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(color: c.raised),
          ProjectImage(project, 0),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0x00111111),
                  Color.fromARGB(gradientAlpha, 0x11, 0x11, 0x11),
                ],
                stops: [gradientStart, 1],
              ),
            ),
          ),
          if (showBadge && project.badge != null)
            Positioned(
              left: inset,
              top: inset,
              child: ProjectBadge(project.badge!, compact: compactBadge),
            ),
        ],
      ),
    );
  }
}

/// Badge di atas gambar: selalu #111111 82% + teks terang.
class ProjectBadge extends StatelessWidget {
  const ProjectBadge(this.text, {super.key, this.compact = false});

  final String text;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: compact ? 22 : 24,
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
            style: AppText.label(
              compact ? 9 : 10,
              color: AppColors.paper,
              spacing: 0.04,
            ),
          ),
        ],
      ),
    );
  }
}

/// Tag kecil berlatar `tag` (engine, bahasa, genre, konteks).
class TagChip extends StatelessWidget {
  const TagChip(this.text, {super.key, this.compact = false});

  final String text;

  /// Lebih kecil (HP landscape): 11 px, padding 2 × 7.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      padding: compact
          ? const EdgeInsets.symmetric(horizontal: 7, vertical: 2)
          : const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.tag,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: AppText.body(
          compact ? 11 : 11.5,
          weight: FontWeight.w600,
          color: c.fg,
        ),
      ),
    );
  }
}

/// Titik penanda halaman: aktif memanjang 18 px berwarna fg.
class PageDots extends StatelessWidget {
  const PageDots({
    super.key,
    required this.count,
    required this.active,
    this.padding = const EdgeInsets.only(top: 6),
  });

  final int count;
  final int active;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return ExcludeSemantics(
      child: Padding(
        padding: padding,
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
