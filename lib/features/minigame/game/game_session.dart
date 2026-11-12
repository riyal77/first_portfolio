import 'dart:math' as math;
import 'dart:ui' show Offset, Rect;

import 'package:flutter/foundation.dart';

import 'bug_shapes.dart';
import 'game_config.dart';

/// Tahap satu permainan.
enum PlayPhase {
  /// Hitung mundur "3, 2, 1".
  countdown,

  /// 90 detik permainan.
  running,

  /// Tulisan "Waktu habis!" ±1 detik.
  timeUp,

  /// Selesai; controller memindahkan ke layar kontak.
  ended,
}

/// Area main (koordinat layar bermain) dan ukuran sesuai tata letak.
@immutable
class PlayArea {
  const PlayArea({
    required this.rect,
    required this.bugSize,
    required this.maxBugs,
  });

  /// Tempat pusat bug boleh muncul: di bawah skor, di luar navigasi.
  final Rect rect;

  /// Ukuran dasar bug.
  final double bugSize;

  /// Jumlah maksimal bug di layar.
  final int maxBugs;

  @override
  bool operator ==(Object other) =>
      other is PlayArea &&
      other.rect == rect &&
      other.bugSize == bugSize &&
      other.maxBugs == maxBugs;

  @override
  int get hashCode => Object.hash(rect, bugSize, maxBugs);
}

/// Satu bug di layar.
class Bug {
  Bug._(this.id, this.kind, this.position, this.lifeMax) : hitsLeft = kind.hits;

  final int id;
  final BugKind kind;

  /// Pusat bug.
  Offset position;

  /// Waktu sebelum meledak (ditetapkan saat muncul, sesuai level).
  final double lifeMax;

  /// Waktu yang sudah berjalan menuju ledakan.
  double life = 0;

  /// Umur sejak muncul (pop).
  double age = 0;

  /// Waktu sejak tap terakhir (squash).
  double sinceTap = double.infinity;

  int hitsLeft;

  /// Bug 2: waktu sejak arsir terkelupas.
  double? sincePeel;

  /// Bug 3: jumlah sisi bingkai yang sudah lepas (atas, kanan, bawah).
  int sidesLost = 0;

  /// Bug 4: lama ditahan.
  double hold = 0;

  /// Bug 4: waktu sejak mulai runtuh (null = belum).
  double? collapsing;

  /// Jari yang sedang menyentuh bug ini.
  final Set<int> pointers = {};

  bool get holding => kind.isHold && pointers.isNotEmpty && collapsing == null;

  double get lifeFraction => (life / lifeMax).clamp(0.0, 1.0);

  double get holdProgress => (hold / GameConfig.holdSeconds).clamp(0.0, 1.0);

  /// Kekuatan arsir Bug 2 (1 = utuh, 0 = terkelupas).
  double get hatch {
    if (kind != BugKind.bug2) return 0;
    final t = sincePeel;
    if (t == null) return 1;
    return math.max(0, 1 - t / GameConfig.hatchFadeSeconds);
  }
}

/// Kejadian untuk efek visual dan getaran (serpihan, "+N", splash,
/// guncangan). Diambil lapisan Flame lewat [GameSession.takeEvents].
sealed class GameEvent {
  const GameEvent();
}

/// Tap mengenai bug, atau Bug 4 mulai ditahan (getaran sangat ringan).
class BugTouched extends GameEvent {
  const BugTouched(this.position);
  final Offset position;
}

/// Arsir Bug 2 terkelupas.
class HatchPeeled extends GameEvent {
  const HatchPeeled(this.position, this.size);
  final Offset position;
  final double size;
}

/// Satu sisi bingkai Bug 3 lepas.
class SideLost extends GameEvent {
  const SideLost(this.position, this.size, this.side);
  final Offset position;
  final double size;
  final BugSide side;
}

/// Bug hancur: pecah 3×3 seukuran [shatterSize], skor bertambah [points].
class BugDestroyed extends GameEvent {
  const BugDestroyed(this.position, this.shatterSize, this.points);
  final Offset position;
  final double shatterSize;
  final int points;
}

/// Bug meledak (splash, guncangan, getaran kuat).
class BugExploded extends GameEvent {
  const BugExploded(this.position);
  final Offset position;
}

/// Waktu habis: bug yang tersisa memudar tanpa skor.
class BugsFaded extends GameEvent {
  const BugsFaded(this.bugs);
  final List<FadedBug> bugs;
}

@immutable
class FadedBug {
  const FadedBug({
    required this.kind,
    required this.position,
    required this.size,
    required this.hatch,
    required this.sidesLost,
  });

  final BugKind kind;
  final Offset position;
  final double size;
  final double hatch;
  final int sidesLost;
}

/// Seluruh keadaan satu permainan Debug Rush: tahap, skor, waktu, level,
/// streak, bug di layar, freeze, dan input.
///
/// Murni Dart (tanpa Flame) dan dipegang [MiniGameController] di luar
/// widget, sehingga tetap utuh saat tata letak berganti (rotasi, layar
/// depan ↔ layar utama Flip). Waktu hanya maju lewat [advance]; saat dijeda,
/// tab tidak aktif, atau layar depan Flip, [advance] tidak dipanggil.
class GameSession extends ChangeNotifier {
  GameSession({math.Random? random}) : _random = random ?? math.Random();

  final math.Random _random;

  PlayPhase _phase = PlayPhase.countdown;
  double _countdownLeft =
      GameConfig.countdownFrom * GameConfig.countdownStepSeconds;
  double _remaining = GameConfig.roundSeconds;
  double _timeUpLeft = GameConfig.timeUpSeconds;
  int _score = 0;
  bool _paused = false;

  int _level = 0;
  int _streak = 0;
  int _explosionChain = 0;
  double _freezeLeft = 0;
  Offset? _splashOrigin;
  double _spawnTimer = GameConfig.firstSpawnDelay;
  int _nextId = 0;

  final List<Bug> _bugs = [];
  final Map<int, Bug> _pointers = {};
  final List<GameEvent> _events = [];
  PlayArea? _area;

  PlayPhase get phase => _phase;
  int get score => _score;
  int get level => _level;
  int get streak => _streak;

  /// Sisa waktu permainan (detik).
  double get remaining => _remaining;

  List<Bug> get bugs => List.unmodifiable(_bugs);
  PlayArea? get area => _area;

  /// Angka hitung mundur yang tampil: 3, 2, lalu 1.
  int get countdownNumber => (_countdownLeft / GameConfig.countdownStepSeconds)
      .ceil()
      .clamp(1, GameConfig.countdownFrom);

  /// Kemajuan angka hitung mundur yang sedang tampil (0 → 1).
  double get countdownStepProgress {
    final steps = _countdownLeft / GameConfig.countdownStepSeconds;
    return (1 - (steps - (countdownNumber - 1))).clamp(0.0, 1.0);
  }

  /// Sedang freeze setelah ledakan.
  bool get frozen => _freezeLeft > 0;

  /// Kemajuan freeze / splash (0 → 1).
  double get freezeProgress =>
      frozen ? (1 - _freezeLeft / GameConfig.freezeSeconds).clamp(0.0, 1.0) : 0;

  /// Titik asal splash ledakan terakhir (null bila tidak freeze).
  Offset? get splashOrigin => frozen ? _splashOrigin : null;

  /// Dijeda (dialog Lanjutkan / Akhiri permainan).
  bool get paused => _paused;

  void setPaused(bool value) {
    if (_paused == value || _phase == PlayPhase.ended) return;
    _paused = value;
    if (value) _releaseAllPointers();
    notifyListeners();
  }

  /// Jeda otomatis (pindah tab/aplikasi, tombol home, Flip ditutup) selama
  /// hitung mundur atau permainan; tidak saat "Waktu habis!".
  void pauseIfRunning() {
    if (_phase == PlayPhase.countdown || _phase == PlayPhase.running) {
      setPaused(true);
    }
  }

  /// Mengambil (dan mengosongkan) kejadian sejak pemanggilan terakhir.
  List<GameEvent> takeEvents() {
    if (_events.isEmpty) return const [];
    final out = List<GameEvent>.of(_events);
    _events.clear();
    return out;
  }

  /// Menetapkan area main. Bila tata letak berganti, posisi bug dipetakan
  /// ulang secara proporsional ke area baru.
  void setArea(PlayArea area) {
    final old = _area;
    if (old == area) return;
    _area = area;
    if (old == null || old.rect == area.rect) return;
    for (final b in _bugs) {
      final fx = old.rect.width <= 0
          ? 0.5
          : (b.position.dx - old.rect.left) / old.rect.width;
      final fy = old.rect.height <= 0
          ? 0.5
          : (b.position.dy - old.rect.top) / old.rect.height;
      b.position = Offset(
        area.rect.left + fx.clamp(0.0, 1.0) * area.rect.width,
        area.rect.top + fy.clamp(0.0, 1.0) * area.rect.height,
      );
    }
    if (_splashOrigin case final o?) {
      final fx = (o.dx - old.rect.left) / math.max(1, old.rect.width);
      final fy = (o.dy - old.rect.top) / math.max(1, old.rect.height);
      _splashOrigin = Offset(
        area.rect.left + fx * area.rect.width,
        area.rect.top + fy * area.rect.height,
      );
    }
  }

  // --- Ukuran dan tampilan bug ---------------------------------------------

  double get _base => _area?.bugSize ?? GameConfig.bugSizePhonePortrait;

  /// Ukuran bug saat ini: pop, membesar 100% → 140%, squash, runtuh.
  double sizeOf(Bug b) {
    final pop = _backOut((b.age / GameConfig.popSeconds).clamp(0.0, 1.0));
    final grow = 1 + (GameConfig.growTo - 1) * b.lifeFraction;
    final collapse = b.collapsing == null
        ? 1.0
        : 1 -
              0.8 *
                  _easeOut(
                    (b.collapsing! / GameConfig.collapseSeconds).clamp(
                      0.0,
                      1.0,
                    ),
                  );
    // Pop berawal dari 0; pembulatan bisa memberi nilai negatif kecil.
    return math.max(0, _base * pop * grow * _squash(b.sinceTap) * collapse);
  }

  /// Opacity bug: berkedip makin cepat di 30% waktu terakhir (kecuali Bug 4
  /// yang sedang ditahan).
  double alphaOf(Bug b) {
    final fr = b.lifeFraction;
    if (fr <= GameConfig.blinkFrom || b.holding) return 1;
    final k = (fr - GameConfig.blinkFrom) / (1 - GameConfig.blinkFrom);
    final period = _lerp(
      GameConfig.blinkPeriodStart,
      GameConfig.blinkPeriodEnd,
      k,
    );
    return (b.life / period).floor().isOdd ? GameConfig.blinkDimAlpha : 1;
  }

  // --- Waktu ---------------------------------------------------------------

  /// Memajukan waktu sebanyak [dt] detik.
  void advance(double dt) {
    if (_paused || dt <= 0 || _phase == PlayPhase.ended) return;
    switch (_phase) {
      case PlayPhase.countdown:
        _countdownLeft -= dt;
        if (_countdownLeft <= 0) {
          _phase = PlayPhase.running;
          _spawnTimer = GameConfig.firstSpawnDelay;
        }
      case PlayPhase.running:
        _remaining -= dt;
        if (_remaining <= 0) {
          _remaining = 0;
          _endRound();
        } else {
          _updateRunning(dt);
        }
      case PlayPhase.timeUp:
        _timeUpLeft -= dt;
        if (_timeUpLeft <= 0) _phase = PlayPhase.ended;
      case PlayPhase.ended:
        return;
    }
    notifyListeners();
  }

  void _updateRunning(double dt) {
    if (_freezeLeft > 0) {
      _freezeLeft = math.max(0, _freezeLeft - dt);
      if (_freezeLeft == 0) _splashOrigin = null;
    } else {
      // Tidak ada bug baru selama freeze.
      _spawnTimer -= dt;
      if (_spawnTimer <= 0) {
        _spawn();
        if (_level >= GameConfig.burstFromLevel &&
            _random.nextDouble() < GameConfig.burstChance) {
          _spawn();
        }
        _spawnTimer =
            _lerp(
              GameConfig.gapAtLevel0,
              GameConfig.gapAtMaxLevel,
              _difficulty,
            ) *
            _lerp(
              GameConfig.gapJitterMin,
              GameConfig.gapJitterMax,
              _random.nextDouble(),
            );
      }
    }

    for (final b in List.of(_bugs)) {
      if (!_bugs.contains(b)) continue;
      b.age += dt;
      b.sinceTap += dt;
      if (b.sincePeel != null) b.sincePeel = b.sincePeel! + dt;

      if (b.collapsing != null) {
        b.collapsing = b.collapsing! + dt;
        if (b.collapsing! >= GameConfig.collapseSeconds) {
          _remove(b);
          _award(b, shatterSize: _base * 0.6);
        }
        continue;
      }

      if (b.holding) {
        // Bug 4 yang ditahan tidak pernah meledak; bar berhenti selama
        // freeze.
        if (_freezeLeft <= 0) b.hold += dt;
        if (b.hold >= GameConfig.holdSeconds) {
          b.hold = GameConfig.holdSeconds;
          _release(b);
          b.collapsing = 0;
        }
      } else {
        b.life += dt;
        if (b.life >= b.lifeMax) _explode(b);
      }
    }
  }

  /// Mengakhiri waktu sekarang ("Waktu habis!" lalu layar kontak).
  void endRoundNow() {
    if (_phase != PlayPhase.running) return;
    _remaining = 0;
    _endRound();
    notifyListeners();
  }

  void _endRound() {
    _phase = PlayPhase.timeUp;
    _events.add(
      BugsFaded([
        for (final b in _bugs)
          FadedBug(
            kind: b.kind,
            position: b.position,
            size: sizeOf(b),
            hatch: b.hatch,
            sidesLost: b.sidesLost,
          ),
      ]),
    );
    _bugs.clear();
    _pointers.clear();
    _freezeLeft = 0;
    _splashOrigin = null;
  }

  // --- Kemunculan ----------------------------------------------------------

  double get _difficulty => _level / GameConfig.maxLevel;

  double get _lifeForLevel =>
      _lerp(GameConfig.lifeAtLevel0, GameConfig.lifeAtMaxLevel, _difficulty);

  /// Mengundi jenis bug: jenis yang sudah mencapai batasnya tidak ikut
  /// diundi; weight Bug 3 dibagi dua untuk setiap Bug 3 yang sudah ada.
  @visibleForTesting
  BugKind pickKind() {
    final counts = {for (final k in BugKind.values) k: 0};
    for (final b in _bugs) {
      counts[b.kind] = counts[b.kind]! + 1;
    }
    final weights = <BugKind, double>{};
    for (final k in BugKind.values) {
      var w = k.weight;
      if (k == BugKind.bug3) w *= math.pow(0.5, counts[k]!);
      final cap = k.maxOnScreen;
      if (cap != null && counts[k]! >= cap) w = 0;
      weights[k] = w;
    }
    final total = weights.values.fold(0.0, (a, b) => a + b);
    var r = _random.nextDouble() * total;
    for (final k in BugKind.values) {
      r -= weights[k]!;
      if (r <= 0 && weights[k]! > 0) return k;
    }
    return BugKind.bug1;
  }

  /// Memunculkan satu bug (jenis [kind] atau hasil undian) bila masih ada
  /// tempat.
  @visibleForTesting
  Bug? spawn([BugKind? kind]) => _spawn(kind);

  Bug? _spawn([BugKind? kind]) {
    final area = _area;
    if (area == null || _bugs.length >= area.maxBugs) return null;
    final k = kind ?? pickKind();
    final cap = k.maxOnScreen;
    if (cap != null && _bugs.where((b) => b.kind == k).length >= cap) {
      return null;
    }
    final base = area.bugSize;
    final m = base * GameConfig.growTo / 2 + 4;
    final r = area.rect;
    final left = r.left + m, right = math.max(r.left + m, r.right - m);
    final top = r.top + m;
    final bottom = math.max(
      top,
      r.bottom - m - GameConfig.holdBarGap - GameConfig.holdBarHeight,
    );
    var p = r.center;
    for (var i = 0; i < GameConfig.spawnTries; i++) {
      p = Offset(
        _lerp(left, right, _random.nextDouble()),
        _lerp(top, bottom, _random.nextDouble()),
      );
      final free = _bugs.every(
        (b) => (b.position - p).distance > base * GameConfig.minCenterDistance,
      );
      if (free) break;
    }
    final bug = Bug._(
      _nextId++,
      k,
      p,
      _lifeForLevel * (k.isHold ? GameConfig.bug4LifeFactor : 1),
    );
    _bugs.add(bug);
    return bug;
  }

  // --- Input ---------------------------------------------------------------

  /// Jari menyentuh layar di [position]. Respons langsung (bukan saat jari
  /// diangkat). Mengembalikan true bila mengenai bug.
  bool pointerDown(int pointer, Offset position) {
    if (_phase != PlayPhase.running || _paused || frozen) return false;
    for (final b in _bugs.reversed) {
      if (b.collapsing != null) continue;
      final half = math.max(
        GameConfig.minTouchHalf,
        sizeOf(b) / 2 + GameConfig.touchPadding,
      );
      final d = position - b.position;
      if (d.dx.abs() > half || d.dy.abs() > half) continue;
      // Jari kedua di bug yang sama tetap dihitung satu tap.
      if (b.pointers.isNotEmpty) return true;
      b.pointers.add(pointer);
      _pointers[pointer] = b;
      if (b.kind.isHold) {
        b.hold = 0;
        b.sinceTap = 0;
        _events.add(BugTouched(b.position));
      } else {
        _tap(b);
      }
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Jari diangkat atau gerakan dibatalkan.
  void pointerUp(int pointer) {
    final b = _pointers.remove(pointer);
    if (b == null) return;
    b.pointers.remove(pointer);
    // Bug 4 dilepas sebelum bar penuh: progres kembali ke nol.
    if (b.kind.isHold && b.pointers.isEmpty && b.collapsing == null) {
      b.hold = 0;
    }
  }

  void _tap(Bug b) {
    final s = sizeOf(b);
    b.sinceTap = 0;
    _events.add(BugTouched(b.position));
    switch (b.kind) {
      case BugKind.bug2 when b.hitsLeft == 2:
        b.hitsLeft = 1;
        b.sincePeel = 0;
        _events.add(HatchPeeled(b.position, s));
      case BugKind.bug3 when b.hitsLeft > 1:
        final side = BugSide.values[b.sidesLost];
        b.sidesLost++;
        b.hitsLeft--;
        _events.add(SideLost(b.position, s, side));
      case BugKind.bug3:
        _events.add(SideLost(b.position, s, BugSide.left));
        _remove(b);
        _award(b, shatterSize: s * 0.42);
      default:
        _remove(b);
        _award(b, shatterSize: s);
    }
  }

  void _award(Bug b, {required double shatterSize}) {
    _explosionChain = 0;
    _streak++;
    if (_streak % GameConfig.bugsPerLevel == 0) {
      _level = math.min(GameConfig.maxLevel, _level + 1);
    }
    _score += b.kind.score;
    _events.add(BugDestroyed(b.position, shatterSize, b.kind.score));
  }

  void _explode(Bug b) {
    _remove(b);
    _streak = 0;
    _explosionChain++;
    _level = _explosionChain >= GameConfig.explosionsToReset
        ? 0
        : math.max(0, _level - GameConfig.explosionPenalty);
    _freezeLeft = GameConfig.freezeSeconds;
    _splashOrigin = b.position;
    // Jari di bug lain dilepas; Bug 4 yang sedang ditahan tetap ditahan.
    for (final o in _bugs) {
      if (!o.holding) _release(o);
    }
    _events.add(BugExploded(b.position));
  }

  void _remove(Bug b) {
    _release(b);
    _bugs.remove(b);
  }

  void _release(Bug b) {
    for (final id in b.pointers) {
      _pointers.remove(id);
    }
    b.pointers.clear();
  }

  void _releaseAllPointers() {
    for (final b in _bugs) {
      _release(b);
      if (b.kind.isHold && b.collapsing == null) b.hold = 0;
    }
    _pointers.clear();
  }

  // --- Untuk pengujian -------------------------------------------------------

  /// Membuat bug [bug] langsung meledak pada [advance] berikutnya.
  @visibleForTesting
  void debugExpire(Bug bug) => bug.life = bug.lifeMax;

  @visibleForTesting
  void debugSetLevel(int level) => _level = level;
}

double _lerp(double a, double b, double t) => a + (b - a) * t;

double _easeOut(double k) => 1 - math.pow(1 - k, 3).toDouble();

double _backOut(double k) {
  const c = 1.7;
  final x = k - 1;
  return 1 + (c + 1) * x * x * x + c * x * x;
}

/// Squash setelah tap: 1 → 0,86 → 1,05 → 1 (±0,26 s).
double _squash(double t) {
  if (t < 0.06) return 1 - 0.14 * (t / 0.06);
  if (t < 0.16) return 0.86 + 0.19 * ((t - 0.06) / 0.1);
  if (t < GameConfig.squashSeconds) return 1.05 - 0.05 * ((t - 0.16) / 0.1);
  return 1;
}
