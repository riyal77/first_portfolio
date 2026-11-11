import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../assets/app_assets.dart';
import '../theme/app_colors.dart';

/// Menghitung ukuran logis agar gambar pixel [sourcePx] digambar dengan
/// skala bilangan bulat di layar (tiap piksel sumber = k×k piksel fisik),
/// sedekat mungkin dengan [target] logis.
double snapPixelSize(double target, int sourcePx, double devicePixelRatio) {
  final k = math.max(1, (target * devicePixelRatio / sourcePx).round());
  return k * sourcePx / devicePixelRatio;
}

/// Gambar pixel art yang selalu tajam: sumber 1x dimuat apa adanya,
/// digambar tanpa penghalusan ([FilterQuality.none]) dengan skala bulat.
class PixelImage extends StatelessWidget {
  const PixelImage(
    this.asset, {
    super.key,
    required this.sourceSize,
    required this.size,
    this.color,
    this.snap = true,
    this.semanticLabel,
  });

  final String asset;
  final int sourceSize;

  /// Ukuran logis yang diinginkan (persegi).
  final double size;

  /// Pewarnaan (untuk ikon/logo putih). Null = warna asli.
  final Color? color;

  /// Bulatkan ukuran ke kelipatan piksel sumber.
  final bool snap;

  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final s = snap ? snapPixelSize(size, sourceSize, dpr) : size;
    return Image.asset(
      asset,
      // scale: 1 memaksa varian 1x (24×24) sehingga pembesaran selalu bulat.
      scale: 1,
      width: s,
      height: s,
      color: color,
      filterQuality: FilterQuality.none,
      isAntiAlias: false,
      semanticLabel: semanticLabel,
      excludeFromSemantics: semanticLabel == null,
      gaplessPlayback: true,
    );
  }
}

/// Ikon pixel 24×24, default berwarna fg tema.
class PixelIcon extends StatelessWidget {
  const PixelIcon(
    this.icon, {
    super.key,
    this.size = 24,
    this.color,
    this.semanticLabel,
  });

  final PixelIcons icon;
  final double size;
  final Color? color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = color ?? IconTheme.of(context).color ?? AppColors.of(context).fg;
    return PixelImage(
      icon.path,
      sourceSize: PixelIcons.sourceSize,
      size: size,
      color: c,
      semanticLabel: semanticLabel,
    );
  }
}
