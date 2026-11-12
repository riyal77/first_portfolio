import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/app.dart';
import 'core/theme/theme_controller.dart';
import 'data/project_repository.dart';
import 'features/minigame/minigame_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Tampil di belakang status bar & gesture bar (latar kaca App Banner/nav).
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Tema tersimpan, data proyek, dan status Mini Game dimuat sebelum frame
  // pertama agar tidak ada kedipan tema, layar kosong, atau layar ajakan
  // yang sempat tampil sebelum layar kontak.
  final (themeController, projects, miniGame) = await (
    ThemeController.load(),
    ProjectRepository.load(),
    MiniGameController.load(),
  ).wait;

  runApp(
    PortfolioApp(
      themeController: themeController,
      projects: projects,
      miniGame: miniGame,
    ),
  );
}
