import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/assets/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/pixel_image.dart';
import '../../../core/widgets/project_widgets.dart';
import '../../../data/project.dart';

/// Galeri geser 16:9: penanda "1 / n" di kanan bawah, tombol layar penuh di
/// kanan atas, lalu titik (HP) atau strip thumbnail (tablet) di bawahnya.
/// Mengetuk gambar membuka galeri layar penuh.
class ProjectGallery extends StatelessWidget {
  const ProjectGallery({
    super.key,
    required this.project,
    required this.controller,
    required this.index,
    required this.onFullscreen,
    this.thumbnails = false,
  });

  final Project project;
  final PageController controller;
  final ValueNotifier<int> index;
  final ValueChanged<int> onFullscreen;

  /// Tablet: strip thumbnail (bingkai tebal = gambar aktif) sebagai ganti
  /// titik.
  final bool thumbnails;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final n = project.imageCount;
    final gallery = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: c.shadow1,
            offset: const Offset(0, 1),
            blurRadius: 2,
          ),
          BoxShadow(
            color: c.shadow2,
            offset: const Offset(0, 14),
            blurRadius: 28,
            spreadRadius: -16,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(color: c.raised),
              PageView.builder(
                key: ValueKey(project.id),
                controller: controller,
                itemCount: n,
                onPageChanged: (i) => index.value = i,
                itemBuilder: (context, i) => Semantics(
                  image: true,
                  button: true,
                  label: '${project.title}, gambar ${i + 1} dari $n',
                  child: GestureDetector(
                    onTap: () => onFullscreen(i),
                    child: ProjectImage(project, i),
                  ),
                ),
              ),
              Positioned(
                right: 10,
                bottom: 10,
                child: IgnorePointer(
                  child: ValueListenableBuilder<int>(
                    valueListenable: index,
                    builder: (_, i, _) => GalleryCounter('${i + 1} / $n'),
                  ),
                ),
              ),
              Positioned(
                right: 10,
                top: 10,
                child: _FullscreenButton(
                  onTap: () => onFullscreen(index.value),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        gallery,
        ValueListenableBuilder<int>(
          valueListenable: index,
          builder: (_, i, _) => thumbnails
              ? _Thumbnails(
                  project: project,
                  active: i,
                  onTap: (t) => controller.animateToPage(
                    t,
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOutCubic,
                  ),
                )
              : PageDots(
                  count: n,
                  active: i,
                  padding: const EdgeInsets.only(top: 12),
                ),
        ),
      ],
    );
  }
}

/// Penanda "1 / n" di atas gambar.
class GalleryCounter extends StatelessWidget {
  const GalleryCounter(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xB8111111),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        text,
        style: AppText.label(
          10,
          color: AppColors.paper,
          spacing: 0.04,
        ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
      ),
    );
  }
}

class _FullscreenButton extends StatelessWidget {
  const _FullscreenButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Lihat galeri layar penuh',
      excludeSemantics: true,
      child: Material(
        color: const Color(0x99111111),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: const SizedBox.square(
            dimension: 32,
            child: Center(
              child: PixelIcon(
                PixelIcons.fullscreen,
                size: 16,
                color: AppColors.paper,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Thumbnails extends StatelessWidget {
  const _Thumbnails({
    required this.project,
    required this.active,
    required this.onTap,
  });

  final Project project;
  final int active;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (var i = 0; i < project.imageCount; i++)
            Semantics(
              button: true,
              selected: i == active,
              label: 'Gambar ${i + 1}',
              excludeSemantics: true,
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onTap(i);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 80,
                  height: 45,
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: i == active ? c.fg : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: Opacity(
                      opacity: i == active ? 1 : 0.7,
                      child: ProjectImage(project, i),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
