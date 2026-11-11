import 'package:flutter/material.dart';

import '../../../core/assets/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/pixel_image.dart';
import '../home_content.dart';

/// Kotak ajakan Mini Game. [horizontal]: ikon, teks, dan tombol sebaris
/// (HP landscape & tablet); selain itu tombol selebar kotak di bawah teks.
class MiniGameCta extends StatelessWidget {
  const MiniGameCta({super.key, required this.onPlay, this.horizontal = false});

  final VoidCallback onPlay;
  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final icon = Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: c.bg,
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: PixelIcon(PixelIcons.navMiniGame, size: 28, color: c.fg),
    );
    final texts = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2, bottom: 4),
          child: Text(
            HomeContent.ctaTitle,
            style: AppText.pixel(
              18,
              weight: FontWeight.w600,
              height: 1.15,
              color: c.fg,
            ),
          ),
        ),
        Text(
          HomeContent.ctaBody,
          style: AppText.body(13, height: 1.5, color: c.fg2),
        ),
      ],
    );
    final button = _PlayButton(onPressed: onPlay, expand: !horizontal);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: c.cardShadow,
      ),
      child: horizontal
          ? Row(
              children: [
                icon,
                const SizedBox(width: 14),
                Expanded(child: texts),
                const SizedBox(width: 14),
                button,
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    icon,
                    const SizedBox(width: 14),
                    Expanded(child: texts),
                  ],
                ),
                const SizedBox(height: 14),
                button,
              ],
            ),
    );
  }
}

class _PlayButton extends StatelessWidget {
  const _PlayButton({required this.onPressed, required this.expand});

  final VoidCallback onPressed;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return DecoratedBox(
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
          onTap: onPressed,
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            height: 48,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    HomeContent.ctaButton,
                    style: AppText.label(13, color: c.onBtn, spacing: 0.06),
                  ),
                  const SizedBox(width: 6),
                  PixelIcon(PixelIcons.chevronRight, size: 16, color: c.onBtn),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
