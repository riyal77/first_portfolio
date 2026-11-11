import 'package:flutter/material.dart';

/// Token warna "monokrom hangat" (lihat CLAUDE.md > Design system > Warna).
///
/// Dipasang sebagai [ThemeExtension] sehingga bisa diambil di mana saja lewat
/// `AppColors.of(context)` dan ikut beranimasi saat tema berganti.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.bg,
    required this.surface,
    required this.raised,
    required this.tag,
    required this.line,
    required this.fg,
    required this.fg2,
    required this.muted,
    required this.btn,
    required this.onBtn,
    required this.glass,
    required this.glassLine,
    required this.shadow1,
    required this.shadow2,
    required this.shine,
  });

  /// Latar dasar.
  final Color bg;

  /// Latar kartu.
  final Color surface;

  /// Placeholder / latar gambar yang belum dimuat.
  final Color raised;

  /// Latar tag.
  final Color tag;

  /// Garis pemisah.
  final Color line;

  /// Teks utama.
  final Color fg;

  /// Teks sekunder.
  final Color fg2;

  /// Ikon nonaktif. Jangan dipakai untuk paragraf (kontras 4,1:1).
  final Color muted;

  /// Latar tombol utama dan teks/ikon di atasnya.
  final Color btn;
  final Color onBtn;

  /// Kaca buram (App Banner, navigation bar/rail, tombol tema mengambang).
  final Color glass;
  final Color glassLine;

  /// Bayangan lembut: [shadow1] tipis dekat, [shadow2] lebar jauh.
  final Color shadow1;
  final Color shadow2;

  /// Kilau 1 px di tepi atas kartu.
  final Color shine;

  // Warna tetap yang sama di kedua tema.
  static const Color ink = Color(0xFF111111);
  static const Color paper = Color(0xFFF6F4EE);

  /// Badge di atas gambar: selalu #111111 82% + teks [paper].
  static const Color badge = Color(0xD1111111);

  static const AppColors light = AppColors(
    bg: Color(0xFFF6F4EE),
    surface: Color(0xFFE6E1D7),
    raised: Color(0xFFBEB8AD),
    tag: Color(0xFFD3CDC2),
    line: Color(0xFFBEB8AD),
    fg: Color(0xFF111111),
    fg2: Color(0xFF5E5B55),
    muted: Color(0xFF777777),
    btn: Color(0xFF111111),
    onBtn: Color(0xFFF6F4EE),
    glass: Color(0xBFF6F4EE), // 75%
    glassLine: Color(0x14111111), // 8%
    shadow1: Color(0x0F111111), // 6%
    shadow2: Color(0x1F111111), // 12%
    shine: Color(0x8CFFFFFF), // 55%
  );

  static const AppColors dark = AppColors(
    bg: Color(0xFF111111),
    surface: Color(0xFF1C1B19),
    raised: Color(0xFF2A2826),
    tag: Color(0xFF2E2C29),
    line: Color(0xFF333333),
    fg: Color(0xFFF6F4EE),
    fg2: Color(0xFFBEB8AD),
    muted: Color(0xFF9C978E),
    btn: Color(0xFFF6F4EE),
    onBtn: Color(0xFF111111),
    glass: Color(0xB3111111), // 70%
    glassLine: Color(0x14F6F4EE), // 8%
    shadow1: Color(0x4D000000), // 30%
    shadow2: Color(0x73000000), // 45%
    shine: Color(0x0FFFFFFF), // 6%
  );

  static AppColors of(BuildContext context) =>
      Theme.of(context).extension<AppColors>()!;

  /// Bayangan lembut berlapis untuk kartu (setara CSS mockup:
  /// `0 1px 0 shine inset, 0 1px 2px sh1, 0 10px 24px -14px sh2`).
  List<BoxShadow> get cardShadow => [
    BoxShadow(color: shadow1, offset: const Offset(0, 1), blurRadius: 2),
    BoxShadow(
      color: shadow2,
      offset: const Offset(0, 10),
      blurRadius: 24,
      spreadRadius: -14,
    ),
  ];

  @override
  AppColors copyWith({
    Color? bg,
    Color? surface,
    Color? raised,
    Color? tag,
    Color? line,
    Color? fg,
    Color? fg2,
    Color? muted,
    Color? btn,
    Color? onBtn,
    Color? glass,
    Color? glassLine,
    Color? shadow1,
    Color? shadow2,
    Color? shine,
  }) {
    return AppColors(
      bg: bg ?? this.bg,
      surface: surface ?? this.surface,
      raised: raised ?? this.raised,
      tag: tag ?? this.tag,
      line: line ?? this.line,
      fg: fg ?? this.fg,
      fg2: fg2 ?? this.fg2,
      muted: muted ?? this.muted,
      btn: btn ?? this.btn,
      onBtn: onBtn ?? this.onBtn,
      glass: glass ?? this.glass,
      glassLine: glassLine ?? this.glassLine,
      shadow1: shadow1 ?? this.shadow1,
      shadow2: shadow2 ?? this.shadow2,
      shine: shine ?? this.shine,
    );
  }

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColors(
      bg: l(bg, other.bg),
      surface: l(surface, other.surface),
      raised: l(raised, other.raised),
      tag: l(tag, other.tag),
      line: l(line, other.line),
      fg: l(fg, other.fg),
      fg2: l(fg2, other.fg2),
      muted: l(muted, other.muted),
      btn: l(btn, other.btn),
      onBtn: l(onBtn, other.onBtn),
      glass: l(glass, other.glass),
      glassLine: l(glassLine, other.glassLine),
      shadow1: l(shadow1, other.shadow1),
      shadow2: l(shadow2, other.shadow2),
      shine: l(shine, other.shine),
    );
  }
}
