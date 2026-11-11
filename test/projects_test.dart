import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:first_portfolio/app/app.dart';
import 'package:first_portfolio/app/app_shell.dart';
import 'package:first_portfolio/core/theme/theme_controller.dart';
import 'package:first_portfolio/core/widgets/app_navigation.dart';
import 'package:first_portfolio/data/project_repository.dart';
import 'package:first_portfolio/features/projects/projects_page.dart';
import 'package:first_portfolio/features/projects/widgets/filter_bar.dart';
import 'package:first_portfolio/features/projects/widgets/gallery_lightbox.dart';
import 'package:first_portfolio/features/projects/widgets/project_detail_view.dart';

Future<void> _pumpApp(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    PortfolioApp(
      themeController: ThemeController.inMemory(ThemeMode.light),
      projects: ProjectRepository.parse(
        File(ProjectRepository.assetPath).readAsStringSync(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _goToProjects(WidgetTester tester) async {
  await tester.tap(find.bySemanticsLabel('Proyek'));
  await tester.pumpAndSettle();
}

Finder get _page => find.byType(ProjectsPage);

Finder _inPage(Finder f) => find.descendant(of: _page, matching: f);

Future<void> _openCard(WidgetTester tester, String title) async {
  final card = _inPage(find.text(title)).first;
  // Ke tengah layar: tepi atas tertutup App Banner dan filter.
  await Scrollable.ensureVisible(tester.element(card), alignment: 0.5);
  await tester.pumpAndSettle();
  await tester.tap(card);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Filter: jumlah di banner ikut filter, Semua mengembalikan', (
    tester,
  ) async {
    await _pumpApp(tester, const Size(402, 874));
    await _goToProjects(tester);
    expect(find.text('7 proyek'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Filter Godot'));
    await tester.pumpAndSettle();
    expect(find.text('2 dari 7 proyek · Godot'), findsOneWidget);
    expect(_inPage(find.text('Project Musafa')), findsOneWidget);
    expect(_inPage(find.text('Purwodaddy')), findsNothing);

    await tester.tap(find.bySemanticsLabel('Filter Semua'));
    await tester.pumpAndSettle();
    expect(find.text('7 proyek'), findsOneWidget);
  });

  testWidgets('Detail: buka, Tautan tersembunyi bila kosong, Kembali', (
    tester,
  ) async {
    await _pumpApp(tester, const Size(402, 874));
    await _goToProjects(tester);

    await _openCard(tester, 'Project Musafa');
    expect(find.byType(ProjectDetailView), findsOneWidget);
    expect(find.text('Platformer · 2023'), findsOneWidget);
    expect(find.text('TAUTAN'), findsNothing);

    await tester.tap(find.text('Kembali'));
    await tester.pumpAndSettle();
    expect(find.byType(ProjectDetailView), findsNothing);

    await _openCard(tester, 'Jump of Icarus');
    await tester.dragUntilVisible(
      find.text('TAUTAN'),
      find.byType(ProjectDetailView),
      const Offset(0, -300),
    );
    expect(find.text('LIHAT DI STEAM'), findsOneWidget);
  });

  testWidgets(
    'Tombol Kembali Android: layar penuh → detail → daftar → Beranda',
    (tester) async {
      await _pumpApp(tester, const Size(402, 874));
      await _goToProjects(tester);
      await _openCard(tester, 'Purwodaddy');

      await tester.tap(find.bySemanticsLabel('Lihat galeri layar penuh'));
      await tester.pumpAndSettle();
      expect(find.byType(GalleryLightbox), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(GalleryLightbox), findsNothing);
      expect(find.byType(ProjectDetailView), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(ProjectDetailView), findsNothing);
      final shell = tester.widget<ShellScope>(find.byType(ShellScope));
      expect(shell.tabIndex, AppTab.projects);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(
        tester.widget<ShellScope>(find.byType(ShellScope)).tabIndex,
        AppTab.home,
      );
    },
  );

  testWidgets('Kartu unggulan Beranda membuka detail proyeknya', (
    tester,
  ) async {
    await _pumpApp(tester, const Size(402, 874));
    final card = find.text('Purwodaddy').first;
    await tester.ensureVisible(card);
    await tester.pumpAndSettle();
    await tester.tap(card);
    await tester.pumpAndSettle();

    expect(
      tester.widget<ShellScope>(find.byType(ShellScope)).tabIndex,
      AppTab.projects,
    );
    expect(find.byType(ProjectDetailView), findsOneWidget);
    expect(find.text('Adventure · 2024'), findsOneWidget);

    await tester.dragUntilVisible(
      find.text('HALAMAN GLOBAL GAME JAM'),
      find.byType(ProjectDetailView),
      const Offset(0, -300),
    );
    expect(find.text('HALAMAN GLOBAL GAME JAM'), findsOneWidget);
  });

  testWidgets('Tablet: daftar yang bergeser tidak menutupi rail navigasi', (
    tester,
  ) async {
    await _pumpApp(tester, const Size(800, 1280));
    await _goToProjects(tester);
    await _openCard(tester, 'Purwodaddy');

    // Halaman dipotong di batasnya: ClipRect seluas halaman, di kanan rail.
    final clip = _inPage(find.byType(ClipRect)).first;
    final pageRect = tester.getRect(_page);
    expect(tester.getRect(clip), pageRect);
    final railRight = tester.getRect(find.byType(AppNavRail)).right;
    expect(pageRect.left, greaterThanOrEqualTo(railRight));

    // Rail tetap bisa diketuk saat detail terbuka.
    await tester.tap(find.bySemanticsLabel('Beranda'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<ShellScope>(find.byType(ShellScope)).tabIndex,
      AppTab.home,
    );
  });

  testWidgets('Tablet landscape: latar filter selebar halaman', (tester) async {
    await _pumpApp(tester, const Size(1280, 800));
    await _goToProjects(tester);
    final filter = tester.getRect(find.byType(FilterBar));
    expect(filter.width, closeTo(tester.getRect(_page).width, 0.5));
  });

  testWidgets('Tablet: filter sembunyi saat scroll ke bawah, muncul ke atas', (
    tester,
  ) async {
    await _pumpApp(tester, const Size(800, 1280));
    await _goToProjects(tester);
    final list = _inPage(find.byType(SingleChildScrollView)).first;
    double filterBottom() => tester.getRect(find.byType(FilterBar)).bottom;
    final shown = filterBottom();

    await tester.drag(list, const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(filterBottom(), lessThan(shown - 30));

    await tester.drag(list, const Offset(0, 60));
    await tester.pumpAndSettle();
    expect(filterBottom(), closeTo(shown, 0.5));
  });

  testWidgets('Detail tetap terbuka saat tata letak berganti', (tester) async {
    await _pumpApp(tester, const Size(402, 874));
    await _goToProjects(tester);
    await _openCard(tester, 'Jamal the Bubble Bug');

    for (final size in const [
      Size(1280, 800),
      Size(402, 432),
      Size(874, 402),
    ]) {
      tester.view.physicalSize = size;
      await tester.pumpAndSettle();
      expect(find.byType(ProjectDetailView), findsOneWidget);
      expect(find.text('Puzzle Platformer · 2025'), findsOneWidget);
    }
  });
}
