import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/theme/theme_controller.dart';
import '../data/project_repository.dart';
import '../features/minigame/minigame_controller.dart';
import 'app_shell.dart';

/// Akar aplikasi "Ryal Naufal Portfolio".
class PortfolioApp extends StatelessWidget {
  PortfolioApp({
    super.key,
    required this.themeController,
    required this.projects,
    MiniGameController? miniGame,
  }) : miniGame = miniGame ?? MiniGameController.inMemory();

  final ThemeController themeController;
  final ProjectRepository projects;

  /// Status Mini Game. Tanpa nilai (pengujian): tanpa penyimpanan.
  final MiniGameController miniGame;

  @override
  Widget build(BuildContext context) {
    return ThemeScope(
      controller: themeController,
      child: ProjectsScope(
        repository: projects,
        child: MiniGameScope(controller: miniGame, child: _themedApp()),
      ),
    );
  }

  Widget _themedApp() {
    return ListenableBuilder(
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
    );
  }
}
