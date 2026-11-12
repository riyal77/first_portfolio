import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:first_portfolio/features/minigame/game/bug_shapes.dart';
import 'package:first_portfolio/features/minigame/game/game_config.dart';
import 'package:first_portfolio/features/minigame/game/game_session.dart';

const _area = PlayArea(
  rect: Rect.fromLTRB(14, 66, 388, 780),
  bugSize: 60,
  maxBugs: 6,
);

/// Sesi yang sudah melewati hitung mundur (sedang bermain).
GameSession _running({int seed = 1}) {
  final s = GameSession(random: math.Random(seed))..setArea(_area);
  s.advance(GameConfig.countdownFrom * GameConfig.countdownStepSeconds + 0.01);
  expect(s.phase, PlayPhase.running);
  return s;
}

var _pointer = 0;

/// Tap (jari turun lalu naik) di tengah bug.
void _tap(GameSession s, Bug b) {
  final id = ++_pointer;
  s.pointerDown(id, b.position);
  s.pointerUp(id);
}

void main() {
  test('Hitung mundur 3-2-1 lalu bermain 90 detik, "Waktu habis!" 1 detik', () {
    final s = GameSession(random: math.Random(1))..setArea(_area);
    expect(s.countdownNumber, 3);
    s.advance(0.8);
    expect(s.countdownNumber, 2);
    s.advance(1.5);
    expect(s.phase, PlayPhase.running);
    expect(s.remaining, GameConfig.roundSeconds);

    for (var t = 0.0; t < GameConfig.roundSeconds + 0.1; t += 0.1) {
      s.advance(0.1);
    }
    expect(s.phase, PlayPhase.timeUp);
    expect(s.bugs, isEmpty);
    expect(s.takeEvents().whereType<BugsFaded>(), isNotEmpty);
    s.advance(1.05);
    expect(s.phase, PlayPhase.ended);
  });

  test('Batas per jenis: penuh tidak diundi', () {
    final s = _running();
    for (var i = 0; i < 5; i++) {
      s.spawn(BugKind.bug2);
    }
    expect(s.spawn(BugKind.bug2), isNull, reason: 'Bug 2 maks. 5');
    // Area besar (maks. total 20) untuk menguji batas Bug 3 dan Bug 4.
    final big = GameSession(random: math.Random(2))
      ..setArea(
        const PlayArea(
          rect: Rect.fromLTRB(0, 0, 2000, 2000),
          bugSize: 60,
          maxBugs: 20,
        ),
      );
    big.advance(3);
    for (var i = 0; i < 5; i++) {
      big.spawn(BugKind.bug2);
    }
    for (var i = 0; i < 3; i++) {
      big.spawn(BugKind.bug3);
    }
    big.spawn(BugKind.bug4);
    expect(big.spawn(BugKind.bug3), isNull);
    expect(big.spawn(BugKind.bug4), isNull);
    for (var i = 0; i < 200; i++) {
      expect(big.pickKind(), BugKind.bug1);
    }
  });

  test('Jumlah maksimal bug di layar', () {
    final s = _running();
    for (var i = 0; i < 10; i++) {
      s.spawn(BugKind.bug1);
    }
    expect(s.bugs.length, _area.maxBugs);
  });

  test('Bug 1: 1 tap, +2', () {
    final s = _running();
    final b = s.spawn(BugKind.bug1)!;
    _tap(s, b);
    expect(s.bugs, isEmpty);
    expect(s.score, 2);
  });

  test('Bug 2: tap pertama menghapus arsir, tap kedua menghancurkan (+5)', () {
    final s = _running();
    final b = s.spawn(BugKind.bug2)!;
    _tap(s, b);
    expect(s.bugs, contains(b));
    expect(b.hitsLeft, 1);
    expect(s.takeEvents().whereType<HatchPeeled>(), hasLength(1));
    _tap(s, b);
    expect(s.bugs, isEmpty);
    expect(s.score, 5);
  });

  test(
    'Bug 3: sisi atas, kanan, bawah lepas; tap ke-4 menghancurkan (+10)',
    () {
      final s = _running();
      final b = s.spawn(BugKind.bug3)!;
      final sides = <BugSide>[];
      for (var i = 0; i < 4; i++) {
        _tap(s, b);
        sides.addAll(s.takeEvents().whereType<SideLost>().map((e) => e.side));
      }
      expect(sides, [BugSide.top, BugSide.right, BugSide.bottom, BugSide.left]);
      expect(s.bugs, isEmpty);
      expect(s.score, 10);
    },
  );

  test('Dua jari di satu bug tetap satu tap', () {
    final s = _running();
    final b = s.spawn(BugKind.bug2)!;
    s.pointerDown(1, b.position);
    s.pointerDown(2, b.position);
    expect(b.hitsLeft, 1);
    s.pointerUp(1);
    s.pointerUp(2);
  });

  test('Bug 4: tahan 2 detik hancur (+20); dilepas lebih awal progres nol', () {
    final s = _running();
    final b = s.spawn(BugKind.bug4)!;
    s.pointerDown(1, b.position);
    s.advance(1.0);
    expect(b.hold, closeTo(1.0, 1e-9));
    s.pointerUp(1);
    expect(b.hold, 0);

    s.pointerDown(2, b.position);
    for (var t = 0.0; t < 2.3; t += 0.05) {
      s.advance(0.05);
    }
    expect(s.bugs, isNot(contains(b)));
    expect(s.score, 20);
  });

  test('Bug 4 yang ditahan tidak pernah meledak', () {
    final s = _running();
    final b = s.spawn(BugKind.bug4)!;
    b.life = b.lifeMax - 0.01;
    s.pointerDown(1, b.position);
    s.advance(0.5);
    expect(s.frozen, isFalse);
    expect(s.bugs, contains(b));
  });

  test('Level naik setiap 2 bug hancur berturut-turut (maks. 10)', () {
    final s = _running();
    for (var i = 0; i < 24; i++) {
      _tap(s, s.spawn(BugKind.bug1)!);
    }
    expect(s.streak, 24);
    expect(s.level, GameConfig.maxLevel);
  });

  test(
    'Ledakan beruntun: −2 level tiga kali, ke-4 kembali ke 0; skor tetap',
    () {
      final s = _running();
      s.debugSetLevel(10);
      final levels = <int>[];
      for (var i = 0; i < 4; i++) {
        final b = s.spawn(BugKind.bug1)!;
        final score = s.score;
        s.debugExpire(b);
        s.advance(0.001);
        expect(s.score, score);
        levels.add(s.level);
        // Lewati freeze.
        s.advance(GameConfig.freezeSeconds + 0.01);
      }
      expect(levels, [8, 6, 4, 0]);
      expect(s.streak, 0);
    },
  );

  test('Satu bug hancur mengembalikan hitungan ledakan ke nol', () {
    final s = _running();
    s.debugSetLevel(10);
    for (var i = 0; i < 3; i++) {
      s.debugExpire(s.spawn(BugKind.bug1)!);
      s.advance(0.001);
      s.advance(GameConfig.freezeSeconds + 0.01);
    }
    expect(s.level, 4);
    _tap(s, s.spawn(BugKind.bug1)!);
    s.debugExpire(s.spawn(BugKind.bug1)!);
    s.advance(0.001);
    expect(s.level, 2, reason: 'ledakan ke-1 lagi: −2, bukan reset');
  });

  test('Freeze 0,6 detik: tap diabaikan, tidak ada bug baru', () {
    final s = _running();
    final target = s.spawn(BugKind.bug1)!;
    s.debugExpire(s.spawn(BugKind.bug1)!);
    s.advance(0.001);
    expect(s.frozen, isTrue);
    expect(s.pointerDown(1, target.position), isFalse);
    final count = s.bugs.length;
    s.advance(0.5);
    expect(s.bugs.length, count);
    s.advance(0.2);
    expect(s.frozen, isFalse);
    expect(s.pointerDown(2, target.position), isTrue);
  });

  test('Waktu sebelum meledak mengikuti level (3,6 → 1,85 detik)', () {
    final s = _running();
    expect(s.spawn(BugKind.bug1)!.lifeMax, closeTo(3.6, 1e-9));
    expect(
      s.spawn(BugKind.bug4)!.lifeMax,
      closeTo(3.6 * GameConfig.bug4LifeFactor, 1e-9),
    );
    s.debugSetLevel(10);
    expect(s.spawn(BugKind.bug1)!.lifeMax, closeTo(1.85, 1e-9));
  });

  test('Posisi bug di dalam area dan tidak tumpang tindih', () {
    final s = _running(seed: 9);
    for (var i = 0; i < 6; i++) {
      s.spawn(BugKind.bug1);
    }
    final bugs = s.bugs;
    for (final b in bugs) {
      expect(_area.rect.contains(b.position), isTrue);
    }
    for (var i = 0; i < bugs.length; i++) {
      for (var j = i + 1; j < bugs.length; j++) {
        expect(
          (bugs[i].position - bugs[j].position).distance,
          greaterThan(_area.bugSize * GameConfig.minCenterDistance),
        );
      }
    }
  });

  test('Tata letak berganti: posisi bug dipetakan ulang, sesi tetap', () {
    final s = _running();
    final b = s.spawn(BugKind.bug1)!;
    _tap(s, s.spawn(BugKind.bug1)!);
    final fx = (b.position.dx - _area.rect.left) / _area.rect.width;
    const land = PlayArea(
      rect: Rect.fromLTRB(14, 58, 784, 388),
      bugSize: 52,
      maxBugs: 7,
    );
    s.setArea(land);
    expect(
      (b.position.dx - land.rect.left) / land.rect.width,
      closeTo(fx, 1e-9),
    );
    expect(s.score, 2);
    expect(s.bugs, contains(b));
  });

  test('Jeda menghentikan waktu dan melepas jari', () {
    final s = _running();
    final b = s.spawn(BugKind.bug4)!;
    s.pointerDown(1, b.position);
    s.setPaused(true);
    expect(b.holding, isFalse);
    final remaining = s.remaining;
    s.advance(5);
    expect(s.remaining, remaining);
  });
}
