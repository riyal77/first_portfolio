import 'package:flutter/material.dart';

/// Tiga keluarga font yang di-bundle (lihat pubspec.yaml).
///
/// - [pixel]  Pixelify Sans: judul, nama, judul kartu, paragraf panjang.
/// - [label]  Silkscreen: judul bagian & label kecil, huruf kapital.
/// - [body]   Plus Jakarta Sans: teks antarmuka lainnya.
abstract final class AppFonts {
  static const String pixel = 'PixelifySans';
  static const String label = 'Silkscreen';
  static const String body = 'PlusJakartaSans';
}

/// Pembuat [TextStyle] sesuai aturan tipografi mockup.
/// Warna sengaja opsional: bila kosong, ikut [DefaultTextStyle] (fg tema).
abstract final class AppText {
  /// Pixelify Sans. Bobot yang tersedia: 400, 500, 600.
  static TextStyle pixel(
    double size, {
    FontWeight weight = FontWeight.w400,
    Color? color,
    double? height,
    double? letterSpacing,
  }) => TextStyle(
    fontFamily: AppFonts.pixel,
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
  );

  /// Silkscreen, letter-spacing [spacing] em (default 0,08 em).
  /// Teks sebaiknya sudah ditulis kapital.
  static TextStyle label(
    double size, {
    Color? color,
    double spacing = 0.08,
    double? height,
  }) => TextStyle(
    fontFamily: AppFonts.label,
    fontSize: size,
    fontWeight: FontWeight.w400,
    color: color,
    height: height,
    letterSpacing: size * spacing,
  );

  /// Plus Jakarta Sans. Bobot 400–700, italic 400/500.
  static TextStyle body(
    double size, {
    FontWeight weight = FontWeight.w400,
    Color? color,
    double? height,
    FontStyle? style,
  }) => TextStyle(
    fontFamily: AppFonts.body,
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
    fontStyle: style,
  );

  /// Paragraf panjang bergaya pixel (bio About Me, paragraf & poin Detail
  /// Proyek): Pixelify 400, 15,5 px, line-height 1,55.
  static TextStyle paragraph({Color? color}) =>
      pixel(15.5, color: color, height: 1.55, letterSpacing: 15.5 * 0.01);
}
