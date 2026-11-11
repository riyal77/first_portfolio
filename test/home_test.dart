import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:first_portfolio/app/app.dart';
import 'package:first_portfolio/app/app_shell.dart';
import 'package:first_portfolio/core/theme/theme_controller.dart';
import 'package:first_portfolio/data/project_repository.dart';
import 'package:first_portfolio/features/home/widgets/home_parts.dart';

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

ScrollPosition _homeScroll(WidgetTester tester) => tester
    .state<ScrollableState>(
      find
          .descendant(
            of: find.byType(SingleChildScrollView),
            matching: find.byType(Scrollable),
          )
          .first,
    )
    .position;

/// Posisi atas teks di layar.
double _topOf(WidgetTester tester, String text) =>
    tester.getTopLeft(find.text(text).first).dy;

void main() {
  const sizes = {
    'HP portrait': Size(402, 874),
    'HP landscape': Size(874, 402),
    'layar depan Flip': Size(402, 432),
    'tablet portrait': Size(800, 1280),
    'tablet landscape': Size(1280, 800),
  };

  for (final entry in sizes.entries) {
    testWidgets('Beranda tampil tanpa overflow: ${entry.key}', (tester) async {
      await _pumpApp(tester, entry.value);
      expect(find.text('SKILLS'), findsOneWidget);
      expect(find.text('FEATURED PROJECTS'), findsOneWidget);
      expect(find.text('Juara GGJ 2024'), findsOneWidget);
      expect(find.byType(SocialButtons), findsOneWidget);
      // Gulir sampai bawah agar semua bagian ikut di-layout.
      await tester.drag(
        find.byType(SingleChildScrollView).first,
        const Offset(0, -3000),
      );
      await tester.pumpAndSettle();
      expect(find.text('MAIN SEKARANG'), findsOneWidget);
    });
  }

  testWidgets('Morphing: foto & nama pindah ke App Banner setelah scroll', (
    tester,
  ) async {
    await _pumpApp(tester, const Size(402, 874));
    // Nama yang tampil ada di lapisan morphing (bukan slot hero).
    final nameFinder = find.text('Ryal Naufal');
    final before = tester.getRect(nameFinder.last);
    expect(before.top, greaterThan(100));

    await tester.drag(
      find.byType(SingleChildScrollView).first,
      const Offset(0, -600),
    );
    await tester.pumpAndSettle();
    final after = tester.getRect(nameFinder.last);
    // Banner 60 px: nama berada di dalamnya, mengecil 24 → 18.
    expect(after.center.dy, lessThan(60));
    expect(after.height, lessThan(before.height));
  });

  testWidgets('SKILLS tablet: portrait digeser, landscape grid 4 × 2', (
    tester,
  ) async {
    await _pumpApp(tester, const Size(800, 1280));
    // Portrait: 4 kolom tidak muat lega, jadi 2 baris yang digeser.
    expect(find.text('GESER ›'), findsOneWidget);

    tester.view.physicalSize = const Size(1280, 800);
    await tester.pumpAndSettle();
    expect(find.text('GESER ›'), findsNothing);
  });

  testWidgets('MAIN SEKARANG membuka tab Mini Game', (tester) async {
    await _pumpApp(tester, const Size(402, 874));
    await tester.drag(
      find.byType(SingleChildScrollView).first,
      const Offset(0, -3000),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('MAIN SEKARANG'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<ShellScope>(find.byType(ShellScope)).tabIndex,
      AppTab.miniGame,
    );
  });

  testWidgets('Posisi scroll dipetakan per bagian saat tata letak berganti', (
    tester,
  ) async {
    await _pumpApp(tester, const Size(402, 874));
    // Gulir sampai judul FEATURED PROJECTS dekat puncak layar.
    final pos = _homeScroll(tester);
    final target = pos.pixels + _topOf(tester, 'FEATURED PROJECTS') - 120;
    pos.jumpTo(target);
    await tester.pumpAndSettle();
    final phoneTop = _topOf(tester, 'FEATURED PROJECTS');

    // Ke tablet: hero jauh lebih pendek, piksel scroll tidak lagi cocok,
    // tetapi bagian FEATURED PROJECTS tetap di posisi baca yang sama.
    tester.view.physicalSize = const Size(1280, 800);
    await tester.pumpAndSettle();
    final tabletTop = _topOf(tester, 'FEATURED PROJECTS');
    expect(tabletTop, inInclusiveRange(0, 400));

    // Kembali ke HP: posisi semula.
    tester.view.physicalSize = const Size(402, 874);
    await tester.pumpAndSettle();
    expect(_topOf(tester, 'FEATURED PROJECTS'), closeTo(phoneTop, 40));
  });

  testWidgets('Carousel tetap di kartu yang sama saat lebar berubah', (
    tester,
  ) async {
    await _pumpApp(tester, const Size(402, 874));
    final carousel = find.byWidgetPredicate(
      (w) => w is SingleChildScrollView && w.scrollDirection == Axis.horizontal,
    );
    // Carousel = scroll horizontal kedua (yang pertama SKILLS).
    await tester.ensureVisible(find.text('Purwodaddy'));
    await tester.pumpAndSettle();
    await tester.fling(carousel.at(1), const Offset(-300, 0), 800);
    await tester.pumpAndSettle();
    expect(find.text('2 / 4'), findsOneWidget);

    // Layar depan Flip: lebar kartu berubah, kartu ke-2 tetap aktif.
    tester.view.physicalSize = const Size(402, 432);
    await tester.pumpAndSettle();
    expect(find.text('2 / 4'), findsOneWidget);
    final cardLeft = tester.getTopLeft(find.text('Project Musafa')).dx;
    expect(cardLeft, inInclusiveRange(20, 60));
  });
}
