import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/pixel_image.dart';
import '../home_content.dart';
import 'home_parts.dart';
import 'snap_physics.dart';

/// Susunan bagian SKILLS.
enum SkillsLayout {
  /// HP portrait & Flip: grid 2 baris yang digeser, kolom 196.
  twoRows,

  /// HP landscape: 1 baris yang digeser, lebar mengikuti isi.
  oneRow,

  /// Tablet: grid 4 × 2 tanpa digeser.
  grid,
}

class SkillsSection extends StatelessWidget {
  const SkillsSection({
    super.key,
    required this.layout,
    this.controller,
    this.horizontalPadding = 20,
  });

  final SkillsLayout layout;
  final ScrollController? controller;
  final double horizontalPadding;

  static const double _gap = 10;
  static const double _columnWidth = 196;

  /// Lebar minimum kartu di grid tablet. Bila 4 kolom tidak muat
  /// (tablet portrait), grid diganti 2 baris yang digeser dengan kolom
  /// selebar ini agar teks panjang ("Best Story & Illustration") lega.
  static const double _tabletMinTile = 220;

  @override
  Widget build(BuildContext context) {
    if (layout != SkillsLayout.grid) return _build(layout, _columnWidth);
    return LayoutBuilder(
      builder: (context, cons) {
        const cols = 4;
        final inner = cons.maxWidth - horizontalPadding * 2;
        final w = (inner - _gap * (cols - 1)) / cols;
        return w >= _tabletMinTile
            ? _build(SkillsLayout.grid, w)
            : _build(SkillsLayout.twoRows, _tabletMinTile);
      },
    );
  }

  /// [width]: lebar kolom (twoRows) atau lebar kartu (grid).
  Widget _build(SkillsLayout layout, double width) {
    final skills = HomeContent.skills;
    final hp = horizontalPadding;
    final Widget body = switch (layout) {
      SkillsLayout.twoRows => SingleChildScrollView(
        controller: controller,
        scrollDirection: Axis.horizontal,
        physics: SnapToItemPhysics(itemExtent: width + _gap),
        padding: EdgeInsets.fromLTRB(hp, 2, hp, 14),
        child: Row(
          children: [
            for (var col = 0; col < (skills.length / 2).ceil(); col++) ...[
              if (col > 0) const SizedBox(width: _gap),
              SizedBox(
                width: width,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _SkillTile(skills[col * 2], height: 52),
                    if (col * 2 + 1 < skills.length) ...[
                      const SizedBox(height: _gap),
                      _SkillTile(skills[col * 2 + 1], height: 52),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      SkillsLayout.oneRow => SingleChildScrollView(
        controller: controller,
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.fromLTRB(hp, 2, hp, 14),
        child: Row(
          children: [
            for (var i = 0; i < skills.length; i++) ...[
              if (i > 0) const SizedBox(width: _gap),
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 150),
                child: _SkillTile(skills[i], height: 48, compactRight: true),
              ),
            ],
          ],
        ),
      ),
      SkillsLayout.grid => Padding(
        padding: EdgeInsets.fromLTRB(hp, 2, hp, 14),
        child: Wrap(
          spacing: _gap,
          runSpacing: _gap,
          children: [
            for (final s in skills)
              SizedBox(width: width, child: _SkillTile(s, height: 52)),
          ],
        ),
      ),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          'SKILLS',
          padding: EdgeInsets.fromLTRB(hp, 0, hp, 12),
          trailing: layout == SkillsLayout.grid
              ? null
              : const SectionHint('GESER ›'),
        ),
        body,
      ],
    );
  }
}

class _SkillTile extends StatelessWidget {
  const _SkillTile(
    this.item, {
    required this.height,
    this.compactRight = false,
  });

  final SkillItem item;
  final double height;
  final bool compactRight;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final award = item.award;
    final fg = award ? c.onBtn : c.fg;
    final iconColor = award ? c.onBtn : c.fg;
    return Container(
      height: height,
      padding: EdgeInsets.only(left: 12, right: compactRight ? 16 : 12),
      decoration: BoxDecoration(
        color: award ? c.btn : c.surface,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: c.shadow1,
            offset: const Offset(0, 1),
            blurRadius: 2,
          ),
          BoxShadow(
            color: c.shadow2,
            offset: const Offset(0, 4),
            blurRadius: 10,
            spreadRadius: -6,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: award ? c.onBtn.withValues(alpha: 0.14) : c.bg,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: item.icon != null
                ? PixelIcon(item.icon!, size: 20, color: iconColor)
                : Image.asset(
                    item.logo!,
                    width: 20,
                    height: 20,
                    color: iconColor,
                    filterQuality: FilterQuality.medium,
                    excludeFromSemantics: true,
                  ),
          ),
          const SizedBox(width: 11),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.visible,
                  style: AppText.pixel(
                    15,
                    weight: FontWeight.w600,
                    height: 1.2,
                    color: fg,
                  ),
                ),
                Text(
                  item.subtitle,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.visible,
                  style: AppText.body(
                    11.5,
                    height: 1.3,
                    color: award ? fg.withValues(alpha: 0.72) : c.fg2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
