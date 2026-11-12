import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

import '../../../core/assets/app_assets.dart';
import '../../../core/external_link.dart';
import '../../../core/layout/device_layout.dart';
import '../../../core/layout/scroll_anchor.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/app_banner.dart';
import '../../../core/widgets/pixel_image.dart';
import '../minigame_controller.dart';
import '../widgets/minigame_widgets.dart';

/// Teks layar kontak (mockup `minigame-kontak-mockup.html`).
abstract final class ContactText {
  static const String finalScore = 'SKOR AKHIR';
  static const String bestScoreLabel = 'SKOR TERTINGGI';
  static const String unit = 'poin dalam 2 menit';
  static const String best = 'Skor tertinggi';
  static const String record = 'REKOR BARU!';
  static const String skippedLabel = 'MINI GAME · DEBUG RUSH';
  static const String skippedTitle = 'Halo, terima kasih sudah mampir!';
  static const String skippedBody =
      'Kamu melewati permainan. Kapan pun ingin mencoba, tekan Main di bawah.';
  static const String contactsTitle = 'KONTAK';
  static const String contactsBody =
      'Terima kasih sudah berkunjung! Mau ngobrol soal game atau kolaborasi? '
      'Temukan aku di sini.';
  static const String play = 'MAIN';
  static const String playAgain = 'MAIN LAGI';
}

class ContactLink {
  const ContactLink(this.icon, this.name, this.handle, this.url);

  final PixelIcons icon;
  final String name;
  final String handle;
  final String url;
}

const contactLinks = [
  ContactLink(
    PixelIcons.github,
    'GitHub',
    'github.com/riyal77',
    'https://github.com/riyal77',
  ),
  ContactLink(
    PixelIcons.instagram,
    'Instagram',
    '@ryalnaufal',
    'https://www.instagram.com/ryalnaufal/',
  ),
  ContactLink(
    PixelIcons.facebook,
    'Facebook',
    'facebook.com/ryal.naufal',
    'https://web.facebook.com/ryal.naufal/',
  ),
  ContactLink(
    PixelIcons.email,
    'Email',
    'ryal_naufal@yahoo.com',
    'mailto:ryal_naufal@yahoo.com',
  ),
];

/// Layar kontak memakai dua kolom di layar mendatar (HP landscape, tablet
/// landscape); selain itu satu kolom (tablet portrait: maksimal 600 di
/// tengah).
bool useTwoColumns(BuildContext context) {
  final size = MediaQuery.sizeOf(context);
  return switch (DeviceLayout.fromSize(size)) {
    DeviceLayout.phoneLandscape => true,
    DeviceLayout.tablet => size.width > size.height,
    _ => false,
  };
}

/// Layar kontak (hadiah): kartu hasil, KONTAK, tombol MAIN LAGI / MAIN.
///
/// - HP portrait, layar depan Flip, tablet portrait: satu kolom bergulir.
/// - HP landscape & tablet landscape: dua kolom; kolom kiri (kartu hasil +
///   tombol) tetap di tempat, hanya kolom kanan (KONTAK) yang di-scroll.
class ContactScreen extends StatefulWidget {
  const ContactScreen({
    super.key,
    required this.controller,
    required this.scroll,
    required this.onPlay,
  });

  final MiniGameController controller;
  final ScrollController scroll;
  final VoidCallback onPlay;

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  final _keys = List.generate(3, (i) => GlobalKey(debugLabel: 'contact$i'));
  late final _anchor = ScrollAnchorKeeper(widget.scroll, () => _keys);
  DeviceLayout? _layout;

  /// Tinggi isi kolom KONTAK (dua kolom), untuk menyejajarkan kolom kiri.
  double? _contactsHeight;

  void _onContactsHeight(double height) {
    if (mounted && height != _contactsHeight) {
      setState(() => _contactsHeight = height);
    }
  }

  @override
  Widget build(BuildContext context) {
    final layout = DeviceLayout.of(context);
    if (_layout != null && _layout != layout) _anchor.layoutChanged();
    _layout = layout;

    final ctl = widget.controller;
    final pad = MediaQuery.paddingOf(context);
    final banner = AppBanner.totalHeight(context);
    final cover = layout.isCover;
    final h = switch (layout) {
      DeviceLayout.tablet => 24.0,
      DeviceLayout.flipCover => 16.0,
      _ => 20.0,
    };

    final twoColumns = useTwoColumns(context);
    final result = KeyedSubtree(
      key: _keys[0],
      child: ctl.hasPlayed
          ? _ResultCard(
              result: ctl.lastResult,
              bestScore: ctl.bestScore,
              scoreSize: switch (layout) {
                DeviceLayout.phoneLandscape => 64,
                DeviceLayout.flipCover => 60,
                _ => 76,
              },
              expand: twoColumns,
            )
          : _SkippedCard(expand: twoColumns),
    );
    final contacts = KeyedSubtree(key: _keys[1], child: const _Contacts());
    final cta = KeyedSubtree(
      key: _keys[2],
      child: GamePrimaryButton(
        label: ctl.hasPlayed ? ContactText.playAgain : ContactText.play,
        icon: PixelIcons.navMiniGame,
        onPressed: widget.onPlay,
      ),
    );

    Widget scrollView({
      required Widget child,
      required EdgeInsets padding,
      ScrollController? controller,
      String? storageKey,
    }) {
      return SingleChildScrollView(
        key: storageKey == null ? null : PageStorageKey<String>(storageKey),
        controller: controller,
        padding: padding,
        child: child,
      );
    }

    final Widget body;
    if (!twoColumns) {
      body = scrollView(
        controller: widget.scroll,
        storageKey: 'minigame-contact',
        padding: EdgeInsets.fromLTRB(
          h,
          banner + (cover ? 16 : 20),
          h,
          pad.bottom + 30,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                result,
                SizedBox(height: cover ? 22 : 26),
                contacts,
                SizedBox(height: cover ? 22 : 26),
                cta,
              ],
            ),
          ),
        ),
      );
    } else {
      final top = banner + 16;
      body = Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Row(
            // Kedua kolom setinggi layar (kolom kanan di-scroll).
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Kolom kiri tetap di tempat, puncak dan dasarnya sejajar
              // kolom kontak (paling tinggi setinggi layar): kartu memanjang,
              // tombol di dasar. Scroll sendiri hanya bila layar terlalu
              // pendek untuk isinya.
              Expanded(
                flex: 92,
                child: LayoutBuilder(
                  builder: (context, box) {
                    final padding = EdgeInsets.fromLTRB(
                      h,
                      top,
                      0,
                      pad.bottom + 24,
                    );
                    final target = math.min(
                      box.maxHeight - padding.vertical,
                      _contactsHeight ?? 0,
                    );
                    return scrollView(
                      padding: padding,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: math.max(0, target),
                        ),
                        child: IntrinsicHeight(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(child: result),
                              const SizedBox(height: 18),
                              cta,
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(width: layout.isTablet ? 32 : 24),
              Expanded(
                flex: 108,
                child: scrollView(
                  controller: widget.scroll,
                  storageKey: 'minigame-contact-side',
                  padding: EdgeInsets.fromLTRB(0, top, h, pad.bottom + 24),
                  child: _HeightReporter(
                    onHeight: _onContactsHeight,
                    child: contacts,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return NotificationListener<UserScrollNotification>(
      onNotification: (n) {
        if (n.metrics.axis == Axis.vertical) _anchor.userScrolled();
        return false;
      },
      child: body,
    );
  }
}

// ---------------------------------------------------------------------------
// Kartu hasil
// ---------------------------------------------------------------------------

/// Bingkai tebal 2 px fg (seperti kartu Programming di About Me) dengan grid
/// halus yang memudar ke bawah.
class _FramedCard extends StatelessWidget {
  const _FramedCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: c.shadow2,
            offset: const Offset(0, 14),
            blurRadius: 30,
            spreadRadius: -18,
          ),
        ],
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.fg, width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: CustomPaint(
        painter: _GridPainter(c.fg),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
          child: child,
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  _GridPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    // Garis fg 7% dengan opacity 0,5, memudar sampai 85% tinggi kartu.
    final paint = Paint()
      ..strokeWidth = 1
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withValues(alpha: 0.035), color.withValues(alpha: 0)],
        stops: const [0, 0.85],
      ).createShader(Offset.zero & size);
    const step = 12.0;
    for (var x = step - 0.5; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = step - 0.5; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter oldDelegate) => oldDelegate.color != color;
}

/// Kartu skor. [result] null (kunjungan berikutnya): menampilkan skor
/// tertinggi tanpa animasi.
class _ResultCard extends StatefulWidget {
  const _ResultCard({
    required this.result,
    required this.bestScore,
    required this.scoreSize,
    this.expand = false,
  });

  final GameResult? result;
  final int bestScore;
  final double scoreSize;

  /// Kartu mengisi tinggi yang diberikan (kolom kiri dua kolom): baris
  /// skor tertinggi turun ke dasar kartu.
  final bool expand;

  @override
  State<_ResultCard> createState() => _ResultCardState();
}

class _ResultCardState extends State<_ResultCard>
    with TickerProviderStateMixin {
  late final AnimationController _count = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  late final AnimationController _badge = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  );

  @override
  void initState() {
    super.initState();
    final r = widget.result;
    if (r == null || r.countedUp) {
      _count.value = 1;
      _badge.value = 1;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final r = widget.result;
    if (r == null || r.countedUp) return;
    r.countedUp = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      // Reduced motion: langsung angka akhir, badge tanpa animasi.
      _count.value = 1;
      _badge.value = 1;
      return;
    }
    _count.forward().whenCompleteOrCancel(() {
      if (mounted) _badge.forward();
    });
  }

  @override
  void dispose() {
    _count.dispose();
    _badge.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final r = widget.result;
    final target = r?.score ?? widget.bestScore;
    final tabular = const [FontFeature.tabularFigures()];

    return _FramedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 26,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    r == null
                        ? ContactText.bestScoreLabel
                        : ContactText.finalScore,
                    style: AppText.label(11, color: c.fg2),
                  ),
                ),
                if (r != null && r.isRecord)
                  AnimatedBuilder(
                    animation: _badge,
                    builder: (context, child) {
                      final t = _badge.value;
                      if (t == 0) return const SizedBox.shrink();
                      return Opacity(
                        opacity: t.clamp(0.0, 1.0),
                        child: Transform.scale(
                          scale: 0.4 + 0.6 * _pop.transform(t),
                          alignment: Alignment.centerRight,
                          child: child,
                        ),
                      );
                    },
                    child: const _RecordBadge(),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          AnimatedBuilder(
            animation: _count,
            builder: (context, _) {
              final shown =
                  (target * Curves.easeOutCubic.transform(_count.value))
                      .round();
              return Semantics(
                label: '$target poin',
                excludeSemantics: true,
                child: Text(
                  '$shown',
                  style: AppText.pixel(
                    widget.scoreSize,
                    weight: FontWeight.w600,
                    height: 0.95,
                    color: c.fg,
                    letterSpacing: -0.01 * widget.scoreSize,
                  ).copyWith(fontFeatures: tabular),
                ),
              );
            },
          ),
          const SizedBox(height: 2),
          Text(
            ContactText.unit,
            style: AppText.pixel(15, weight: FontWeight.w500, color: c.fg2),
          ),
          if (widget.expand) const Spacer(),
          if (r != null) ...[
            const SizedBox(height: 14),
            CustomPaint(
              painter: _DashedLinePainter(c.line),
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        ContactText.best,
                        style: AppText.body(13, color: c.fg2),
                      ),
                    ),
                    Text(
                      '${widget.bestScore}',
                      style: AppText.pixel(
                        20,
                        weight: FontWeight.w600,
                        color: c.fg,
                      ).copyWith(fontFeatures: tabular),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Setara cubic-bezier(.2, 1.6, .4, 1) di mockup (sedikit memantul).
  static const _pop = Cubic(0.2, 1.6, 0.4, 1);
}

/// Badge "REKOR BARU!" (ikon piala, gaya badge GGJ, latar btn).
class _RecordBadge extends StatelessWidget {
  const _RecordBadge();

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      height: 26,
      padding: const EdgeInsets.only(left: 7, right: 9),
      decoration: BoxDecoration(
        color: c.btn,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PixelIcon(PixelIcons.trophy, size: 15, color: c.onBtn),
          const SizedBox(width: 6),
          Text(
            ContactText.record,
            style: AppText.label(10, color: c.onBtn, spacing: 0.06),
          ),
        ],
      ),
    );
  }
}

/// Garis putus-putus 1,5 px di tepi atas.
class _DashedLinePainter extends CustomPainter {
  _DashedLinePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5;
    const dash = 5.0, gap = 4.0;
    for (var x = 0.0; x < size.width; x += dash + gap) {
      canvas.drawLine(
        Offset(x, 0.75),
        Offset((x + dash).clamp(0, size.width), 0.75),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DashedLinePainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Setelah Lewati (belum pernah bermain): sapaan pengganti kartu hasil.
class _SkippedCard extends StatelessWidget {
  const _SkippedCard({this.expand = false});

  /// Lihat [_ResultCard.expand]; isi tetap di atas.
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return _FramedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ContactText.skippedLabel,
            style: AppText.label(11, color: c.fg2),
          ),
          const SizedBox(height: 6),
          Text(
            ContactText.skippedTitle,
            style: AppText.pixel(
              24,
              weight: FontWeight.w600,
              height: 1.1,
              color: c.fg,
            ),
          ),
          const SizedBox(height: 6),
          Text(ContactText.skippedBody, style: AppText.paragraph(color: c.fg2)),
          if (expand) const Spacer(),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// KONTAK
// ---------------------------------------------------------------------------

/// Melaporkan tinggi [child] setelah layout (setelah frame selesai).
class _HeightReporter extends SingleChildRenderObjectWidget {
  const _HeightReporter({required this.onHeight, required super.child});

  final ValueChanged<double> onHeight;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderHeightReporter(onHeight);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderHeightReporter renderObject,
  ) {
    renderObject.onHeight = onHeight;
  }
}

class _RenderHeightReporter extends RenderProxyBox {
  _RenderHeightReporter(this.onHeight);

  ValueChanged<double> onHeight;
  double? _reported;

  @override
  void performLayout() {
    super.performLayout();
    final height = size.height;
    if (height == _reported) return;
    _reported = height;
    SchedulerBinding.instance.addPostFrameCallback((_) => onHeight(height));
  }
}

class _Contacts extends StatelessWidget {
  const _Contacts();

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const GameSectionTitle(ContactText.contactsTitle, bottom: 8),
        Text(ContactText.contactsBody, style: AppText.paragraph(color: c.fg2)),
        const SizedBox(height: 12),
        for (final (i, link) in contactLinks.indexed) ...[
          if (i > 0) const SizedBox(height: 8),
          _ContactRow(link),
        ],
      ],
    );
  }
}

/// Satu baris kontak; seluruh baris bisa diketuk.
class _ContactRow extends StatelessWidget {
  const _ContactRow(this.link);

  final ContactLink link;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: c.shadow1,
            offset: const Offset(0, 1),
            blurRadius: 2,
          ),
        ],
      ),
      child: Material(
        color: c.surface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => openExternal(link.url),
          borderRadius: BorderRadius.circular(12),
          child: Semantics(
            link: true,
            label: '${link.name}, ${link.handle}',
            excludeSemantics: true,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 64),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: c.bg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: PixelIcon(link.icon, size: 24, color: c.fg),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            link.name,
                            style: AppText.pixel(
                              17,
                              weight: FontWeight.w600,
                              height: 1.15,
                              color: c.fg,
                            ),
                          ),
                          Text(
                            link.handle,
                            style: AppText.body(
                              12.5,
                              height: 1.4,
                              color: c.fg2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    PixelIcon(
                      PixelIcons.externalLink,
                      size: 18,
                      color: c.muted,
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
