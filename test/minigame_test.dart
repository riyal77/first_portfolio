import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:first_portfolio/app/app.dart';
import 'package:first_portfolio/app/app_shell.dart';
import 'package:first_portfolio/core/theme/theme_controller.dart';
import 'package:first_portfolio/data/project_repository.dart';
import 'package:first_portfolio/features/minigame/game/game_config.dart';
import 'package:first_portfolio/features/minigame/game/game_session.dart';
import 'package:first_portfolio/features/minigame/minigame_controller.dart';
import 'package:first_portfolio/features/minigame/minigame_page.dart';

Future<MiniGameController> _pumpMiniGame(
  WidgetTester tester,
  Size size, {
  MiniGameController? controller,
}) async {
  final ctl = controller ?? MiniGameController.inMemory(random: math.Random(7));
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    PortfolioApp(
      themeController: ThemeController.inMemory(ThemeMode.light),
      projects: ProjectRepository.parse(
        File(ProjectRepository.assetPath).readAsStringSync(),
      ),
      miniGame: ctl,
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.bySemanticsLabel('Mini Game'));
  await tester.pumpAndSettle();
  return ctl;
}

Finder _inGame(Finder f) =>
    find.descendant(of: find.byType(MiniGamePage), matching: f);

/// Memajukan waktu per 100 ms (selang besar dianggap jeda oleh game).
Future<void> _advance(WidgetTester tester, double seconds) async {
  for (var t = 0.0; t < seconds; t += 0.1) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Tombol kembali Android.
Future<void> _pressBack(WidgetTester tester) async {
  final message = const JSONMethodCodec().encodeMethodCall(
    const MethodCall('popRoute'),
  );
  await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
    'flutter/navigation',
    message,
    (_) {},
  );
  await tester.pump();
}

/// Gulir sampai tombol [label] terlihat, lalu ketuk.
Future<void> _tapVisible(WidgetTester tester, String label) async {
  await tester.ensureVisible(_inGame(find.text(label)));
  await tester.pumpAndSettle();
  await tester.tap(_inGame(find.text(label)));
  await tester.pump();
}

/// Dari layar ajakan atau kontak sampai tombol uji coba tampil.
Future<void> _startAndSkipCountdown(WidgetTester tester, String button) async {
  await _tapVisible(tester, button);
  await _advance(tester, 3.3);
}

void main() {
  const sizes = {
    'HP portrait': Size(402, 874),
    'HP landscape': Size(874, 402),
    'layar depan Flip': Size(402, 432),
    'tablet portrait': Size(800, 1280),
    'tablet landscape': Size(1280, 800),
  };

  for (final entry in sizes.entries) {
    testWidgets('Layar ajakan tampil tanpa overflow: ${entry.key}', (
      tester,
    ) async {
      await _pumpMiniGame(tester, entry.value);
      for (final t in [
        'DEBUG RUSH',
        'GAME ORISINAL · RYAL NAUFAL',
        'CARA MAIN',
        'JENIS BUG',
        'Bug 4',
        'Tahan 2 detik · +20',
        'MULAI',
        'Lewati untuk melihat kontak',
      ]) {
        expect(_inGame(find.text(t)), findsOneWidget, reason: t);
      }
      await tester.drag(
        _inGame(find.byType(SingleChildScrollView)).first,
        const Offset(0, -3000),
      );
      await tester.pumpAndSettle();
    });

    testWidgets('Layar kontak tampil tanpa overflow: ${entry.key}', (
      tester,
    ) async {
      await _pumpMiniGame(
        tester,
        entry.value,
        controller: MiniGameController.inMemory(
          seenContact: true,
          hasPlayed: true,
          bestScore: 248,
        )..skip(),
      );
      expect(_inGame(find.text('SKOR TERTINGGI')), findsOneWidget);
      expect(_inGame(find.text('248')), findsOneWidget);
      expect(_inGame(find.text('MAIN LAGI')), findsOneWidget);
      for (final t in [
        'github.com/riyal77',
        '@ryalnaufal',
        'facebook.com/ryal.naufal',
        'ryal_naufal@yahoo.com',
      ]) {
        expect(_inGame(find.text(t)), findsOneWidget, reason: t);
      }
      for (final scroll in _inGame(
        find.byType(SingleChildScrollView),
      ).evaluate().toList()) {
        await tester.drag(
          find.byWidget(scroll.widget),
          const Offset(0, -3000),
          warnIfMissed: false,
        );
      }
      await tester.pumpAndSettle();
    });
  }

  testWidgets('Lewati: layar kontak tanpa skor, tombol MAIN', (tester) async {
    final ctl = await _pumpMiniGame(tester, const Size(402, 874));
    await tester.ensureVisible(
      _inGame(find.text('Lewati untuk melihat kontak')),
    );
    await tester.pumpAndSettle();
    await tester.tap(_inGame(find.text('Lewati untuk melihat kontak')));
    await tester.pumpAndSettle();

    expect(ctl.stage, MiniGameStage.contact);
    expect(ctl.seenContact, isTrue);
    expect(ctl.hasPlayed, isFalse);
    expect(
      _inGame(find.text('Halo, terima kasih sudah mampir!')),
      findsOneWidget,
    );
    expect(_inGame(find.text('SKOR AKHIR')), findsNothing);
    expect(_inGame(find.text('MAIN')), findsOneWidget);

    // MAIN langsung ke hitung mundur, tanpa layar ajakan.
    await tester.ensureVisible(_inGame(find.text('MAIN')));
    await tester.pumpAndSettle();
    await tester.tap(_inGame(find.text('MAIN')));
    await tester.pump();
    expect(ctl.stage, MiniGameStage.playing);
    expect(_inGame(find.text('3')), findsOneWidget);
    expect(_inGame(find.text('DEBUG RUSH')), findsNothing);
  });

  testWidgets('Alur penuh: hitung mundur, waktu habis, kontak, rekor baru', (
    tester,
  ) async {
    final ctl = await _pumpMiniGame(tester, const Size(402, 874));
    await _tapVisible(tester, 'MULAI');
    expect(_inGame(find.text('3')), findsOneWidget);
    await _advance(tester, 1.0);
    expect(_inGame(find.text('2')), findsOneWidget);
    await _advance(tester, 2.3);
    expect(ctl.session!.phase, PlayPhase.running);
    // Selama bermain App Banner disembunyikan.
    expect(_inGame(find.text('Mini Game')), findsNothing);

    // Tap bug sungguhan lewat layar (Bug 3: 4 tap, +10).
    final bug = ctl.session!.spawn(BugKind.bug3)!;
    for (var i = 0; i < 4; i++) {
      await tester.tapAt(bug.position);
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(ctl.session!.score, greaterThanOrEqualTo(10));
    ctl.session!.endRoundNow();
    await tester.pump();
    expect(_inGame(find.text('Waktu habis!')), findsOneWidget);

    await _advance(tester, 1.2);
    await tester.pumpAndSettle();
    expect(ctl.stage, MiniGameStage.contact);
    expect(ctl.hasPlayed, isTrue);
    final score = ctl.lastResult!.score;
    expect(score, greaterThan(0));
    expect(ctl.bestScore, score);
    expect(_inGame(find.text('SKOR AKHIR')), findsOneWidget);
    expect(_inGame(find.text('REKOR BARU!')), findsOneWidget);
    expect(_inGame(find.text('MAIN LAGI')), findsOneWidget);
    // Skor akhir dan skor tertinggi (sama).
    expect(_inGame(find.text('$score')), findsNWidgets(2));
  });

  testWidgets('Tombol kembali: jeda, Lanjutkan, lalu Akhiri permainan', (
    tester,
  ) async {
    final ctl = await _pumpMiniGame(
      tester,
      const Size(402, 874),
      controller: MiniGameController.inMemory(
        seenContact: true,
        hasPlayed: true,
        bestScore: 100,
      )..skip(),
    );
    await _startAndSkipCountdown(tester, 'MAIN LAGI');
    final before = ctl.session!.remaining;

    await _pressBack(tester);
    expect(_inGame(find.text('Permainan dijeda')), findsOneWidget);
    expect(
      tester.widget<ShellScope>(find.byType(ShellScope)).tabIndex,
      AppTab.miniGame,
    );
    // Waktu berhenti selama dijeda.
    await _advance(tester, 2);
    expect(ctl.session!.remaining, before);

    await tester.tap(_inGame(find.text('LANJUTKAN')));
    await tester.pump();
    expect(_inGame(find.text('Permainan dijeda')), findsNothing);
    await _advance(tester, 1);
    expect(ctl.session!.remaining, lessThan(before));

    await _pressBack(tester);
    await tester.tap(_inGame(find.text('Akhiri permainan')));
    await tester.pumpAndSettle();
    expect(ctl.stage, MiniGameStage.contact);
    expect(ctl.lastResult!.score, 0);
    expect(_inGame(find.text('REKOR BARU!')), findsNothing);
    expect(ctl.bestScore, 100);

    // Setelah bermain, tombol kembali kembali ke perilaku biasa (Beranda).
    await _pressBack(tester);
    await tester.pumpAndSettle();
    expect(
      tester.widget<ShellScope>(find.byType(ShellScope)).tabIndex,
      AppTab.home,
    );
  });

  testWidgets('Pindah tab menjeda permainan, lalu berlanjut', (tester) async {
    final ctl = await _pumpMiniGame(tester, const Size(402, 874));
    await _tapVisible(tester, 'MULAI');
    await _advance(tester, 1.2);
    expect(_inGame(find.text('2')), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Beranda'));
    await tester.pump();
    await _advance(tester, 5);
    await tester.tap(find.bySemanticsLabel('Mini Game'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    expect(ctl.stage, MiniGameStage.playing);
    expect(_inGame(find.text('2')), findsOneWidget);
    // Kembali ke tab: dialog jeda tampil, waktu belum berjalan.
    expect(_inGame(find.text('Permainan dijeda')), findsOneWidget);
    await _advance(tester, 2);
    expect(ctl.session!.countdownNumber, 2);

    await tester.tap(_inGame(find.text('LANJUTKAN')));
    await tester.pump();
    await _advance(tester, 2.2);
    expect(ctl.session!.phase, PlayPhase.running);
  });

  testWidgets('Tombol home / pindah aplikasi menampilkan dialog jeda', (
    tester,
  ) async {
    final ctl = await _pumpMiniGame(tester, const Size(402, 874));
    await _startAndSkipCountdown(tester, 'MULAI');
    for (final s in [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(s);
    }
    await tester.pump();
    for (final s in [
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(s);
    }
    await tester.pump();
    expect(ctl.session!.paused, isTrue);
    expect(_inGame(find.text('Permainan dijeda')), findsOneWidget);
  });

  testWidgets('Aplikasi dibuka lagi setelah pernah bermain: layar ajakan '
      'dengan MAIN LAGI dan Lihat skor dan kontak', (tester) async {
    final ctl = await _pumpMiniGame(
      tester,
      const Size(402, 874),
      controller: MiniGameController.inMemory(
        seenContact: true,
        hasPlayed: true,
        bestScore: 150,
      ),
    );
    expect(ctl.stage, MiniGameStage.intro);
    expect(_inGame(find.text('DEBUG RUSH')), findsOneWidget);
    expect(_inGame(find.text('MULAI')), findsNothing);
    expect(_inGame(find.text('MAIN LAGI')), findsOneWidget);

    await _tapVisible(tester, 'Lihat skor dan kontak');
    await tester.pumpAndSettle();
    expect(ctl.stage, MiniGameStage.contact);
    expect(_inGame(find.text('SKOR TERTINGGI')), findsOneWidget);
    expect(_inGame(find.text('150')), findsOneWidget);
  });

  testWidgets('Baru pernah Lewati: layar ajakan tetap MULAI / Lewati', (
    tester,
  ) async {
    await _pumpMiniGame(
      tester,
      const Size(402, 874),
      controller: MiniGameController.inMemory(seenContact: true),
    );
    expect(_inGame(find.text('MULAI')), findsOneWidget);
    expect(_inGame(find.text('Lewati untuk melihat kontak')), findsOneWidget);
  });

  testWidgets('Layar ajakan HP landscape: satu kolom', (tester) async {
    await _pumpMiniGame(tester, const Size(874, 402));
    final arena = tester.getTopLeft(_inGame(find.text('SKOR')));
    final howTo = tester.getTopLeft(_inGame(find.text('CARA MAIN')));
    expect(howTo.dy, greaterThan(arena.dy + 100));
    expect(howTo.dx, lessThan(arena.dx));
  });

  testWidgets('Layar ajakan tablet landscape: kolom sejajar atas & bawah', (
    tester,
  ) async {
    await _pumpMiniGame(tester, const Size(1280, 800));
    final title = tester.getRect(_inGame(find.text('DEBUG RUSH')));
    final howTo = tester.getRect(_inGame(find.text('CARA MAIN')));
    expect(howTo.left, greaterThan(title.left + 300));
    // Kolom kanan rata bawah: CARA MAIN dekat JENIS BUG (tanpa celah lebar).
    final bugsTitle = tester.getRect(_inGame(find.text('JENIS BUG')));
    expect(bugsTitle.top - howTo.bottom, lessThan(120));
    expect(howTo.top, greaterThanOrEqualTo(title.top));
    Rect material(String text) => tester.getRect(
      find
          .ancestor(
            of: _inGame(find.text(text)),
            matching: find.byType(Material),
          )
          .first,
    );
    final bug4 = tester.getRect(
      find
          .ancestor(
            of: _inGame(find.text('Bug 4')),
            matching: find.byType(Container),
          )
          .last,
    );
    expect(
      bug4.bottom,
      closeTo(material('Lewati untuk melihat kontak').bottom, 1),
    );
  });

  testWidgets('Layar depan Flip: pesan buka Flip, berlanjut saat dibuka', (
    tester,
  ) async {
    final ctl = await _pumpMiniGame(tester, const Size(402, 432));
    await tester.ensureVisible(_inGame(find.text('MULAI')));
    await tester.pumpAndSettle();
    await tester.tap(_inGame(find.text('MULAI')));
    await tester.pump();
    expect(_inGame(find.text('Buka Flip-mu untuk bermain')), findsOneWidget);
    await _advance(tester, 4);
    expect(ctl.session!.countdownNumber, 3);

    // Flip dibuka: hitung mundur mulai.
    tester.view.physicalSize = const Size(402, 874);
    await tester.pump();
    expect(_inGame(find.text('Buka Flip-mu untuk bermain')), findsNothing);
    await _advance(tester, 3.3);
    final remaining = ctl.session!.remaining;
    expect(remaining, lessThan(GameConfig.roundSeconds));

    // Flip ditutup di tengah permainan: jeda + dialog jeda di layar depan.
    tester.view.physicalSize = const Size(402, 432);
    await tester.pump();
    expect(ctl.session!.paused, isTrue);
    expect(_inGame(find.text('Permainan dijeda')), findsOneWidget);
    await _advance(tester, 3);
    expect(ctl.session!.remaining, remaining);

    // Lanjutkan di layar depan: pesan "Buka Flip-mu", waktu tetap berhenti.
    await tester.tap(_inGame(find.text('LANJUTKAN')));
    await tester.pump();
    expect(_inGame(find.text('Buka Flip-mu untuk bermain')), findsOneWidget);
    await _advance(tester, 2);
    expect(ctl.session!.remaining, remaining);

    // Flip dibuka: berlanjut dengan sisa waktu yang sama.
    tester.view.physicalSize = const Size(874, 402);
    await tester.pump();
    await _advance(tester, 1);
    expect(ctl.session!.remaining, lessThan(remaining));
  });

  testWidgets('Landscape: kolom kiri sejajar atas & bawah kolom kontak', (
    tester,
  ) async {
    await _pumpMiniGame(
      tester,
      const Size(1280, 800),
      controller: MiniGameController.inMemory(
        seenContact: true,
        hasPlayed: true,
        bestScore: 248,
      )..skip(),
    );
    Rect box(String text) => tester.getRect(
      find
          .ancestor(
            of: _inGame(find.text(text)),
            matching: find.byType(Material),
          )
          .first,
    );
    final card = tester.getRect(
      find
          .ancestor(
            of: _inGame(find.text('SKOR TERTINGGI')),
            matching: find.byType(Container),
          )
          .last,
    );
    expect(
      card.top,
      closeTo(tester.getTopLeft(_inGame(find.text('KONTAK'))).dy, 1),
    );
    expect(box('MAIN LAGI').bottom, closeTo(box('Email').bottom, 1));
  });

  testWidgets('Rotasi dari landscape ter-scroll: navigation bar muncul lagi', (
    tester,
  ) async {
    await _pumpMiniGame(
      tester,
      const Size(874, 402),
      controller: MiniGameController.inMemory(
        seenContact: true,
        hasPlayed: true,
        bestScore: 248,
      )..skip(),
    );
    await tester.drag(_inGame(find.text('Instagram')), const Offset(0, -300));
    await tester.pumpAndSettle();
    final shell = tester.widget<ShellScope>(find.byType(ShellScope));
    expect(shell.navVisible.value, isFalse);

    tester.view.physicalSize = const Size(402, 874);
    await tester.pumpAndSettle();
    expect(shell.navVisible.value, isTrue);
  });

  testWidgets('Landscape: KONTAK di kolom kanan, kolom kiri tetap', (
    tester,
  ) async {
    await _pumpMiniGame(
      tester,
      const Size(874, 402),
      controller: MiniGameController.inMemory(
        seenContact: true,
        hasPlayed: true,
        bestScore: 248,
      )..skip(),
    );
    final score = tester.getTopLeft(_inGame(find.text('SKOR TERTINGGI')));
    final contacts = tester.getTopLeft(_inGame(find.text('KONTAK')));
    expect(contacts.dx, greaterThan(score.dx + 200));
    expect(contacts.dy, closeTo(score.dy, 40));

    final button = tester.getTopLeft(_inGame(find.text('MAIN LAGI')));
    await tester.drag(_inGame(find.text('Instagram')), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(_inGame(find.text('MAIN LAGI'))), button);
  });
}
