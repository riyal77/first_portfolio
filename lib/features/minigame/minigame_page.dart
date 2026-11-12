import 'package:flutter/material.dart';

import '../../app/app_shell.dart';
import '../../core/widgets/app_banner.dart';
import 'minigame_controller.dart';
import 'screens/contact_screen.dart';
import 'screens/intro_screen.dart';
import 'screens/play_screen.dart';

/// Mini Game (Debug Rush): App Banner "Mini Game" + layar sesuai tahap.
///
/// - Layar ajakan: tampil setiap kali aplikasi dibuka. Kunjungan pertama
///   (atau baru pernah Lewati): MULAI / Lewati. Setelah pernah bermain:
///   MAIN LAGI / Lihat Skor & Kontak.
/// - Bermain: hitung mundur, permainan, "Waktu habis!".
/// - Layar kontak: hasil + 4 kontak + Main lagi; tetap tampil selama
///   aplikasi terbuka.
///
/// Tombol kembali Android saat bermain menjeda permainan dan menampilkan
/// pilihan Lanjutkan / Akhiri permainan. Di layar depan Flip permainan tidak
/// berjalan (pesan "Buka Flip-mu untuk bermain"), lalu dimulai atau
/// berlanjut begitu Flip dibuka.
class MiniGamePage extends StatefulWidget {
  const MiniGamePage({super.key});

  @override
  State<MiniGamePage> createState() => _MiniGamePageState();
}

class _MiniGamePageState extends State<MiniGamePage> {
  final _introScroll = ScrollController();
  final _contactScroll = ScrollController();
  MiniGameController? _controller;
  MiniGameStage? _stage;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = MiniGameScope.of(context);
    if (controller != _controller) {
      _controller?.removeListener(_onChanged);
      _controller = controller..addListener(_onChanged);
      _stage = controller.stage;
      WidgetsBinding.instance.addPostFrameCallback((_) => _syncBackHandler());
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_onChanged);
    _introScroll.dispose();
    _contactScroll.dispose();
    super.dispose();
  }

  void _onChanged() {
    final stage = _controller!.stage;
    if (stage == _stage) return;
    _stage = stage;
    if (!mounted) return;
    setState(() {});
    final shell = ShellScope.read(context);
    // Navigation bar bisa sedang tersembunyi karena layar sebelumnya
    // di-scroll; tampilkan lagi saat berganti layar.
    if (shell.tabIndex == AppTab.miniGame) shell.goToTab(AppTab.miniGame);
    _syncBackHandler();
  }

  /// Saat bermain, tombol kembali Android ditangani halaman ini (jeda).
  void _syncBackHandler() {
    if (!mounted) return;
    final playing = _controller?.stage == MiniGameStage.playing;
    ShellScope.read(context)
        .setBackHandler(AppTab.miniGame, playing ? _onBack : null);
  }

  void _onBack() {
    final session = _controller?.session;
    if (session == null) return;
    // Kembali saat dialog jeda terbuka = Lanjutkan.
    session.setPaused(!session.paused);
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller!;
    final Widget screen = switch (c.stage) {
      MiniGameStage.intro => IntroScreen(
        scroll: _introScroll,
        primaryLabel: c.hasPlayed ? IntroText.playAgain : IntroText.start,
        secondaryLabel: c.hasPlayed ? IntroText.seeContact : IntroText.skip,
        onPrimary: c.start,
        onSecondary: c.skip,
      ),
      MiniGameStage.playing => PlayScreen(
        session: c.session!,
        onEnd: c.endEarly,
      ),
      MiniGameStage.contact => ContactScreen(
        controller: c,
        scroll: _contactScroll,
        onPlay: c.start,
      ),
    };

    return Stack(
      children: [
        Positioned.fill(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            // Tiap layar mengisi seluruh halaman (bawaan: dipusatkan).
            layoutBuilder: (current, previous) =>
                Stack(fit: StackFit.expand, children: [...previous, ?current]),
            child: KeyedSubtree(key: ValueKey(c.stage), child: screen),
          ),
        ),
        // Selama bermain App Banner disembunyikan; layar hanya berisi skor.
        if (c.stage != MiniGameStage.playing)
          const Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: AppBanner(leading: BannerTitle('Mini Game')),
          ),
      ],
    );
  }
}
