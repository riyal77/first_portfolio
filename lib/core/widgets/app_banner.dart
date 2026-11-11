import 'package:flutter/material.dart';

import '../assets/app_assets.dart';
import '../layout/device_layout.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import 'glass.dart';
import 'pixel_image.dart';
import 'theme_toggle_button.dart';

/// App Banner berlatar kaca di atas halaman: [leading] di kiri, tombol tema
/// di kanan atas. Tinggi: 64 (HP portrait & tablet), 56 (HP landscape),
/// 52 (layar depan Flip), ditambah status bar.
///
/// Letakkan di dalam `Stack` di atas konten yang di-scroll; konten diberi
/// jarak atas sebesar [AppBanner.totalHeight].
class AppBanner extends StatelessWidget {
  const AppBanner({super.key, required this.leading, this.showGlass = true});

  final Widget leading;

  /// Latar kaca bisa dimatikan (mis. untuk morphing Beranda).
  final bool showGlass;

  /// Tinggi total banner termasuk status bar.
  static double totalHeight(BuildContext context) =>
      MediaQuery.paddingOf(context).top + DeviceLayout.of(context).bannerHeight;

  @override
  Widget build(BuildContext context) {
    final layout = DeviceLayout.of(context);
    final top = MediaQuery.paddingOf(context).top;
    final row = Padding(
      padding: EdgeInsets.only(
        top: top,
        left: 20,
        right: layout.isLandscape ? 10 : 12,
      ),
      child: SizedBox(
        height: layout.bannerHeight,
        child: Row(
          children: [
            Expanded(child: leading),
            const SizedBox(width: 12),
            const ThemeToggleButton(),
          ],
        ),
      ),
    );
    if (!showGlass) return row;
    return Glass(
      border: Border(
        bottom: BorderSide(color: AppColors.of(context).glassLine),
      ),
      child: row,
    );
  }
}

/// Judul halaman di App Banner, dengan keterangan kecil opsional
/// (mis. "Game Projects" + "7 proyek").
class BannerTitle extends StatelessWidget {
  const BannerTitle(this.title, {super.key, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final layout = DeviceLayout.of(context);
    final size = switch (layout) {
      DeviceLayout.phoneLandscape => 22.0,
      DeviceLayout.flipCover => 20.0,
      _ => 24.0,
    };
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.pixel(
              size,
              weight: FontWeight.w600,
              height: 1.05,
              color: c.fg,
            ),
          ),
        ),
        if (subtitle != null)
          Padding(
            padding: EdgeInsets.only(top: layout.isLandscape ? 2 : 3),
            child: Text(
              subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.body(
                12.5,
                color: c.fg2,
              ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
            ),
          ),
      ],
    );
  }
}

/// Tombol Kembali tanpa bingkai: panah pixel + "Kembali"
/// (Pixelify 600, 17 px).
class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: Transform.translate(
        offset: const Offset(-8, 0),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              height: 44,
              child: Padding(
                padding: const EdgeInsets.only(left: 8, right: 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PixelIcon(PixelIcons.back, size: 22, color: c.fg),
                    const SizedBox(width: 6),
                    Text(
                      'Kembali',
                      style: AppText.pixel(
                        17,
                        weight: FontWeight.w600,
                        color: c.fg,
                        letterSpacing: 0.17,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
