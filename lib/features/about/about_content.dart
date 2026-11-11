import '../../core/assets/app_assets.dart';

/// Teks dan data About Me (sumber: mockup `about-mockup.html`).
abstract final class AboutContent {
  static const String name = 'Ryal Naufal';
  static const String role = 'GAME PROGRAMMER';
  static const String tagline =
      '“Great games are born from their makers’ unrest.”';

  static const List<String> bio = [
    'Sejak kecil aku sudah tertarik pada video game. Saat remaja, '
        'ketertarikan itu meluas ke sejarah dan industri di baliknya. '
        'Perjalananku dimulai di Arsitektur. Dari sana aku membawa kepekaan '
        'terhadap ruang, sirkulasi, dan perilaku manusia, yang kini menjadi '
        'modalku dalam level design, juga kebiasaan untuk selalu melahirkan '
        'konsep yang orisinal. Arsitektur mengajarkanku bahwa setiap karya '
        'membawa rasa. Karena itu aku percaya game adalah media untuk '
        'menyampaikan perasaan paling jujur pembuatnya, dan perasaan paling '
        'jujur lahir dari keresahan.',
    'Ambisi untuk suatu hari membuat game impianku sendiri membawaku pindah '
        'ke Informatika. Aku senang menyelami pemrograman game sampai ke '
        'dasarnya, dari game engine hingga game framework, karena bagiku kode '
        'bukan sekadar membuat game berjalan: arsitektur dan strukturnya '
        'adalah seni tersendiri untuk memberikan pengalaman terbaik bagi '
        'pemain. Target berikutnya: merilis game karyaku sendiri di Steam.',
  ];

  /// Kemampuan; penekanan hanya lewat bentuk kartu (lihat [SkillWeight]).
  static const List<Skill> skills = [
    Skill(
      'Programming',
      ['Game System', 'Game Mechanics', 'UI Programming'],
      'Semua proyek',
      SkillWeight.main,
    ),
    Skill(
      'Game Design',
      ['Game Design', 'Level Design', 'Enemy Design'],
      'Project Musafa · Rhythm Space Bar',
      SkillWeight.plus,
    ),
    Skill(
      'Art',
      ['Sprite', 'UI Art', 'Animasi'],
      'Project Musafa · Rhythm Space Bar',
      SkillWeight.extra,
    ),
  ];

  static const List<Tool> engines = [
    Tool('Godot', [AppLogos.godot], ['Project Musafa', 'Jamal the Bubble Bug']),
    Tool('Unity', [AppLogos.unity], ['Jump of Icarus', 'Purwodaddy']),
    Tool('LÖVE', [AppLogos.love], ['Fifty Bird', 'Breakout Clone']),
    Tool('Scratch', [AppLogos.scratch], ['Rhythm Space Bar']),
  ];

  static const List<Tool> languages = [
    Tool(
      'GDScript',
      [AppLogos.godot],
      ['Project Musafa', 'Jamal the Bubble Bug'],
    ),
    Tool('C#', [AppLogos.csharp], ['Jump of Icarus', 'Purwodaddy']),
    Tool('Lua', [AppLogos.lua], ['Fifty Bird', 'Breakout Clone']),
    Tool(
      'C++ · Python',
      [AppLogos.cpp, AppLogos.python],
      [],
      note: 'Dipakai untuk tugas kuliah dan proyek di luar game.',
    ),
  ];

  static const List<String> designTools = ['Aseprite', 'CorelDRAW'];

  /// Terbaru di atas.
  static const List<JourneyItem> journey = [
    JourneyItem(
      '2025',
      '23Mil Studio',
      'Game Programmer (pekerja lepas) · Jump of Icarus',
    ),
    JourneyItem(
      '2025',
      'Global Game Jam · Bandung',
      'Peserta · Jamal the Bubble Bug',
    ),
    JourneyItem(
      '2024',
      'Global Game Jam · Bogor',
      'Purwodaddy',
      award: 'BEST STORY & BEST ILLUSTRATION',
    ),
  ];

  static const List<EducationGroup> education = [
    EducationGroup('Universitas', [
      EducationItem(
        PixelIcons.eduUniversity,
        'S1 Informatika',
        'Universitas Bhayangkara Jakarta Raya',
      ),
      EducationItem(
        PixelIcons.eduUniversity,
        'S1 Arsitektur',
        'Universitas Sebelas Maret (UNS)',
      ),
    ]),
    EducationGroup('Sekolah', [
      EducationItem(PixelIcons.eduSchool, 'SMA', 'SMAN 2 Kota Bekasi'),
    ]),
    EducationGroup('Non-formal', [
      EducationItem(
        PixelIcons.eduOnline,
        'CS50 2D',
        'Kelas daring Harvard · pemrograman game',
      ),
      EducationItem(
        PixelIcons.eduOnline,
        'CS50x',
        'Kelas daring Harvard · dasar pemrograman',
      ),
    ]),
  ];
}

/// Bentuk kartu kemampuan: bingkai tebal (utama), kartu surface (biasa),
/// garis putus-putus tanpa latar (pelengkap).
enum SkillWeight { main, plus, extra }

class Skill {
  const Skill(this.title, this.tags, this.proof, this.weight);

  final String title;
  final List<String> tags;

  /// Baris bawah kartu: judul game.
  final String proof;
  final SkillWeight weight;
}

class Tool {
  const Tool(this.name, this.logos, this.projects, {this.note});

  final String name;
  final List<String> logos;

  /// Judul proyek (teks biasa, bukan tombol).
  final List<String> projects;

  /// Keterangan pengganti daftar proyek (C++ · Python).
  final String? note;
}

class JourneyItem {
  const JourneyItem(this.year, this.title, this.subtitle, {this.award});

  final String year;
  final String title;
  final String subtitle;
  final String? award;
}

class EducationGroup {
  const EducationGroup(this.label, this.items);

  final String label;
  final List<EducationItem> items;
}

class EducationItem {
  const EducationItem(this.icon, this.level, this.school);

  final PixelIcons icon;

  /// Jenjang (S1 Informatika, SMA, CS50 2D, …), Pixelify.
  final String level;
  final String school;
}
