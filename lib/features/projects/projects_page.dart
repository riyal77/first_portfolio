import 'package:flutter/material.dart';

import '../../core/widgets/placeholder_page.dart';
import '../../data/project_repository.dart';

/// Game Projects. Sementara placeholder; dibangun di branch `gameProjects`.
class ProjectsPage extends StatelessWidget {
  const ProjectsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final count = ProjectsScope.of(context).projects.length;
    return PlaceholderPage(
      title: 'Game Projects',
      subtitle: '$count proyek',
      message: 'Halaman Game Projects dibangun di branch gameProjects.',
      storageKey: 'projects',
    );
  }
}
