import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:first_portfolio/app/app.dart';
import 'package:first_portfolio/core/theme/theme_controller.dart';
import 'package:first_portfolio/data/project_repository.dart';
import 'package:first_portfolio/features/about/about_page.dart';

Future<void> _pumpAbout(WidgetTester tester, Size size) async {
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
  await tester.tap(find.bySemanticsLabel('Tentang'));
  await tester.pumpAndSettle();
}

Finder _inAbout(Finder f) =>
    find.descendant(of: find.byType(AboutPage), matching: f);

void main() {
  const sizes = {
    'HP portrait': Size(402, 874),
    'HP landscape': Size(874, 402),
    'layar depan Flip': Size(402, 432),
    'tablet portrait': Size(800, 1280),
    'tablet landscape': Size(1280, 800),
  };

  for (final entry in sizes.entries) {
    testWidgets('About Me tampil tanpa overflow: ${entry.key}', (tester) async {
      await _pumpAbout(tester, entry.value);
      for (final title in ['SKILLS', 'TOOLS', 'JOURNEY', 'EDUCATION']) {
        expect(_inAbout(find.text(title)), findsOneWidget, reason: title);
      }
      expect(_inAbout(find.text('Read More..')), findsOneWidget);
      expect(_inAbout(find.text('C++ · Python')), findsOneWidget);
      expect(_inAbout(find.text('CS50x')), findsOneWidget);
      // Gulir sampai bawah agar semua bagian ikut di-layout.
      await tester.drag(
        _inAbout(find.byType(SingleChildScrollView)).first,
        const Offset(0, -4000),
      );
      await tester.pumpAndSettle();
    });
  }

  testWidgets('Bio: Read More.. membuka, Read Less menutup', (tester) async {
    await _pumpAbout(tester, const Size(402, 874));
    final lastWords = _inAbout(
      find.textContaining('merilis game karyaku sendiri di Steam'),
    );
    double bioBottom() => tester
        .getBottomLeft(_inAbout(find.text('Read More..').hitTestable()).first)
        .dy;
    final collapsed = bioBottom();

    await tester.tap(_inAbout(find.text('Read More..')));
    await tester.pumpAndSettle();
    expect(_inAbout(find.text('Read Less')), findsOneWidget);
    // Paragraf kedua kini utuh di atas tombol.
    final open = tester.getBottomLeft(_inAbout(find.text('Read Less'))).dy;
    expect(open, greaterThan(collapsed + 100));
    expect(tester.getBottomLeft(lastWords).dy, lessThan(open));

    // Bio terbuka mendorong tombol ke bawah layar: gulir ke tengah dulu.
    await Scrollable.ensureVisible(
      tester.element(_inAbout(find.text('Read Less'))),
      alignment: 0.5,
    );
    await tester.pumpAndSettle();
    await tester.tap(_inAbout(find.text('Read Less')));
    await tester.pumpAndSettle();
    expect(_inAbout(find.text('Read More..')), findsOneWidget);
  });

  testWidgets('Tablet portrait: JOURNEY dan EDUCATION berdampingan', (
    tester,
  ) async {
    await _pumpAbout(tester, const Size(800, 1280));
    final journey = tester.getTopLeft(_inAbout(find.text('JOURNEY')));
    final education = tester.getTopLeft(_inAbout(find.text('EDUCATION')));
    expect(journey.dy, closeTo(education.dy, 0.5));
    expect(education.dx, greaterThan(journey.dx + 200));
  });

  testWidgets('HP landscape: SKILLS di kolom kanan sejajar perkenalan', (
    tester,
  ) async {
    await _pumpAbout(tester, const Size(874, 402));
    final skills = tester.getTopLeft(_inAbout(find.text('SKILLS')));
    final name = tester.getTopLeft(_inAbout(find.text('Ryal Naufal')));
    expect(skills.dx, greaterThan(name.dx + 200));
    expect(skills.dy, lessThan(name.dy + 40));
  });
}
