import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../bug_shapes.dart';
import '../debug_rush_game.dart';
import '../game_config.dart';
import '../game_session.dart';

/// Satu kepingan: kotak kecil / serpihan arsir / sisi bingkai yang jatuh.
class _Piece {
  _Piece({
    required this.position,
    required this.size,
    required this.velocity,
    required this.spin,
    required this.lifetime,
    required this.gravity,
    required this.hatchColor,
  });

  Offset position;
  final Size size;
  Offset velocity;
  final double spin;
  final double lifetime;
  final double gravity;

  /// Memakai warna arsir (serpihan Bug 2) alih-alih fg.
  final bool hatchColor;

  double rotation = 0;
  double age = 0;

  /// Utuh di 40% awal, lalu memudar.
  double get alpha {
    final k = age / lifetime;
    return k < 0.4 ? 1 : (1 - (k - 0.4) / 0.6).clamp(0.0, 1.0);
  }
}

/// Serpihan dan pecahan bug: pecah 3×3 saat hancur, serpihan arsir Bug 2,
/// sisi bingkai Bug 3 yang jatuh. Hanya visual; tidak ikut disimpan di sesi.
class DebrisLayer extends Component with HasGameReference<DebugRushGame> {
  DebrisLayer() : super(priority: 1);

  final List<_Piece> _pieces = [];
  final _random = math.Random();

  double _spin() => game.reduceMotion ? 0 : (_random.nextDouble() - 0.5) * 9;

  void _add(
    Offset position,
    Size size,
    Offset velocity,
    double lifetime,
    double gravity, {
    bool hatchColor = false,
  }) {
    _pieces.add(
      _Piece(
        position: position,
        size: size,
        velocity: velocity,
        spin: _spin(),
        lifetime: lifetime,
        gravity: gravity,
        hatchColor: hatchColor,
      ),
    );
  }

  /// Pecah menjadi 3×3 kotak kecil yang terpental lalu memudar.
  void shatter(Offset center, double size) {
    final p = size / 3;
    for (var i = 0; i < 3; i++) {
      for (var j = 0; j < 3; j++) {
        final dx = i - 1, dy = j - 1;
        final speed = 170 + _random.nextDouble() * 170;
        _add(
          center + Offset(dx * p, dy * p),
          Size.square(p * 0.72),
          Offset(
            (dx + (_random.nextDouble() - 0.5) * 0.6) * speed,
            (dy + (_random.nextDouble() - 0.5) * 0.6) * speed - 140,
          ),
          GameConfig.shatterSeconds,
          900,
        );
      }
    }
  }

  /// Arsir Bug 2 rontok: serpihan kecil berwarna arsir.
  void peel(Offset center, double size) {
    for (var i = 0; i < GameConfig.hatchFlakes; i++) {
      _add(
        center +
            Offset(
              (_random.nextDouble() - 0.5) * size * 0.8,
              (_random.nextDouble() - 0.5) * size * 0.8,
            ),
        Size.square(size * 0.09),
        Offset(
          (_random.nextDouble() - 0.5) * 220,
          -80 - _random.nextDouble() * 160,
        ),
        0.32,
        900,
        hatchColor: true,
      );
    }
  }

  /// Satu sisi bingkai Bug 3 lepas dan jatuh sambil memudar.
  void dropSide(Offset c, double s, BugSide side) {
    final h = s / 2, th = s * 0.12;
    final jitter = (_random.nextDouble() - 0.5) * 40;
    final (Offset at, Size size, Offset v) = switch (side) {
      BugSide.top => (
        c + Offset(0, -h + th / 2),
        Size(s, th),
        Offset(jitter, -120),
      ),
      BugSide.right => (
        c + Offset(h - th / 2, 0),
        Size(th, s),
        Offset(70 + jitter, -100),
      ),
      BugSide.bottom => (
        c + Offset(0, h - th / 2),
        Size(s, th),
        Offset(jitter, -20),
      ),
      BugSide.left => (
        c + Offset(-h + th / 2, 0),
        Size(th, s),
        const Offset(-70, -60),
      ),
    };
    _add(at, size, v, GameConfig.sideFallSeconds, 1500);
  }

  @override
  void update(double dt) {
    for (final p in _pieces) {
      p.age += dt;
      p.velocity += Offset(0, p.gravity * dt);
      p.position += p.velocity * dt;
      p.rotation += p.spin * dt;
    }
    _pieces.removeWhere((p) => p.age >= p.lifetime);
  }

  @override
  void render(Canvas canvas) {
    final palette = game.palette;
    for (final p in _pieces) {
      final color = (p.hatchColor ? palette.hatch : palette.fg).withValues(
        alpha: p.alpha,
      );
      canvas.save();
      canvas.translate(p.position.dx, p.position.dy);
      canvas.rotate(p.rotation);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: p.size.width,
            height: p.size.height,
          ),
          Radius.circular(math.min(p.size.width, p.size.height) * 0.18),
        ),
        Paint()..color = color,
      );
      canvas.restore();
    }
  }
}

/// Saat waktu habis, bug yang tersisa memudar (±0,25 s) tanpa skor dan
/// tanpa ledakan.
class FadingBugs extends Component with HasGameReference<DebugRushGame> {
  FadingBugs(this.bugs) : super(priority: 0);

  final List<FadedBug> bugs;
  double _age = 0;

  @override
  void update(double dt) {
    _age += dt;
    if (_age >= GameConfig.endFadeSeconds) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final alpha = (1 - _age / GameConfig.endFadeSeconds).clamp(0.0, 1.0);
    for (final b in bugs) {
      paintBug(
        canvas,
        center: b.position,
        size: b.size,
        kind: b.kind,
        palette: game.palette,
        alpha: alpha,
        hatch: b.hatch,
        sidesLost: b.sidesLost,
      );
    }
  }
}
