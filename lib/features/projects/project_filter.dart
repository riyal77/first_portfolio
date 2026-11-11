import 'package:flutter/foundation.dart';

import '../../core/assets/app_assets.dart';
import '../../data/project.dart';

/// Jenis filter: engine atau konteks proyek.
enum FilterKind { engine, context }

/// Satu chip filter. [kind] null = "Semua".
@immutable
class ProjectFilter {
  const ProjectFilter(this.label, [this.kind, this.logo]);

  final String label;
  final FilterKind? kind;

  /// Logo engine di depan label (hanya chip engine).
  final String? logo;

  bool get isAll => kind == null;

  bool matches(Project p) => switch (kind) {
    null => true,
    FilterKind.engine => p.engine == label,
    FilterKind.context => p.context == label,
  };

  @override
  bool operator ==(Object other) =>
      other is ProjectFilter && other.label == label && other.kind == kind;

  @override
  int get hashCode => Object.hash(label, kind);

  static const all = ProjectFilter('Semua');

  /// Grup chip sesuai mockup: Semua | engine | konteks.
  static const List<List<ProjectFilter>> groups = [
    [all],
    [
      ProjectFilter('Godot', FilterKind.engine, AppLogos.godot),
      ProjectFilter('Unity', FilterKind.engine, AppLogos.unity),
      ProjectFilter('LÖVE', FilterKind.engine, AppLogos.love),
      ProjectFilter('Scratch', FilterKind.engine, AppLogos.scratch),
    ],
    [
      ProjectFilter('Game Jam', FilterKind.context),
      ProjectFilter('Komersial', FilterKind.context),
      ProjectFilter('Pribadi', FilterKind.context),
      ProjectFilter('Tugas Kelas', FilterKind.context),
    ],
  ];

  /// Teks jumlah di App Banner: "7 proyek" / "2 dari 7 proyek · Godot".
  static String countLabel(ProjectFilter filter, int shown, int total) =>
      filter.isAll
      ? '$total proyek'
      : '$shown dari $total proyek · ${filter.label}';
}
