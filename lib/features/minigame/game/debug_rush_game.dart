import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import 'bug_shapes.dart';
import 'components/bug_component.dart';
import 'components/debris.dart';
import 'components/score_popup.dart';
import 'components/splash_effect.dart';
import 'game_config.dart';
import 'game_session.dart';

/// Debug Rush di Flame.
///
/// Aturan dan keadaan permainan ada di [session] (murni Dart, dipegang di
/// luar widget). Game ini memajukan waktu sesi setiap frame, lalu
/// menggambar bug dan efek: serpihan, "+N", splash, guncangan kamera, dan
/// getaran. Skor, hitung mundur, "Waktu habis!", dan dialog dibuat dengan
/// widget Flutter di atasnya (lihat `play_screen.dart`).
///
/// Koordinat dunia = koordinat layar bermain (dp), titik (0, 0) di kiri
/// atas.
class DebugRushGame extends FlameGame {
  DebugRushGame({required this.session});

  final GameSession session;

  /// Warna dari tema aktif; diperbarui layar bermain saat tema berganti.
  GamePalette palette = GamePalette.from(AppColors.light, dark: false);

  /// "Kurangi gerakan" aktif: tanpa guncangan, getar Bug 4, dan putaran
  /// serpihan.
  bool reduceMotion = false;

  /// Layar depan Flip: permainan tidak berjalan.
  bool blocked = false;

  /// Geseran guncangan saat ini (skor Flutter ikut bergeser; dibaca saat
  /// overlay dibangun ulang setiap frame oleh sesi).
  Offset shake = Offset.zero;

  final _random = math.Random();
  double _shakeAge = double.infinity;
  late final DebrisLayer _debris;

  @override
  Color backgroundColor() => const Color(0x00000000);

  @override
  Future<void> onLoad() async {
    camera.viewfinder.anchor = Anchor.topLeft;
    _debris = DebrisLayer();
    await world.addAll([BugsLayer(), _debris, SplashEffect()]);
  }

  @override
  void update(double dt) {
    // Selang besar = game sempat berhenti (pindah tab, latar belakang):
    // waktu tidak dihitung, permainan berlanjut dari posisi terakhir.
    final gap = dt > GameConfig.maxFrameGap;
    if (!gap && !blocked) session.advance(dt);
    for (final e in session.takeEvents()) {
      _handle(e);
    }
    _updateShake(gap ? 0 : dt);
    super.update(gap ? 0 : dt);
  }

  void _handle(GameEvent e) {
    switch (e) {
      case BugTouched():
        HapticFeedback.selectionClick();
      case HatchPeeled(:final position, :final size):
        _debris.peel(position, size);
      case SideLost(:final position, :final size, :final side):
        _debris.dropSide(position, size, side);
      case BugDestroyed(:final position, :final shatterSize, :final points):
        _debris.shatter(position, shatterSize);
        world.add(ScorePopup(position, points));
        HapticFeedback.lightImpact();
      case BugExploded():
        if (!reduceMotion) _shakeAge = 0;
        HapticFeedback.heavyImpact();
      case BugsFaded(:final bugs):
        if (bugs.isNotEmpty) world.add(FadingBugs(bugs));
    }
  }

  /// Guncangan ±6 dp yang meluruh selama 0,3 detik.
  void _updateShake(double dt) {
    _shakeAge += dt;
    var offset = Offset.zero;
    if (_shakeAge < GameConfig.shakeSeconds && !reduceMotion) {
      final a =
          GameConfig.shakeAmplitude * (1 - _shakeAge / GameConfig.shakeSeconds);
      offset = Offset(
        (_random.nextDouble() - 0.5) * 2 * a,
        (_random.nextDouble() - 0.5) * 2 * a,
      );
    }
    camera.viewfinder.position = Vector2(-offset.dx, -offset.dy);
    shake = offset;
  }
}
