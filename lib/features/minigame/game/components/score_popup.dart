import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/painting.dart' show TextStyle;

import '../../../../core/theme/app_text.dart';
import '../bug_shapes.dart';
import '../debug_rush_game.dart';
import '../game_config.dart';

/// Teks "+N" di posisi bug: naik 24 dp lalu memudar dalam 0,5 detik.
/// Makin besar nilainya, makin besar dan makin kontras teksnya.
class ScorePopup extends Component with HasGameReference<DebugRushGame> {
  ScorePopup(this.origin, this.points) : super(priority: 3);

  final Offset origin;
  final int points;
  double _age = 0;

  @override
  void update(double dt) {
    _age += dt;
    if (_age >= GameConfig.popupSeconds) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final k = (_age / GameConfig.popupSeconds).clamp(0.0, 1.0);
    final alpha = k < 0.4 ? 1.0 : 1 - (k - 0.4) / 0.6;
    final rise = GameConfig.popupRise * (1 - math.pow(1 - k, 3));
    final text = TextPaint(
      style: TextStyle(
        fontFamily: AppFonts.pixel,
        fontWeight: FontWeight.w600,
        fontSize: GamePalette.popupSize(points),
        color: game.palette.popupColor(points).withValues(alpha: alpha),
      ),
    );
    text.render(
      canvas,
      '+$points',
      Vector2(origin.dx, origin.dy - rise),
      anchor: Anchor.center,
    );
  }
}
