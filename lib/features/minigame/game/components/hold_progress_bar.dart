import 'dart:ui';

import 'package:flame/components.dart';

import '../bug_shapes.dart';
import '../debug_rush_game.dart';
import '../game_config.dart';
import '../game_session.dart';

/// Bar progres Bug 4: tampil selama ditahan (dan saat runtuh), lebar =
/// ukuran dasar, tinggi 6, 10 dp di bawah bug, terisi kiri → kanan dalam
/// 2 detik.
class HoldProgressBar extends Component with HasGameReference<DebugRushGame> {
  HoldProgressBar(this.bug);

  final Bug bug;

  @override
  void render(Canvas canvas) {
    final collapsing = bug.collapsing != null;
    if (!bug.holding && !collapsing) return;
    final session = game.session;
    final base = session.area?.bugSize ?? GameConfig.bugSizePhonePortrait;
    final half = session.sizeOf(bug) / 2;
    paintHoldBar(
      canvas,
      topCenter: bug.position + Offset(0, half + GameConfig.holdBarGap),
      width: base,
      progress: collapsing ? 1 : bug.holdProgress,
      palette: game.palette,
    );
  }
}
