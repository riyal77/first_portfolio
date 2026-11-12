import 'package:flutter/material.dart';

import '../../../core/layout/device_layout.dart';
import '../../../core/layout/scroll_anchor.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/app_banner.dart';
import '../game/bug_shapes.dart';
import '../game/game_config.dart';
import '../widgets/minigame_widgets.dart';

/// Teks layar ajakan.
abstract final class IntroText {
  static const String title = 'DEBUG RUSH';
  static const String byline = 'GAME ORISINAL · RYAL NAUFAL';
  static const String howToTitle = 'CARA MAIN';
  static const String howTo =
      'Bug bermunculan di layar. Hancurkan sebelum meledak dan kumpulkan '
      'skor setinggi mungkin.';
  static const String bugsTitle = 'JENIS BUG';
  static const String start = 'MULAI';
  static const String skip = 'Lewati untuk melihat kontak';

  /// Pembukaan aplikasi berikutnya, setelah pernah bermain.
  static const String playAgain = 'MAIN LAGI';
  static const String seeContact = 'Lihat skor dan kontak';
}

/// Layar ajakan: judul, pratinjau arena, CARA MAIN, JENIS BUG, tombol utama
/// dan sekunder.
///
/// Kunjungan pertama: MULAI / "Lewati untuk melihat kontak.". Setelah
/// aplikasi dibuka ulang dan pernah bermain: MAIN LAGI / "Lihat Skor &
/// Kontak" (label dari halaman).
///
/// - Satu kolom (urutan sama dengan HP portrait): HP portrait & landscape,
///   layar depan Flip, tablet portrait (maksimal 600 di tengah).
/// - Tablet landscape: dua kolom yang dasarnya sejajar (kiri judul,
///   pratinjau memanjang, tombol; kanan cara main dan jenis bug, rata
///   bawah).
class IntroScreen extends StatefulWidget {
  const IntroScreen({
    super.key,
    required this.scroll,
    required this.primaryLabel,
    required this.secondaryLabel,
    required this.onPrimary,
    required this.onSecondary,
  });

  final ScrollController scroll;
  final String primaryLabel;
  final String secondaryLabel;

  /// Mulai permainan (hitung mundur).
  final VoidCallback onPrimary;

  /// Ke layar kontak.
  final VoidCallback onSecondary;

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  final _keys = List.generate(5, (i) => GlobalKey(debugLabel: 'intro$i'));
  late final _anchor = ScrollAnchorKeeper(widget.scroll, () => _keys);
  DeviceLayout? _layout;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final layout = DeviceLayout.fromSize(size);
    if (_layout != null && _layout != layout) _anchor.layoutChanged();
    _layout = layout;

    final pad = MediaQuery.paddingOf(context);
    final cover = layout.isCover;
    final twoColumns = layout.isTablet && size.width > size.height;
    final h = switch (layout) {
      DeviceLayout.tablet => 24.0,
      DeviceLayout.flipCover => 16.0,
      _ => 20.0,
    };
    final endPad = pad.bottom + (layout.usesBottomBar ? 30 : 24);
    final arenaHeight = cover ? 104.0 : 130.0;

    final header = _section(0, _Header(cover: cover));
    Widget arena({bool expand = false}) => _section(
      1,
      _ArenaPreview(height: arenaHeight, expand: expand),
      top: cover ? 14 : 16,
    );
    Widget howTo({double top = 26}) => _section(
      2,
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const GameSectionTitle(IntroText.howToTitle),
          Text(
            IntroText.howTo,
            style: AppText.paragraph(color: AppColors.of(context).fg2),
          ),
        ],
      ),
      top: top,
    );
    final bugs = _section(
      3,
      const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [GameSectionTitle(IntroText.bugsTitle), _BugCards()],
      ),
      top: 26,
    );
    final actions = _section(
      4,
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GamePrimaryButton(
            label: widget.primaryLabel,
            onPressed: widget.onPrimary,
          ),
          const SizedBox(height: 8),
          GameSecondaryButton(
            label: widget.secondaryLabel,
            onPressed: widget.onSecondary,
            pixelFont: true,
          ),
        ],
      ),
      top: 22,
    );

    final Widget body = twoColumns
        ? Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              // Dasar kedua kolom sejajar: pratinjau arena memanjang di
              // kiri; cara main dan jenis bug turun ke dasar di kanan.
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 92,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          header,
                          Expanded(child: arena(expand: true)),
                          actions,
                        ],
                      ),
                    ),
                    const SizedBox(width: 32),
                    Expanded(
                      flex: 108,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [const Spacer(), howTo(top: 0), bugs],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        : Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [header, arena(), howTo(), bugs, actions],
              ),
            ),
          );

    return NotificationListener<UserScrollNotification>(
      onNotification: (n) {
        if (n.metrics.axis == Axis.vertical) _anchor.userScrolled();
        return false;
      },
      child: SingleChildScrollView(
        key: const PageStorageKey<String>('minigame-intro'),
        controller: widget.scroll,
        padding: EdgeInsets.fromLTRB(
          h,
          AppBanner.totalHeight(context) + (cover ? 16 : 24),
          h,
          endPad,
        ),
        child: body,
      ),
    );
  }

  Widget _section(int i, Widget child, {double top = 0}) => Padding(
    key: _keys[i],
    padding: EdgeInsets.only(top: top),
    child: child,
  );
}

class _Header extends StatelessWidget {
  const _Header({required this.cover});

  final bool cover;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            IntroText.title,
            style: AppText.pixel(
              cover ? 34 : 40,
              weight: FontWeight.w600,
              height: 1.05,
              color: c.fg,
              letterSpacing: 0.4,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          IntroText.byline,
          style: AppText.label(10.5, color: c.fg2, spacing: 0.12),
        ),
      ],
    );
  }
}

/// Pratinjau arena: contoh skor dan beberapa bug dengan ukuran berbeda
/// (bug membesar menuju ledakan). [expand]: tinggi minimal [height],
/// memanjang mengisi ruang yang diberikan.
class _ArenaPreview extends StatelessWidget {
  const _ArenaPreview({required this.height, this.expand = false});

  final double height;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return ExcludeSemantics(
      child: Container(
        height: expand ? null : height,
        constraints: expand ? BoxConstraints(minHeight: height) : null,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.line),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [c.surface, Color.lerp(c.surface, c.bg, 0.6)!],
          ),
        ),
        // Bug digambar dengan CustomPaint (bukan LayoutBuilder) supaya
        // tinggi intrinsiknya bisa dihitung untuk kolom yang disejajarkan.
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _ArenaBugsPainter(
                  gamePaletteOf(context),
                  scale: height / 130,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('SKOR', style: AppText.label(9.5, color: c.fg2)),
                  const SizedBox(height: 2),
                  Text(
                    '48',
                    style: AppText.pixel(
                      20,
                      weight: FontWeight.w600,
                      color: c.fg,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArenaBugsPainter extends CustomPainter {
  _ArenaBugsPainter(this.palette, {required this.scale});

  final GamePalette palette;
  final double scale;

  /// (jenis, ukuran, posisi tengah x, posisi tengah y) dalam pecahan.
  static const _bugs = [
    (BugKind.bug1, 30.0, 0.455, 0.33),
    (BugKind.bug4, 26.0, 0.92, 0.21),
    (BugKind.bug3, 52.0, 0.786, 0.6),
    (BugKind.bug2, 34.0, 0.31, 0.76),
    (BugKind.bug1, 22.0, 0.605, 0.8),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (final (kind, s, fx, fy) in _bugs) {
      paintBug(
        canvas,
        center: Offset(fx * size.width, fy * size.height),
        size: s * scale,
        kind: kind,
        palette: palette,
      );
    }
  }

  @override
  bool shouldRepaint(_ArenaBugsPainter oldDelegate) =>
      oldDelegate.palette != palette || oldDelegate.scale != scale;
}

/// 4 kartu jenis bug, 2 kolom × 2 baris.
class _BugCards extends StatelessWidget {
  const _BugCards();

  @override
  Widget build(BuildContext context) {
    Widget row(BugKind a, BugKind b) => IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: _BugCard(a)),
          const SizedBox(width: 10),
          Expanded(child: _BugCard(b)),
        ],
      ),
    );
    return Column(
      children: [
        row(BugKind.bug1, BugKind.bug2),
        const SizedBox(height: 10),
        row(BugKind.bug3, BugKind.bug4),
      ],
    );
  }
}

class _BugCard extends StatelessWidget {
  const _BugCard(this.kind);

  final BugKind kind;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: c.shadow1,
            offset: const Offset(0, 1),
            blurRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          BugGlyph(kind, size: 36),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  kind.name,
                  style: AppText.pixel(
                    16,
                    weight: FontWeight.w600,
                    height: 1.2,
                    color: c.fg,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${kind.howTo} · +${kind.score}',
                  style: AppText.body(11.5, height: 1.4, color: c.fg2),
                ),
                if (kind.isHold) ...[
                  const SizedBox(height: 6),
                  const HoldBar(progress: 0.55),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
