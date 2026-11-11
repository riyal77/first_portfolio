import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'project.dart';

/// Memuat dan menyediakan data 7 proyek (urutan tampil sesuai JSON).
class ProjectRepository {
  const ProjectRepository(this.projects);

  static const assetPath = 'assets/data/projects.json';

  final List<Project> projects;

  /// 4 proyek unggulan untuk Beranda.
  List<Project> get featured =>
      projects.where((p) => p.featured).toList(growable: false);

  Project byId(String id) => projects.firstWhere((p) => p.id == id);

  static Future<ProjectRepository> load([AssetBundle? bundle]) async {
    final raw = await (bundle ?? rootBundle).loadString(assetPath);
    return ProjectRepository.parse(raw);
  }

  static ProjectRepository parse(String raw) {
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final list = (json['projects'] as List)
        .map((e) => Project.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
    return ProjectRepository(list);
  }
}

/// Menyediakan [ProjectRepository] ke seluruh pohon widget.
class ProjectsScope extends InheritedWidget {
  const ProjectsScope({
    super.key,
    required this.repository,
    required super.child,
  });

  final ProjectRepository repository;

  static ProjectRepository of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ProjectsScope>()!.repository;

  @override
  bool updateShouldNotify(ProjectsScope oldWidget) =>
      repository != oldWidget.repository;
}
