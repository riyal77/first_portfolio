/// Nama ikon pixel 24×24 di `assets/icons/` (putih, diwarnai lewat `color:`).
enum PixelIcons {
  navHome('nav_home'),
  navProjects('nav_projects'),
  navAbout('nav_about'),
  navMiniGame('nav_minigame'),
  themeSun('theme_sun'),
  themeMoon('theme_moon'),
  back('back'),
  externalLink('external_link'),
  fullscreen('fullscreen'),
  close('close'),
  email('email'),
  trophy('trophy'),
  chevronRight('chevron_right'),
  eduUniversity('edu_university'),
  eduSchool('edu_school'),
  eduOnline('edu_online'),
  github('github'),
  instagram('instagram'),
  facebook('facebook');

  const PixelIcons(this.file);

  final String file;

  /// Ukuran sumber dalam piksel (varian 1x).
  static const int sourceSize = 24;

  String get path => 'assets/icons/$file.png';
}

/// Logo monokrom putih 96×96 di `assets/logos/`.
abstract final class AppLogos {
  static const String _dir = 'assets/logos';

  static const String godot = '$_dir/godot.png';
  static const String unity = '$_dir/unity.png';
  static const String love = '$_dir/love.png';
  static const String scratch = '$_dir/scratch.png';
  static const String csharp = '$_dir/csharp.png';
  static const String lua = '$_dir/lua.png';
  static const String cpp = '$_dir/cpp.png';
  static const String python = '$_dir/python.png';

  /// Logo untuk nama engine atau bahasa seperti tertulis di data proyek.
  /// GDScript memakai logo Godot.
  static String? forName(String name) => switch (name) {
        'Godot' || 'GDScript' => godot,
        'Unity' => unity,
        'LÖVE' => love,
        'Scratch' => scratch,
        'C#' => csharp,
        'Lua' => lua,
        'C++' => cpp,
        'Python' => python,
        _ => null,
      };
}

/// Gambar lain.
abstract final class AppImages {
  /// Avatar pixel 144×144, warnanya sudah dipetakan ke palet tiap tema.
  static const String avatarLight = 'assets/images/avatar_light.png';
  static const String avatarDark = 'assets/images/avatar_dark.png';
  static const int avatarSourceSize = 144;
}
