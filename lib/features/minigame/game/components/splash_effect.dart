import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../debug_rush_game.dart';
import '../game_config.dart';

/// Splash layar penuh saat bug meledak: dither piksel warna fg yang menyebar
/// dari posisi bug, lalu luruh tepat saat freeze selesai.
///
/// Digambar dengan fragment shader `shaders/splash.frag`. Bila shader tidak
/// bisa dimuat (mis. di lingkungan pengujian), pola yang sama digambar
/// dengan kotak-kotak biasa di Canvas.
class SplashEffect extends Component with HasGameReference<DebugRushGame> {
  SplashEffect() : super(priority: 2);

  static const String asset = 'shaders/splash.frag';

  FragmentShader? _shader;

  @override
  Future<void> onLoad() async {
    try {
      final program = await FragmentProgram.fromAsset(asset);
      _shader = program.fragmentShader();
    } catch (_) {
      _shader = null;
    }
  }

  @override
  void onRemove() {
    _shader?.dispose();
    _shader = null;
    super.onRemove();
  }

  @override
  void render(Canvas canvas) {
    final session = game.session;
    final origin = session.splashOrigin;
    if (origin == null) return;
    final size = game.size;
    final k = session.freezeProgress;
    final color = game.palette.fg;
    final shader = _shader;
    if (shader != null) {
      shader
        ..setFloat(0, size.x)
        ..setFloat(1, size.y)
        ..setFloat(2, origin.dx)
        ..setFloat(3, origin.dy)
        ..setFloat(4, k)
        ..setFloat(5, GameConfig.splashCell)
        ..setFloat(6, color.r)
        ..setFloat(7, color.g)
        ..setFloat(8, color.b)
        ..setFloat(9, color.a);
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.x, size.y),
        Paint()..shader = shader,
      );
      return;
    }
    _paintFallback(canvas, size.x, size.y, origin, k, color);
  }

  static const _bayer = [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5];

  void _paintFallback(
    Canvas canvas,
    double w,
    double h,
    Offset o,
    double k,
    Color color,
  ) {
    const cell = GameConfig.splashCell;
    final maxD = [
      Offset(o.dx, o.dy),
      Offset(w - o.dx, o.dy),
      Offset(o.dx, h - o.dy),
      Offset(w - o.dx, h - o.dy),
    ].map((v) => v.distance).reduce(math.max);
    final spread =
        1 - math.pow(1 - (k / GameConfig.splashSpread).clamp(0.0, 1.0), 3);
    final radius = maxD * spread + cell;
    final glob = k < GameConfig.splashSpread
        ? 1.0
        : 1 - (k - GameConfig.splashSpread) / (1 - GameConfig.splashSpread);
    const band = 70.0;
    final path = Path();
    var iy = 0;
    for (var y = 0.0; y < h; y += cell, iy++) {
      var ix = 0;
      for (var x = 0.0; x < w; x += cell, ix++) {
        final d = (Offset(x + cell / 2, y + cell / 2) - o).distance;
        if (d > radius) continue;
        var loc = glob * (1 - 0.4 * d / maxD);
        if (d > radius - band) loc *= (radius - d) / band;
        if ((_bayer[(iy & 3) * 4 + (ix & 3)] + 0.5) / 16 < loc) {
          path.addRect(Rect.fromLTWH(x, y, cell, cell));
        }
      }
    }
    canvas.drawPath(path, Paint()..color = color);
  }
}
