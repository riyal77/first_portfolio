import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/theme/theme_controller.dart';
import '../data/project_repository.dart';
import 'app_shell.dart';

/// Akar aplikasi "Ryal Naufal Portfolio".
class PortfolioApp extends StatelessWidget {
  const PortfolioApp({
    super.key,
    required this.themeController,
    required this.projects,
  });

  final ThemeController themeController;
  final ProjectRepository projects;

  @override
  Widget build(BuildContext context) {
    return ThemeScope(
      controller: themeController,
      child: ProjectsScope(
        repository: projects,
        child: ListenableBuilder(
          listenable: themeController,
          builder: (context, _) => MaterialApp(
            title: 'Ryal Naufal Portfolio',
            debugShowCheckedModeBanner: false,
            // Cadangan bila Android tetap membuat ulang Activity
            // (mis. proses dimatikan sistem saat di latar belakang).
            restorationScopeId: 'app',
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeController.mode,
            themeAnimationDuration: const Duration(milliseconds: 300),
            home: const AppShell(),
          ),
        ),
      ),
    );
  }
}
