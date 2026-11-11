import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/glass.dart';
import '../../../core/widgets/theme_toggle_button.dart';
import '../../../data/project.dart';
import '../home_content.dart';
import 'featured_projects.dart';
import 'home_parts.dart';
import 'mini_game_cta.dart';
import 'skills_section.dart';

/// Ukuran hero per tata letak yang bermorfosis (HP portrait, HP landscape,
/// layar depan Flip). Angka diambil dari mockup Beranda dan wireframe Flip.
class MorphSpec {
  const MorphSpec({
    required this.horizontal,
    required this.avatar,
    required this.avatarEnd,
    required this.bannerHeight,
    required this.nameSize,
    required this.padding,
    required this.nameGap,
    required this.roleGap,
    required this.taglineGap,
    required this.taglineSize,
    required this.descGap,
    required this.descSize,
    required this.descHeight,
    required this.descMaxWidth,
    required this.socialsGap,
    required this.socialSize,
    required this.socialIcon,
    required this.socialSpacing,
    required this.socialRadius,
  });

  /// Landscape: foto di kiri, teks di kanan (rata kiri).
  final bool horizontal;

  /// Sisi foto di hero (landscape: lebar; tinggi mengikuti kolom teks).
  final double avatar;

  /// Sisi foto di App Banner.
  final double avatarEnd;

  /// Tinggi App Banner (tanpa status bar).
  final double bannerHeight;

  final double nameSize;

  /// Padding hero (bagian atas belum termasuk status bar).
  final EdgeInsets padding;

  final double nameGap;
  final double roleGap;
  final double taglineGap;
  final double taglineSize;
  final double descGap;
  final double descSize;
  final double descHeight;
  final double descMaxWidth;
  final double socialsGap;
  final double socialSize;
  final double socialIcon;
  final double socialSpacing;
  final double socialRadius;

  /// Ukuran nama di App Banner.
  static const double nameEnd = 18;

  static const portrait = MorphSpec(
    horizontal: false,
    avatar: 112,
    avatarEnd: 36,
    bannerHeight: 60,
    nameSize: 24,
    padding: EdgeInsets.fromLTRB(22, 28, 22, 34),
    nameGap: 16,
    roleGap: 6,
    taglineGap: 12,
    taglineSize: 13.5,
    descGap: 10,
    descSize: 14,
    descHeight: 1.6,
    descMaxWidth: 340,
    socialsGap: 18,
    socialSize: 52,
    socialIcon: 24,
    socialSpacing: 12,
    socialRadius: 12,
  );

  static const landscape = MorphSpec(
    horizontal: true,
    avatar: 104,
    avatarEnd: 32,
    bannerHeight: 60,
    nameSize: 26,
    padding: EdgeInsets.fromLTRB(20, 20, 20, 30),
    nameGap: 0,
    roleGap: 5,
    taglineGap: 8,
    taglineSize: 13.5,
    descGap: 6,
    descSize: 13.5,
    descHeight: 1.55,
    descMaxWidth: 560,
    socialsGap: 12,
    socialSize: 44,
    socialIcon: 22,
    socialSpacing: 10,
    socialRadius: 10,
  );

  /// Layar depan Flip: hero ringkas, foto 72, App Banner 52.
  static const cover = MorphSpec(
    horizontal: false,
    avatar: 72,
    avatarEnd: 32,
    bannerHeight: 52,
    nameSize: 22,
    padding: EdgeInsets.fromLTRB(20, 16, 20, 26),
    nameGap: 10,
    roleGap: 4,
    taglineGap: 8,
    taglineSize: 12.5,
    descGap: 6,
    descSize: 13,
    descHeight: 1.5,
    descMaxWidth: 360,
    socialsGap: 12,
    socialSize: 44,
    socialIcon: 22,
    socialSpacing: 10,
    socialRadius: 10,
  );
}

/// Posisi awal foto & nama (koordinat konten, scroll = 0) dan tinggi hero.
@immutable
class _HeroMetrics {
  const _HeroMetrics(this.avatar, this.name, this.nameHeight, this.heroHeight);

  final Rect avatar;
  final Offset name;
  final double nameHeight;
  final double heroHeight;

  @override
  bool operator ==(Object other) =>
      other is _HeroMetrics &&
      other.avatar == avatar &&
      other.name == name &&
      other.nameHeight == nameHeight &&
      other.heroHeight == heroHeight;

  @override
  int get hashCode => Object.hash(avatar, name, nameHeight, heroHeight);
}

double _clamp01(double v) => v < 0 ? 0 : (v > 1 ? 1 : v);
double _lerp(double a, double b, double t) => a + (b - a) * t;
double _smoothstep(double t) => t * t * (3 - 2 * t);

/// Beranda HP & layar depan Flip: hero bermorfosis menjadi App Banner.
///
/// Rentang = tinggi hero − status bar − tinggi banner. Foto dan nama
/// berpindah ke banner (smoothstep, tidak ikut terbawa scroll); jabatan,
/// tagline, deskripsi, dan tombol sosial memudar di 60% pertama; latar kaca
/// banner muncul di 40% terakhir. Scroll ke atas = kebalikannya.
class HomeMorphView extends StatefulWidget {
  const HomeMorphView({
    super.key,
    required this.spec,
    required this.scrollController,
    required this.skillsController,
    required this.carouselController,
    required this.carouselIndex,
    required this.sectionKeys,
    required this.featured,
    required this.onOpenProject,
    required this.onPlay,
  });

  final MorphSpec spec;
  final ScrollController scrollController;
  final ScrollController skillsController;
  final ScrollController carouselController;
  final ValueNotifier<int> carouselIndex;

  /// Kunci bagian: hero, skills, featured, ajakan (untuk memetakan posisi
  /// scroll per bagian saat tata letak berganti).
  final List<GlobalKey> sectionKeys;

  final List<Project> featured;
  final ValueChanged<Project> onOpenProject;
  final VoidCallback onPlay;

  @override
  State<HomeMorphView> createState() => _HomeMorphViewState();
}

class _HomeMorphViewState extends State<HomeMorphView> {
  final _stackKey = GlobalKey();
  final _avatarSlotKey = GlobalKey();
  final _nameSlotKey = GlobalKey();

  final _metrics = ValueNotifier<_HeroMetrics?>(null);

  /// Progres morphing 0..1.
  final _progress = ValueNotifier<double>(0);

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_updateProgress);
    _metrics.addListener(_updateProgress);
  }

  @override
  void didUpdateWidget(HomeMorphView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scrollController != widget.scrollController) {
      oldWidget.scrollController.removeListener(_updateProgress);
      widget.scrollController.addListener(_updateProgress);
    }
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_updateProgress);
    _metrics.dispose();
    _progress.dispose();
    super.dispose();
  }

  double get _statusBar => MediaQuery.paddingOf(context).top;

  double get _range {
    final m = _metrics.value;
    if (m == null) return 1;
    final r = m.heroHeight - _statusBar - widget.spec.bannerHeight;
    return r < 1 ? 1 : r;
  }

  double get _scrollOffset {
    final c = widget.scrollController;
    return c.hasClients && c.positions.length == 1 ? c.offset : 0;
  }

  void _updateProgress() {
    if (!mounted) return;
    _progress.value = _clamp01(_scrollOffset / _range);
  }

  /// Mengukur posisi slot foto & nama setelah layout (koordinat konten).
  void _measure() {
    if (!mounted) return;
    final stack = _stackKey.currentContext?.findRenderObject() as RenderBox?;
    final hero =
        widget.sectionKeys[0].currentContext?.findRenderObject() as RenderBox?;
    final av = _avatarSlotKey.currentContext?.findRenderObject() as RenderBox?;
    final nm = _nameSlotKey.currentContext?.findRenderObject() as RenderBox?;
    if (stack == null || hero == null || av == null || nm == null) return;
    if (!stack.hasSize || !hero.hasSize || !av.hasSize || !nm.hasSize) return;
    final s = _scrollOffset;
    final avTopLeft = av.localToGlobal(Offset.zero, ancestor: stack);
    final nmTopLeft = nm.localToGlobal(Offset.zero, ancestor: stack);
    _metrics.value = _HeroMetrics(
      (avTopLeft + Offset(0, s)) & av.size,
      nmTopLeft + Offset(0, s),
      nm.size.height,
      hero.size.height,
    );
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
    final spec = widget.spec;
    final pad = MediaQuery.paddingOf(context);
    final endPad = pad.bottom + (spec.horizontal ? 24 : 34);

    return Stack(
      key: _stackKey,
      children: [
        Positioned.fill(
          child: SingleChildScrollView(
            controller: widget.scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                KeyedSubtree(
                  key: widget.sectionKeys[0],
                  child: _MorphHero(
                    spec: spec,
                    statusBar: pad.top,
                    avatarSlotKey: _avatarSlotKey,
                    nameSlotKey: _nameSlotKey,
                    progress: _progress,
                  ),
                ),
                const SizedBox(height: 24),
                KeyedSubtree(
                  key: widget.sectionKeys[1],
                  child: SkillsSection(
                    layout: spec.horizontal
                        ? SkillsLayout.oneRow
                        : SkillsLayout.twoRows,
                    controller: widget.skillsController,
                  ),
                ),
                const SizedBox(height: 24),
                KeyedSubtree(
                  key: widget.sectionKeys[2],
                  child: FeaturedProjectsSection(
                    projects: widget.featured,
                    layout: spec.horizontal
                        ? FeaturedLayout.carouselLandscape
                        : FeaturedLayout.carousel,
                    controller: widget.carouselController,
                    index: widget.carouselIndex,
                    onOpen: widget.onOpenProject,
                  ),
                ),
                Padding(
                  key: widget.sectionKeys[3],
                  padding: EdgeInsets.fromLTRB(
                    20,
                    spec.horizontal ? 24 : 28,
                    20,
                    0,
                  ),
                  child: MiniGameCta(
                    onPlay: widget.onPlay,
                    horizontal: spec.horizontal,
                  ),
                ),
                SizedBox(height: endPad),
              ],
            ),
          ),
        ),
        // Lapisan yang bermorfosis, di atas konten.
        Positioned.fill(
          child: _MorphOverlay(
            spec: spec,
            statusBar: pad.top,
            metrics: _metrics,
            progress: _progress,
          ),
        ),
      ],
    );
  }
}

/// Elemen hero yang memudar di 60% pertama progres.
class _Fade extends StatelessWidget {
  const _Fade({required this.progress, required this.child});

  final ValueListenable<double> progress;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: progress,
      child: child,
      builder: (context, p, child) {
        final f = 1 - _clamp01(p / 0.6);
        return IgnorePointer(
          ignoring: f <= 0,
          child: Opacity(
            opacity: f,
            child: Transform.translate(
              offset: Offset(0, (1 - f) * -6),
              child: child,
            ),
          ),
        );
      },
    );
  }
}

class _MorphHero extends StatelessWidget {
  const _MorphHero({
    required this.spec,
    required this.statusBar,
    required this.avatarSlotKey,
    required this.nameSlotKey,
    required this.progress,
  });

  final MorphSpec spec;
  final double statusBar;
  final GlobalKey avatarSlotKey;
  final GlobalKey nameSlotKey;
  final ValueListenable<double> progress;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final s = spec;
    final align = s.horizontal ? TextAlign.left : TextAlign.center;

    // Slot nama: tak terlihat (nama yang tampil ada di lapisan morphing),
    // tetapi tetap dibacakan pembaca layar sebagai judul halaman.
    final nameSlot = Semantics(
      header: true,
      child: Opacity(
        key: nameSlotKey,
        opacity: 0,
        alwaysIncludeSemantics: true,
        child: Text(
          HomeContent.name,
          maxLines: 1,
          softWrap: false,
          style: heroNameStyle(s.nameSize, c.fg),
        ),
      ),
    );

    final texts = <Widget>[
      nameSlot,
      _Fade(
        progress: progress,
        child: Padding(
          padding: EdgeInsets.only(top: s.roleGap),
          child: Text(
            HomeContent.role,
            style: AppText.label(12, color: c.fg2, spacing: 0.06),
          ),
        ),
      ),
      _Fade(
        progress: progress,
        child: Padding(
          padding: EdgeInsets.only(top: s.taglineGap),
          child: Text(
            HomeContent.tagline,
            textAlign: align,
            style: heroTaglineStyle(s.taglineSize, c.fg),
          ),
        ),
      ),
      _Fade(
        progress: progress,
        child: Padding(
          padding: EdgeInsets.only(top: s.descGap),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: s.descMaxWidth),
            child: Text(
              HomeContent.description,
              textAlign: align,
              style: heroDescriptionStyle(s.descSize, s.descHeight, c.fg2),
            ),
          ),
        ),
      ),
      _Fade(
        progress: progress,
        child: Padding(
          padding: EdgeInsets.only(top: s.socialsGap),
          child: SocialButtons(
            size: s.socialSize,
            iconSize: s.socialIcon,
            gap: s.socialSpacing,
            radius: s.socialRadius,
          ),
        ),
      ),
    ];

    final Widget content;
    if (s.horizontal) {
      // Kolom teks menentukan tinggi (min. 150); slot foto mengikutinya.
      content = ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 150),
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: SizedBox(key: avatarSlotKey, width: s.avatar),
            ),
            Padding(
              // Kanan 56: ruang untuk tombol tema di kanan atas.
              padding: EdgeInsets.only(left: s.avatar + 20, right: 56),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: texts,
              ),
            ),
          ],
        ),
      );
    } else {
      content = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(key: avatarSlotKey, width: s.avatar, height: s.avatar),
          SizedBox(height: s.nameGap),
          ...texts,
        ],
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [c.bg, c.surface],
        ),
      ),
      child: Stack(
        children: [
          Padding(
            padding: s.padding.copyWith(top: s.padding.top + statusBar),
            child: content,
          ),
          const Positioned(left: 0, right: 0, bottom: 0, child: DitherBand()),
        ],
      ),
    );
  }
}

/// Gaya nama di hero (Pixelify 600, letter-spacing 0,01 em).
TextStyle heroNameStyle(double size, Color color) => AppText.pixel(
  size,
  weight: FontWeight.w600,
  height: 1.15,
  letterSpacing: size * 0.01,
  color: color,
);

/// Gaya tagline di hero (Pixelify 500). Pixelify tidak punya versi miring,
/// jadi tagline tegak; tanda kutip tetap menandainya sebagai kutipan.
TextStyle heroTaglineStyle(double size, Color fg) => AppText.pixel(
  size,
  weight: FontWeight.w500,
  height: 1.35,
  color: fg.withValues(alpha: 0.85),
);

/// Gaya deskripsi singkat di hero (Pixelify 400).
TextStyle heroDescriptionStyle(double size, double height, Color color) =>
    AppText.pixel(size, height: height, color: color);

class _MorphOverlay extends StatelessWidget {
  const _MorphOverlay({
    required this.spec,
    required this.statusBar,
    required this.metrics,
    required this.progress,
  });

  final MorphSpec spec;
  final double statusBar;
  final ValueListenable<_HeroMetrics?> metrics;
  final ValueListenable<double> progress;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final st = statusBar;
    final bh = spec.bannerHeight;
    final end = spec.avatarEnd;

    return AnimatedBuilder(
      animation: Listenable.merge([metrics, progress]),
      builder: (context, _) {
        final m = metrics.value;
        final p = progress.value;
        final e = _smoothstep(p);
        // Latar kaca banner muncul di 40% terakhir.
        final bp = _clamp01((p - 0.6) / 0.4);

        final children = <Widget>[];

        if (bp > 0) {
          children.add(
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: st + bh,
              child: IgnorePointer(
                child: Opacity(
                  opacity: bp,
                  child: Glass(
                    border: Border(bottom: BorderSide(color: c.glassLine)),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            ),
          );
        }

        if (m != null) {
          // Foto: dari slot hero ke banner (kiri 16, tengah vertikal).
          final a1 = Rect.fromLTWH(16, st + (bh - end) / 2, end, end);
          final a = Rect.lerp(m.avatar, a1, e)!;
          children.add(
            Positioned.fromRect(
              rect: a,
              child: IgnorePointer(
                child: AvatarBox(
                  width: a.width,
                  height: a.height,
                  radius: _lerp(14, 8, e),
                ),
              ),
            ),
          );

          // Nama: mengecil 24 → 18 dan pindah ke samping foto di banner.
          final k1 = MorphSpec.nameEnd / spec.nameSize;
          final n1 = Offset(16 + end + 12, st + bh / 2 - m.nameHeight * k1 / 2);
          final n = Offset.lerp(m.name, n1, e)!;
          final k = _lerp(1, k1, e);
          children.add(
            Positioned(
              left: 0,
              top: 0,
              child: IgnorePointer(
                child: ExcludeSemantics(
                  child: Transform(
                    transform: Matrix4.translationValues(n.dx, n.dy, 0)
                      ..scaleByDouble(k, k, 1, 1),
                    child: Text(
                      HomeContent.name,
                      maxLines: 1,
                      softWrap: false,
                      style: heroNameStyle(spec.nameSize, c.fg),
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        // Tombol tema: mengambang berlatar kaca, lalu masuk ke banner dan
        // kehilangan latarnya sendiri.
        const size = 44.0;
        final top = _lerp(st + 16, st + (bh - size) / 2, e);
        final right = _lerp(16, 10, e);
        final ownBg = 1 - bp;
        children.add(
          Positioned(
            top: top,
            right: right,
            child: Stack(
              children: [
                if (ownBg > 0)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Opacity(
                        opacity: ownBg,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: c.shadow2,
                                offset: const Offset(0, 6),
                                blurRadius: 16,
                                spreadRadius: -6,
                              ),
                            ],
                          ),
                          child: Glass(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: c.glassLine),
                            child: const SizedBox.expand(),
                          ),
                        ),
                      ),
                    ),
                  ),
                const ThemeToggleButton(size: size),
              ],
            ),
          ),
        );

        return Stack(children: children);
      },
    );
  }
}
