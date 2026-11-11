import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/app.dart';
import 'core/theme/theme_controller.dart';
import 'data/project_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Tampil di belakang status bar & gesture bar (latar kaca App Banner/nav).
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Tema tersimpan dan data proyek dimuat sebelum frame pertama agar
  // tidak ada kedipan tema atau layar kosong.
  final (themeController, projects) = await (
    ThemeController.load(),
    ProjectRepository.load(),
  ).wait;

  runApp(PortfolioApp(themeController: themeController, projects: projects));
}
