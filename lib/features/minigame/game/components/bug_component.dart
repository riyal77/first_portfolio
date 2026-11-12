import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../bug_shapes.dart';
import '../debug_rush_game.dart';
import '../game_config.dart';
import '../game_session.dart';
import 'hold_progress_bar.dart';

/// Lapisan bug: menjaga satu [BugComponent] untuk setiap bug di
/// [GameSession.bugs] (ditambah saat muncul, dilepas saat hancur atau
/// meledak).
class BugsLayer extends Component with HasGameReference<DebugRushGame> {
  BugsLayer() : super(priority: 0);

  final Map<int, BugComponent> _components = {};

  @override
  void update(double dt) {
    final bugs = game.session.bugs;
    final alive = <int>{};
    for (final bug in bugs) {
      alive.add(bug.id);
      if (!_components.containsKey(bug.id)) {
        final c = BugComponent(bug);
        _components[bug.id] = c;
        add(c);
      }
    }
    _components.removeWhere((id, c) {
      if (alive.contains(id)) return false;
      c.removeFromParent();
      return true;
    });
  }
}

/// Satu bug: digambar dengan kode ([paintBug]), membesar, berkedip, bergetar
/// saat Bug 4 ditahan. Semua keadaannya dibaca dari [Bug] di sesi, sehingga
/// komponen ini hanya penggambar.
class BugComponent extends Component with HasGameReference<DebugRushGame> {
  BugComponent(this.bug);

  final Bug bug;
  final _random = math.Random();

  @override
  Future<void> onLoad() async {
    if (bug.kind.isHold) add(HoldProgressBar(bug));
  }

  /// Getar ±1,4 dp selama Bug 4 ditahan (mati bila "kurangi gerakan").
  Offset get jitter {
    if (!bug.holding || game.reduceMotion) return Offset.zero;
    const j = GameConfig.holdJitter;
    return Offset(
      (_random.nextDouble() - 0.5) * 2 * j,
      (_random.nextDouble() - 0.5) * 2 * j,
    );
  }

  @override
  void render(Canvas canvas) {
    final session = game.session;
    paintBug(
      canvas,
      center: bug.position + jitter,
      size: session.sizeOf(bug),
      kind: bug.kind,
      palette: game.palette,
      alpha: session.alphaOf(bug),
      hatch: bug.hatch,
      sidesLost: bug.sidesLost,
    );
  }
}
