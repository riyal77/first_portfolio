import '../../core/assets/app_assets.dart';

/// Teks dan data statis Beranda (sumber: mockup Beranda + dokumen Rencana).
abstract final class HomeContent {
  static const String name = 'Ryal Naufal';
  static const String role = 'GAME PROGRAMMER';
  static const String tagline =
      '“Great games are born from their makers’ unrest.”';
  static const String description =
      'Game programmer sekaligus game designer. Aku senang menyelami '
      'pemrograman game sampai ke dasarnya, dari game engine hingga game '
      'framework, demi game yang optimal. Bersama tim, memenangkan Best Story '
      '& Best Illustration di Global Game Jam 2024.';

  static const List<SocialLink> socials = [
    SocialLink(PixelIcons.github, 'GitHub', 'https://github.com/riyal77'),
    SocialLink(
      PixelIcons.instagram,
      'Instagram',
      'https://www.instagram.com/ryalnaufal/',
    ),
    SocialLink(
      PixelIcons.facebook,
      'Facebook',
      'https://web.facebook.com/ryal.naufal/',
    ),
    SocialLink(PixelIcons.email, 'Email', 'mailto:ryal_naufal@yahoo.com'),
  ];

  /// Kartu GGJ 2024 di urutan pertama, lalu 7 alat yang dipakai untuk game.
  /// C++ dan Python hanya di About Me.
  static const List<SkillItem> skills = [
    SkillItem(
      'Juara GGJ 2024',
      'Best Story & Illustration',
      icon: PixelIcons.trophy,
      award: true,
    ),
    SkillItem('Godot', 'Engine', logo: AppLogos.godot),
    SkillItem('Unity', 'Engine', logo: AppLogos.unity),
    SkillItem('LÖVE', 'Engine', logo: AppLogos.love),
    SkillItem('Scratch', 'Engine', logo: AppLogos.scratch),
    SkillItem('GDScript', 'Bahasa', logo: AppLogos.godot),
    SkillItem('C#', 'Bahasa', logo: AppLogos.csharp),
    SkillItem('Lua', 'Bahasa', logo: AppLogos.lua),
  ];

  static const String ctaTitle = 'Ingin mencoba permainan seru?';
  static const String ctaBody =
      'Coba game orisinal buatanku, langsung di aplikasi ini.';
  static const String ctaButton = 'MAIN SEKARANG';
}

class SocialLink {
  const SocialLink(this.icon, this.label, this.url);

  final PixelIcons icon;
  final String label;
  final String url;
}

class SkillItem {
  const SkillItem(
    this.name,
    this.subtitle, {
    this.logo,
    this.icon,
    this.award = false,
  });

  final String name;
  final String subtitle;

  /// Logo monokrom 96×96 (engine/bahasa).
  final String? logo;

  /// Ikon pixel (kartu penghargaan).
  final PixelIcons? icon;

  /// Kartu penghargaan: latar `btn`.
  final bool award;
}
