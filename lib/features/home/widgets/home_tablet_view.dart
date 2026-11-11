import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/glass.dart';
import '../../../core/widgets/theme_toggle_button.dart';
import '../../../data/project.dart';
import '../home_content.dart';
import 'featured_projects.dart';
import 'home_morph_view.dart'
    show heroDescriptionStyle, heroNameStyle, heroTaglineStyle;
import 'home_parts.dart';
import 'mini_game_cta.dart';
import 'skills_section.dart';

/// Beranda tablet (wireframe `hp_tablet.png`): tanpa morphing dan tanpa
/// App Banner. Hero penuh dengan foto potret 160 di kiri, SKILLS grid 4 × 2,
/// FEATURED PROJECTS 2 kolom (portrait) / 4 sebaris (landscape), tombol tema
/// mengambang tetap di kanan atas.
class HomeTabletView extends StatelessWidget {
  const HomeTabletView({
    super.key,
    required this.landscape,
    required this.scrollController,
    required this.carouselController,
    required this.carouselIndex,
    required this.sectionKeys,
    required this.featured,
    required this.onOpenProject,
    required this.onPlay,
  });

  final bool landscape;
  final ScrollController scrollController;
  final ScrollController carouselController;
  final ValueNotifier<int> carouselIndex;
  final List<GlobalKey> sectionKeys;
  final List<Project> featured;
  final ValueChanged<Project> onOpenProject;
  final VoidCallback onPlay;

  static const double _hp = 24;

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.paddingOf(context);
    final c = AppColors.of(context);
    return Stack(
      children: [
        Positioned.fill(
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                KeyedSubtree(
                  key: sectionKeys[0],
                  child: _TabletHero(statusBar: pad.top),
                ),
                const SizedBox(height: 28),
                KeyedSubtree(
                  key: sectionKeys[1],
                  child: const SkillsSection(
                    layout: SkillsLayout.grid,
                    horizontalPadding: _hp,
                  ),
                ),
                const SizedBox(height: 24),
                KeyedSubtree(
                  key: sectionKeys[2],
                  child: FeaturedProjectsSection(
                    projects: featured,
                    layout: FeaturedLayout.grid,
                    columns: landscape ? 4 : 2,
                    controller: carouselController,
                    index: carouselIndex,
                    onOpen: onOpenProject,
                    horizontalPadding: _hp,
                  ),
                ),
                Padding(
                  key: sectionKeys[3],
                  padding: const EdgeInsets.fromLTRB(_hp, 24, _hp, 0),
                  child: MiniGameCta(onPlay: onPlay, horizontal: true),
                ),
                SizedBox(height: pad.bottom + 32),
              ],
            ),
          ),
        ),
        // Tombol tema mengambang, posisi tetap, kaca buram.
        Positioned(
          top: pad.top + 16,
          right: 16,
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
              child: const ThemeToggleButton(),
            ),
          ),
        ),
      ],
    );
  }
}

class _TabletHero extends StatelessWidget {
  const _TabletHero({required this.statusBar});

  final double statusBar;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
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
            // Kanan 72: ruang untuk tombol tema mengambang.
            padding: EdgeInsets.fromLTRB(24, statusBar + 32, 72, 40),
            // Kolom teks menentukan tinggi; foto potret mengikuti tingginya.
            child: Stack(
              children: [
                const Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: AvatarBox(width: 160),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 160 + 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(
                          HomeContent.name,
                          style: heroNameStyle(34, c.fg),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        HomeContent.role,
                        style: AppText.label(13, color: c.fg2, spacing: 0.06),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        HomeContent.tagline,
                        style: heroTaglineStyle(15, c.fg),
                      ),
                      const SizedBox(height: 12),
                      ConstrainedBox(
                        // Batas teks hero tablet 640 (wireframe).
                        constraints: const BoxConstraints(maxWidth: 640),
                        child: Text(
                          HomeContent.description,
                          style: heroDescriptionStyle(15, 1.6, c.fg2),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const SocialButtons(),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Positioned(left: 0, right: 0, bottom: 0, child: DitherBand()),
        ],
      ),
    );
  }
}
