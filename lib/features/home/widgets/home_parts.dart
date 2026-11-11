import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/assets/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/pixel_image.dart';
import '../home_content.dart';

/// Pita dither pixel 3 tingkat (25/50/75%, sel 2 px) yang menutup hero:
/// peralihan dari `surface` kembali ke `bg`.
class DitherBand extends StatelessWidget {
  const DitherBand({super.key});

  static const double height = 12;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(painter: _DitherPainter(AppColors.of(context).bg)),
    );
  }
}

class _DitherPainter extends CustomPainter {
  _DitherPainter(this.color);

  final Color color;

  static const double _cell = 2;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..isAntiAlias = false;
    final path = Path();
    // Tiap baris setinggi 4 px = 2 sel; ubin 4×4 berisi 4 sel 2×2.
    // Baris 1: 25% (sel kanan atas). Baris 2: 50% (kanan atas + kiri bawah).
    // Baris 3: 75% (semua kecuali kiri atas).
    for (var row = 0; row < 3; row++) {
      final y0 = row * 2 * _cell;
      for (var x = 0.0; x < size.width; x += 2 * _cell) {
        void cell(int cx, int cy) => path.addRect(
          Rect.fromLTWH(x + cx * _cell, y0 + cy * _cell, _cell, _cell),
        );
        switch (row) {
          case 0:
            cell(1, 0);
          case 1:
            cell(1, 0);
            cell(0, 1);
          default:
            cell(1, 0);
            cell(0, 1);
            cell(1, 1);
        }
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_DitherPainter oldDelegate) => oldDelegate.color != color;
}

/// Kotak avatar pixel: latar `surface`, sudut [radius], gambar 86% dari sisi
/// terpendek, tanpa penghalusan. Avatar sudah dipetakan ke palet tiap tema.
class AvatarBox extends StatelessWidget {
  const AvatarBox({
    super.key,
    required this.width,
    this.height,
    this.radius = 14,
  });

  final double width;

  /// Null = mengikuti tinggi dari induk (mis. foto potret setinggi kolom
  /// teks di tablet); gambar lalu diukur dari [width].
  final double? height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final h = height ?? width;
    final img = (width < h ? width : h) * 0.86;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: c.shadow1,
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
          BoxShadow(
            color: c.shadow2,
            offset: const Offset(0, 14),
            blurRadius: 28,
            spreadRadius: -12,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Image.asset(
        dark ? AppImages.avatarDark : AppImages.avatarLight,
        width: img.roundToDouble(),
        height: img.roundToDouble(),
        filterQuality: FilterQuality.none,
        isAntiAlias: false,
        gaplessPlayback: true,
        excludeFromSemantics: true,
      ),
    );
  }
}

/// Deretan tombol sosial ikon-saja (GitHub, Instagram, Facebook, Email).
class SocialButtons extends StatelessWidget {
  const SocialButtons({
    super.key,
    this.size = 52,
    this.iconSize = 24,
    this.gap = 12,
    this.radius = 12,
  });

  final double size;
  final double iconSize;
  final double gap;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < HomeContent.socials.length; i++) ...[
          if (i > 0) SizedBox(width: gap),
          _SocialButton(
            link: HomeContent.socials[i],
            size: size,
            iconSize: iconSize,
            radius: radius,
            colors: c,
          ),
        ],
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.link,
    required this.size,
    required this.iconSize,
    required this.radius,
    required this.colors,
  });

  final SocialLink link;
  final double size;
  final double iconSize;
  final double radius;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    final c = colors;
    return Semantics(
      button: true,
      link: true,
      label: link.label,
      excludeSemantics: true,
      child: Tooltip(
        message: link.label,
        excludeFromSemantics: true,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            boxShadow: [
              BoxShadow(
                color: c.shadow1,
                offset: const Offset(0, 1),
                blurRadius: 2,
              ),
              BoxShadow(
                color: c.shadow2,
                offset: const Offset(0, 6),
                blurRadius: 14,
                spreadRadius: -6,
              ),
            ],
          ),
          child: Material(
            color: c.bg,
            borderRadius: BorderRadius.circular(radius),
            child: InkWell(
              borderRadius: BorderRadius.circular(radius),
              onTap: () => openExternal(link.url),
              child: SizedBox.square(
                dimension: size,
                child: Center(
                  child: PixelIcon(link.icon, size: iconSize, color: c.fg),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Membuka tautan di aplikasi luar (browser, aplikasi email).
Future<void> openExternal(String url) async {
  try {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  } catch (_) {
    // Tidak ada aplikasi yang bisa membuka tautan: abaikan.
  }
}

/// Judul bagian (Silkscreen 13) dengan keterangan kecil di kanan
/// (mis. "GESER ›" atau "1 / 4").
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.trailing, this.padding});

  final String title;
  final Widget? trailing;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Padding(
      padding: padding ?? const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(title, style: AppText.label(13, color: c.fg)),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Teks kecil di kanan judul bagian.
class SectionHint extends StatelessWidget {
  const SectionHint(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppText.label(
        10,
        color: AppColors.of(context).fg2,
        spacing: 0.06,
      ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
    );
  }
}
