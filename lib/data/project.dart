import 'package:flutter/foundation.dart';

/// Tautan luar sebuah proyek (Steam, halaman GGJ, Scratch).
@immutable
class ProjectLink {
  const ProjectLink({required this.label, required this.url});

  factory ProjectLink.fromJson(Map<String, dynamic> json) =>
      ProjectLink(label: json['label'] as String, url: json['url'] as String);

  final String label;
  final String url;
}

/// Satu proyek game. Sumber data: `assets/data/projects.json`
/// (disalin dari array `P` di `bahan/mockup/game-projects-mockup.html`).
@immutable
class Project {
  const Project({
    required this.id,
    required this.dir,
    required this.imageCount,
    required this.title,
    required this.year,
    required this.genre,
    this.tagGenre,
    required this.engine,
    this.language,
    required this.context,
    required this.contextLong,
    required this.platform,
    required this.team,
    required this.featured,
    this.summary,
    this.pixelArt = false,
    required this.roles,
    this.award,
    this.badge,
    required this.about,
    required this.contributions,
    required this.links,
  });

  factory Project.fromJson(Map<String, dynamic> json) => Project(
    id: json['id'] as String,
    dir: json['dir'] as String,
    imageCount: json['imageCount'] as int,
    title: json['title'] as String,
    year: json['year'] as int,
    genre: json['genre'] as String,
    tagGenre: json['tagGenre'] as String?,
    engine: json['engine'] as String,
    language: json['language'] as String?,
    context: json['context'] as String,
    contextLong: json['contextLong'] as String,
    platform: json['platform'] as String,
    team: json['team'] as String,
    featured: json['featured'] as bool? ?? false,
    summary: json['summary'] as String?,
    pixelArt: json['pixelArt'] as bool? ?? false,
    roles: List<String>.unmodifiable(json['roles'] as List),
    award: json['award'] as String?,
    badge: json['badge'] as String?,
    about: json['about'] as String,
    contributions: List<String>.unmodifiable(json['contributions'] as List),
    links: List<ProjectLink>.unmodifiable(
      (json['links'] as List).map(
        (e) => ProjectLink.fromJson(e as Map<String, dynamic>),
      ),
    ),
  );

  final String id;

  /// Nama folder gambar di `assets/projects/`.
  final String dir;

  /// Jumlah gambar galeri; gambar ke-0 adalah sampul.
  final int imageCount;

  final String title;
  final int year;

  /// Genre lengkap (subjudul detail: "genre · tahun").
  final String genre;

  /// Genre ringkas untuk tag kartu, bila berbeda dari [genre].
  final String? tagGenre;

  /// "Godot", "Unity", "LÖVE", atau "Scratch".
  final String engine;

  /// Bahasa pemrograman; null untuk Scratch.
  final String? language;

  /// Kategori filter: "Game Jam", "Komersial", "Pribadi", "Tugas Kelas".
  final String context;

  /// Teks ubin Konteks di detail.
  final String contextLong;

  final String platform;
  final String team;

  /// Termasuk 4 proyek unggulan Beranda.
  final bool featured;

  /// Deskripsi singkat kartu Featured Projects (maks. 2 baris).
  final String? summary;

  /// Gambar berupa pixel art: tampilkan tanpa penghalusan.
  final bool pixelArt;

  final List<String> roles;

  /// Teks penghargaan di detail (opsional).
  final String? award;

  /// Badge di atas sampul kartu (opsional).
  final String? badge;

  final String about;
  final List<String> contributions;
  final List<ProjectLink> links;

  /// Path gambar galeri ke-[index] (768×432, 16:9).
  String imagePath(int index) => 'assets/projects/$dir/$index.jpg';

  String get coverPath => imagePath(0);

  List<String> get imagePaths =>
      List.generate(imageCount, imagePath, growable: false);

  /// Tag kartu: engine, bahasa, genre ringkas, konteks.
  List<String> get tags => [engine, ?language, tagGenre ?? genre, context];

  /// Baris "Engine / bahasa" di Info Singkat, mis. "Unity · C#".
  String get engineLine => language == null ? engine : '$engine · $language';

  /// Baris kedua kartu: "tahun · peran".
  String get metaLine => '$year · ${roles.join(', ')}';
}
