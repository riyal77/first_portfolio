import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:first_portfolio/app/app.dart';
import 'package:first_portfolio/app/app_shell.dart';
import 'package:first_portfolio/core/layout/device_layout.dart';
import 'package:first_portfolio/core/theme/theme_controller.dart';
import 'package:first_portfolio/core/widgets/app_navigation.dart';
import 'package:first_portfolio/core/widgets/pixel_image.dart';
import 'package:first_portfolio/data/project_repository.dart';

ProjectRepository _loadProjects() => ProjectRepository.parse(
    File(ProjectRepository.assetPath).readAsStringSync());

Future<void> _pumpApp(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(PortfolioApp(
    themeController: ThemeController.inMemory(ThemeMode.light),
    projects: _loadProjects(),
  ));
  await tester.pumpAndSettle();
}

void main() {
  group('DeviceLayout.fromSize', () {
    test('HP portrait, landscape, layar depan Flip, tablet', () {
      expect(DeviceLayout.fromSize(const Size(402, 874)),
          DeviceLayout.phonePortrait);
      expect(DeviceLayout.fromSize(const Size(874, 402)),
          DeviceLayout.phoneLandscape);
      expect(
          DeviceLayout.fromSize(const Size(402, 432)), DeviceLayout.flipCover);
      expect(DeviceLayout.fromSize(const Size(800, 1280)), DeviceLayout.tablet);
      expect(DeviceLayout.fromSize(const Size(1280, 800)), DeviceLayout.tablet);
    });
  });

  group('Data proyek', () {
    test('7 proyek dalam urutan tampil, 4 unggulan', () {
      final repo = _loadProjects();
      expect(repo.projects.map((p) => p.title), [
        'Purwodaddy',
        'Project Musafa',
        'Jump of Icarus',
        'Jamal the Bubble Bug',
        'Breakout Clone',
        'Fifty Bird',
        'Rhythm Space Bar',
      ]);
      expect(repo.featured.length, 4);
    });

    test('Semua gambar galeri ada di assets', () {
      for (final p in _loadProjects().projects) {
        for (final path in p.imagePaths) {
          expect(File(path).existsSync(), isTrue, reason: path);
        }
      }
    });

    test('Tag dan baris engine', () {
      final repo = _loadProjects();
      expect(repo.byId('icarus').tags,
          ['Unity', 'C#', 'Platformer', 'Komersial']);
      expect(repo.byId('rhythm').engineLine, 'Scratch');
      expect(repo.byId('rhythm').tags, ['Scratch', 'Rhythm', 'Tugas Kelas']);
    });
  });

  test('snapPixelSize membulatkan ke kelipatan piksel sumber', () {
    // DPR 2,625 (umum di HP Android): 24 px sumber × 3 = 72 px fisik.
    expect(snapPixelSize(24, 24, 2.625) * 2.625, closeTo(72, 1e-9));
    expect(snapPixelSize(24, 24, 2), 24);
  });

  testWidgets('HP portrait: navigation bar bawah, tab bisa berpindah',
      (tester) async {
    await _pumpApp(tester, const Size(402, 874));
    expect(find.byType(AppBottomBar), findsOneWidget);
    expect(find.byType(AppNavRail), findsNothing);

    await tester.tap(find.bySemanticsLabel('Proyek'));
    await tester.pumpAndSettle();
    expect(find.text('7 proyek'), findsOneWidget);
  });

  testWidgets('HP landscape dan tablet memakai rail', (tester) async {
    await _pumpApp(tester, const Size(874, 402));
    expect(find.byType(AppNavRail), findsOneWidget);
    expect(find.byType(AppBottomBar), findsNothing);

    tester.view.physicalSize = const Size(1280, 800);
    await tester.pumpAndSettle();
    expect(find.byType(AppNavRail), findsOneWidget);
  });

  testWidgets('Tab dan scroll tetap sama saat tata letak berganti',
      (tester) async {
    await _pumpApp(tester, const Size(402, 874));
    await tester.tap(find.bySemanticsLabel('Tentang'));
    await tester.pumpAndSettle();

    final list = find.byKey(const PageStorageKey('about'));
    await tester.drag(list, const Offset(0, -300));
    await tester.pumpAndSettle();
    final before = tester
        .state<ScrollableState>(
            find.descendant(of: list, matching: find.byType(Scrollable)))
        .position
        .pixels;
    expect(before, greaterThan(0));

    // Pindah ke "layar depan Flip", lalu ke landscape.
    for (final size in const [Size(402, 432), Size(874, 402)]) {
      tester.view.physicalSize = size;
      await tester.pumpAndSettle();
      final shell = tester.widget<ShellScope>(find.byType(ShellScope));
      expect(shell.tabIndex, AppTab.about);
      final now = tester
          .state<ScrollableState>(
              find.descendant(of: list, matching: find.byType(Scrollable)))
          .position
          .pixels;
      expect(now, before);
    }
  });

  testWidgets('Tombol tema membalik tema', (tester) async {
    await _pumpApp(tester, const Size(402, 874));
    BuildContext ctx() => tester.element(find.byType(AppShell));
    expect(Theme.of(ctx()).brightness, Brightness.light);

    await tester.tap(find.bySemanticsLabel('Ganti ke tema gelap').first);
    await tester.pumpAndSettle();
    expect(Theme.of(ctx()).brightness, Brightness.dark);
  });
}
