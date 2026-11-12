import 'dart:math' as math;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../../core/assets/app_assets.dart';
import '../../../core/layout/device_layout.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/pixel_image.dart';
import '../game/bug_shapes.dart';
import '../game/debug_rush_game.dart';
import '../game/game_config.dart';
import '../game/game_session.dart';
import '../widgets/minigame_widgets.dart';

/// Teks layar bermain.
abstract final class PlayText {
  static const String timeUp = 'Waktu habis!';
  static const String paused = 'Permainan dijeda';
  static const String resume = 'LANJUTKAN';
  static const String end = 'Akhiri permainan';
  static const String openFlip = 'Buka Flip-mu untuk bermain';
}

/// Layar bermain Debug Rush: [GameWidget] mengisi seluruh halaman (App Banner
/// disembunyikan, navigasi tetap tampil), dengan overlay Flutter di atasnya:
/// skor di tengah atas, hitung mundur "3, 2, 1", "Waktu habis!", dialog
/// jeda, dan pesan layar depan Flip.
///
/// Jeda: tombol kembali Android (lewat halaman), pindah tab, pindah
/// aplikasi, tombol home, dan Flip ditutup di tengah permainan memunculkan
/// dialog Lanjutkan / Akhiri permainan. Di layar depan Flip permainan tidak
/// berjalan; setelah Lanjutkan ditekan di layar depan, tampil pesan "Buka
/// Flip-mu untuk bermain" sampai Flip dibuka.
class PlayScreen extends StatefulWidget {
  const PlayScreen({super.key, required this.session, required this.onEnd});

  final GameSession session;

  /// "Akhiri permainan" dari dialog jeda.
  final VoidCallback onEnd;

  @override
  State<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends State<PlayScreen> {
  late final DebugRushGame _game = DebugRushGame(session: widget.session);

  /// Aplikasi tersembunyi (tombol home, pindah aplikasi): jeda.
  late final AppLifecycleListener _lifecycle = AppLifecycleListener(
    onHide: widget.session.pauseIfRunning,
  );

  /// Tata letak sebelumnya layar depan Flip (null = belum ada).
  bool? _wasCover;

  @override
  void initState() {
    super.initState();
    _lifecycle; // mulai mendengarkan
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Tab lain dibuka (shell mematikan TickerMode tab yang tidak aktif).
    if (!TickerMode.valuesOf(context).enabled) widget.session.pauseIfRunning();
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final layout = DeviceLayout.of(context);
    final cover = layout.isCover;
    // Flip ditutup di tengah permainan: jeda + dialog. (Menekan Mulai di
    // layar depan tidak menjeda; cukup pesan "Buka Flip-mu".)
    if (_wasCover == false && cover) widget.session.pauseIfRunning();
    _wasCover = cover;

    final c = AppColors.of(context);
    _game
      ..palette = GamePalette.from(
        c,
        dark: Theme.of(context).brightness == Brightness.dark,
      )
      ..reduceMotion = MediaQuery.disableAnimationsOf(context)
      ..blocked = cover;

    final pad = MediaQuery.paddingOf(context);
    final landscape = layout.isLandscape;
    final scoreSize = switch (layout) {
      DeviceLayout.phoneLandscape => 32.0,
      DeviceLayout.tablet => 48.0,
      _ => 40.0,
    };
    final scoreTop = pad.top + (landscape ? 12 : 10);

    return LayoutBuilder(
      builder: (context, box) {
        final area = Rect.fromLTRB(
          GameConfig.areaSideInset,
          scoreTop + scoreSize + GameConfig.areaBelowScore,
          box.maxWidth - GameConfig.areaSideInset,
          box.maxHeight -
              pad.bottom -
              (layout.usesBottomBar
                  ? GameConfig.areaAboveNav
                  : GameConfig.areaBottomInset),
        );
        if (!cover) {
          widget.session.setArea(
            PlayArea(
              rect: area,
              bugSize: switch (layout) {
                DeviceLayout.phoneLandscape => GameConfig.bugSizePhoneLandscape,
                DeviceLayout.tablet => GameConfig.bugSizeTablet,
                _ => GameConfig.bugSizePhonePortrait,
              },
              maxBugs: switch (layout) {
                DeviceLayout.phoneLandscape => GameConfig.maxBugsPhoneLandscape,
                DeviceLayout.tablet => GameConfig.maxBugsTablet,
                _ => GameConfig.maxBugsPhonePortrait,
              },
            ),
          );
        }

        return ListenableBuilder(
          listenable: widget.session,
          builder: (context, _) {
            final s = widget.session;
            return Stack(
              fit: StackFit.expand,
              children: [
                Listener(
                  behavior: HitTestBehavior.opaque,
                  onPointerDown: (e) {
                    if (!_game.blocked) {
                      s.pointerDown(e.pointer, e.localPosition);
                    }
                  },
                  onPointerUp: (e) => s.pointerUp(e.pointer),
                  onPointerCancel: (e) => s.pointerUp(e.pointer),
                  child: GameWidget(game: _game),
                ),
                if (!cover) ...[
                  Positioned(
                    top: scoreTop,
                    left: 0,
                    right: 0,
                    // Skor ikut bergeser saat guncangan.
                    child: Transform.translate(
                      offset: _game.shake,
                      child: _ScoreHud(
                        score: s.score,
                        size: scoreSize,
                        overSplash: s.frozen,
                      ),
                    ),
                  ),
                  Positioned.fromRect(
                    rect: area,
                    child: IgnorePointer(child: _phaseText(s, layout)),
                  ),
                ],
                if (s.paused)
                  _PauseDialog(
                    onResume: () => s.setPaused(false),
                    onEnd: widget.onEnd,
                  )
                else if (cover)
                  const _OpenFlipMessage(),
              ],
            );
          },
        );
      },
    );
  }

  Widget _phaseText(GameSession s, DeviceLayout layout) {
    final c = AppColors.of(context);
    final landscape = layout.isLandscape;
    switch (s.phase) {
      case PlayPhase.countdown:
        // Mengecil dari 1,35× sambil muncul, memudar di 25% terakhir.
        final p = s.countdownStepProgress;
        final reduce = MediaQuery.disableAnimationsOf(context);
        final scale = reduce
            ? 1.0
            : 1.35 - 0.35 * (1 - math.pow(1 - (p / 0.3).clamp(0.0, 1.0), 3));
        final opacity = p > 0.75 ? 1 - (p - 0.75) / 0.25 : 1.0;
        return Center(
          child: Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: Transform.scale(
              scale: scale,
              child: Text(
                '${s.countdownNumber}',
                style: AppText.pixel(
                  landscape ? 80 : 96,
                  weight: FontWeight.w600,
                  height: 1,
                  color: c.fg,
                ),
              ),
            ),
          ),
        );
      case PlayPhase.timeUp || PlayPhase.ended:
        return Center(
          child: Text(
            PlayText.timeUp,
            style: AppText.pixel(
              landscape ? 34 : 40,
              weight: FontWeight.w600,
              color: c.fg,
            ),
          ),
        );
      case PlayPhase.running:
        return const SizedBox.shrink();
    }
  }
}

/// Skor di tengah atas tanpa label dan latar (Pixelify 600, angka
/// tabular). Melompat kecil saat bertambah. Di atas splash, warnanya
/// dibalik (blend difference) agar tetap terbaca.
class _ScoreHud extends StatelessWidget {
  const _ScoreHud({
    required this.score,
    required this.size,
    required this.overSplash,
  });

  final int score;
  final double size;
  final bool overSplash;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final base = AppText.pixel(
      size,
      weight: FontWeight.w600,
      height: 1,
    ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
    final style = overSplash
        ? base.copyWith(
            foreground: Paint()
              ..color = const Color(0xFFFFFFFF)
              ..blendMode = BlendMode.difference,
          )
        : base.copyWith(color: c.fg);
    final reduce = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      label: 'Skor $score',
      excludeSemantics: true,
      child: Center(
        child: TweenAnimationBuilder<double>(
          key: ValueKey(score),
          tween: Tween(
            begin: score == 0 || reduce ? 1 : GameConfig.scoreBumpScale,
            end: 1,
          ),
          duration: Duration(
            milliseconds: (GameConfig.scoreBumpSeconds * 1000).round(),
          ),
          curve: Curves.easeOut,
          builder: (context, scale, child) =>
              Transform.scale(scale: scale, child: child),
          child: Text('$score', style: style),
        ),
      ),
    );
  }
}

/// Dialog jeda: Lanjutkan atau Akhiri permainan.
class _PauseDialog extends StatelessWidget {
  const _PauseDialog({required this.onResume, required this.onEnd});

  final VoidCallback onResume;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return ColoredBox(
      color: c.bg.withValues(alpha: 0.82),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 340),
            child: Container(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: c.cardShadow,
              ),
              foregroundDecoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: c.fg, width: 2),
              ),
              child: Semantics(
                scopesRoute: true,
                namesRoute: true,
                explicitChildNodes: true,
                label: PlayText.paused,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      PlayText.paused,
                      textAlign: TextAlign.center,
                      style: AppText.pixel(
                        22,
                        weight: FontWeight.w600,
                        color: c.fg,
                      ),
                    ),
                    const SizedBox(height: 16),
                    GamePrimaryButton(
                      label: PlayText.resume,
                      onPressed: onResume,
                    ),
                    const SizedBox(height: 8),
                    GameSecondaryButton(
                      label: PlayText.end,
                      onPressed: onEnd,
                      pixelFont: true,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Layar depan Flip: game tidak dimainkan.
class _OpenFlipMessage extends StatelessWidget {
  const _OpenFlipMessage();

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return ColoredBox(
      color: c.bg,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: PixelIcon(PixelIcons.navMiniGame, size: 32, color: c.fg),
              ),
              const SizedBox(height: 14),
              Text(
                PlayText.openFlip,
                textAlign: TextAlign.center,
                style: AppText.pixel(20, weight: FontWeight.w600, color: c.fg),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
