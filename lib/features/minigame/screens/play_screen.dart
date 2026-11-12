import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../core/assets/app_assets.dart';
import '../../../core/layout/device_layout.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/app_banner.dart';
import '../../../core/widgets/pixel_image.dart';
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
  static const String trialLabel = 'LAYAR BERMAIN SEMENTARA';
  static const String trialFinish = 'Selesai (uji coba)';
}

/// Layar bermain. Area permainan mengisi ruang di bawah App Banner dan di
/// luar navigasi; teks dan UI (skor, hitung mundur, "Waktu habis!", dialog
/// jeda, pesan layar depan Flip) berupa widget Flutter di atasnya.
///
/// **Sementara (branch `miniGame`):** belum ada game. Setelah hitung mundur
/// tampil tombol "Selesai (uji coba)" yang memberi skor acak; sisa waktu
/// juga tetap berjalan sehingga jeda bisa diuji. Di branch `debugRush`
/// bagian tengah diganti `GameWidget` Flame.
///
/// Waktu dimajukan oleh [Ticker] milik layar ini. Ticker otomatis berhenti
/// saat tab lain aktif ([TickerMode]) dan saat aplikasi di latar belakang
/// (tidak ada frame); selang besar setelahnya diabaikan sehingga permainan
/// tidak bergeser. Pindah tab, pindah aplikasi, atau tombol home juga
/// memunculkan dialog jeda, sama seperti tombol kembali Android.
class PlayScreen extends StatefulWidget {
  const PlayScreen({
    super.key,
    required this.session,
    required this.trialScore,
    required this.onEnd,
  });

  final GameSession session;

  /// Skor acak untuk tombol "Selesai (uji coba)".
  final int Function() trialScore;

  /// "Akhiri permainan" dari dialog jeda.
  final VoidCallback onEnd;

  @override
  State<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends State<PlayScreen>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration? _last;

  /// Layar depan Flip: permainan tidak berjalan.
  bool _blocked = false;

  /// Aplikasi tersembunyi (tombol home, pindah aplikasi): jeda.
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick)..start();
    _lifecycle = AppLifecycleListener(onHide: widget.session.pauseIfRunning);
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
    _ticker.dispose();
    super.dispose();
  }

  void _tick(Duration elapsed) {
    final last = _last;
    _last = elapsed;
    if (last == null || _blocked) return;
    final dt = (elapsed - last).inMicroseconds / Duration.microsecondsPerSecond;
    if (dt > GameConfig.maxFrameGap) return;
    widget.session.advance(dt);
  }

  @override
  Widget build(BuildContext context) {
    final layout = DeviceLayout.of(context);
    _blocked = layout.isCover;
    final pad = MediaQuery.paddingOf(context);
    final top = AppBanner.totalHeight(context);

    return ListenableBuilder(
      listenable: widget.session,
      builder: (context, _) {
        final s = widget.session;
        return Padding(
          padding: EdgeInsets.only(top: top, bottom: pad.bottom),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (_blocked)
                const _OpenFlipMessage()
              else ...[
                _phaseView(s),
                if (s.phase != PlayPhase.countdown)
                  Positioned(
                    left: layout.isCover ? 16 : 20,
                    top: 16,
                    child: _ScoreHud(score: s.score),
                  ),
                if (s.paused)
                  _PauseDialog(
                    onResume: () => s.setPaused(false),
                    onEnd: widget.onEnd,
                  ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _phaseView(GameSession s) {
    final c = AppColors.of(context);
    return switch (s.phase) {
      PlayPhase.countdown => Center(
        child: Text(
          '${s.countdownNumber}',
          key: ValueKey('countdown${s.countdownNumber}'),
          style: AppText.pixel(112, weight: FontWeight.w600, color: c.fg),
        ),
      ),
      PlayPhase.running => _TrialArea(
        remaining: s.remaining,
        onFinish: () => s.endRoundNow(widget.trialScore()),
      ),
      PlayPhase.timeUp || PlayPhase.ended => Center(
        child: Text(
          PlayText.timeUp,
          style: AppText.pixel(40, weight: FontWeight.w600, color: c.fg),
        ),
      ),
    };
  }
}

/// Skor di kiri atas area permainan (satu-satunya HUD).
class _ScoreHud extends StatelessWidget {
  const _ScoreHud({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Semantics(
      label: 'Skor $score',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('SKOR', style: AppText.label(11, color: c.fg2)),
          const SizedBox(height: 2),
          Text(
            '$score',
            style: AppText.pixel(
              30,
              weight: FontWeight.w600,
              height: 1,
              color: c.fg,
            ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
          ),
        ],
      ),
    );
  }
}

/// Isi sementara selama 2 menit: tombol uji coba + sisa waktu (hanya
/// untuk pengujian; game sungguhan tidak menampilkan sisa waktu).
class _TrialArea extends StatelessWidget {
  const _TrialArea({required this.remaining, required this.onFinish});

  final double remaining;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final secs = remaining.ceil();
    final time = '${secs ~/ 60}:${(secs % 60).toString().padLeft(2, '0')}';
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                PlayText.trialLabel,
                textAlign: TextAlign.center,
                style: AppText.label(10.5, color: c.fg2),
              ),
              const SizedBox(height: 8),
              Text(
                'Sisa waktu (uji coba): $time',
                textAlign: TextAlign.center,
                style: AppText.body(
                  13,
                  color: c.fg2,
                ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
              ),
              const SizedBox(height: 16),
              GameSecondaryButton(
                label: PlayText.trialFinish,
                onPressed: onFinish,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dialog jeda (tombol kembali Android): Lanjutkan atau Akhiri permainan.
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
                    GameSecondaryButton(label: PlayText.end, onPressed: onEnd),
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
    return Center(
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
    );
  }
}
