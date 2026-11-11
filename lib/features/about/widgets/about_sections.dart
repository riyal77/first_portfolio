import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../core/assets/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/pixel_image.dart';
import '../../../core/widgets/project_widgets.dart';
import '../about_content.dart';

/// Judul bagian About Me (Silkscreen 13, jarak bawah 14).
class AboutSectionTitle extends StatelessWidget {
  const AboutSectionTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Semantics(
        header: true,
        child: Text(
          text,
          style: AppText.label(13, color: AppColors.of(context).fg),
        ),
      ),
    );
  }
}

/// Sub-judul kecil (Universitas, Game Engine, …).
class AboutSubtitle extends StatelessWidget {
  const AboutSubtitle(this.text, {super.key, this.first = false});

  final String text;
  final bool first;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: first ? 0 : 18, bottom: 10),
      child: Text(
        text,
        style: AppText.body(
          12.5,
          weight: FontWeight.w500,
          color: AppColors.of(context).fg2,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Perkenalan
// ---------------------------------------------------------------------------

/// Foto, nama, jabatan, tagline.
class IntroHeader extends StatelessWidget {
  const IntroHeader({super.key, this.photo = 96, this.nameSize = 24});

  final double photo;
  final double nameSize;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final img = (photo * 80 / 96).roundToDouble();
    return Row(
      children: [
        Container(
          width: photo,
          height: photo,
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: c.shadow1,
                offset: const Offset(0, 2),
                blurRadius: 4,
              ),
              BoxShadow(
                color: c.shadow2,
                offset: const Offset(0, 12),
                blurRadius: 24,
                spreadRadius: -12,
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Image.asset(
            dark ? AppImages.avatarDark : AppImages.avatarLight,
            width: img,
            height: img,
            filterQuality: FilterQuality.none,
            isAntiAlias: false,
            gaplessPlayback: true,
            semanticLabel: 'Avatar pixel Ryal Naufal',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AboutContent.name,
                style: AppText.pixel(
                  nameSize,
                  weight: FontWeight.w600,
                  height: 1.1,
                  color: c.fg,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                AboutContent.role,
                style: AppText.label(11.5, color: c.fg2, spacing: 0.06),
              ),
              const SizedBox(height: 8),
              Text(
                AboutContent.tagline,
                // Sama dengan tagline Beranda: Pixelify tegak.
                style: AppText.pixel(
                  13,
                  weight: FontWeight.w500,
                  height: 1.45,
                  color: c.fg.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Bio dua paragraf, dipotong [collapsedLines] baris dengan efek memudar,
/// lalu tombol "Read More.." / "Read Less".
class BioSection extends StatelessWidget {
  const BioSection({
    super.key,
    required this.expanded,
    this.collapsedLines = 5,
  });

  final ValueNotifier<bool> expanded;
  final int collapsedLines;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final style = AppText.paragraph(color: c.fg);
    final lineHeight = style.fontSize! * style.height!;
    final collapsedHeight = lineHeight * collapsedLines;

    final paragraphs = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < AboutContent.bio.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          Text(AboutContent.bio[i], style: style),
        ],
      ],
    );

    return ValueListenableBuilder<bool>(
      valueListenable: expanded,
      builder: (context, open, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedSize(
              duration: const Duration(milliseconds: 350),
              curve: const Cubic(0.2, 0.8, 0.2, 1),
              alignment: Alignment.topCenter,
              child: ClipRect(
                child: Stack(
                  children: [
                    if (open)
                      paragraphs
                    else
                      // Setinggi [collapsedLines] baris; sisanya sengaja
                      // meluap dan terpotong.
                      SizedBox(
                        height: collapsedHeight,
                        width: double.infinity,
                        child: OverflowBox(
                          alignment: Alignment.topLeft,
                          minHeight: 0,
                          maxHeight: double.infinity,
                          child: paragraphs,
                        ),
                      ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: 56,
                      child: IgnorePointer(
                        child: AnimatedOpacity(
                          opacity: open ? 0 : 1,
                          duration: const Duration(milliseconds: 250),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [c.bg.withValues(alpha: 0), c.bg],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Transform.translate(
              offset: const Offset(-8, 0),
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Material(
                  type: MaterialType.transparency,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => expanded.value = !open,
                    child: Semantics(
                      button: true,
                      expanded: open,
                      child: SizedBox(
                        height: 40,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8, right: 10),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                open ? 'Read Less' : 'Read More..',
                                style: AppText.pixel(
                                  16,
                                  weight: FontWeight.w600,
                                  color: c.fg,
                                ),
                              ),
                              const SizedBox(width: 4),
                              AnimatedRotation(
                                turns: open ? -0.25 : 0.25,
                                duration: const Duration(milliseconds: 250),
                                child: PixelIcon(
                                  PixelIcons.chevronRight,
                                  size: 18,
                                  color: c.fg,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// SKILLS
// ---------------------------------------------------------------------------

/// Tiga kartu kemampuan. [row]: berjajar (tablet), selain itu bertumpuk.
class SkillsCards extends StatelessWidget {
  const SkillsCards({super.key, this.row = false});

  final bool row;

  @override
  Widget build(BuildContext context) {
    final cards = [for (final s in AboutContent.skills) _SkillCard(s)];
    if (!row) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < cards.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            cards[i],
          ],
        ],
      );
    }
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < cards.length; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            Expanded(child: cards[i]),
          ],
        ],
      ),
    );
  }
}

class _SkillCard extends StatelessWidget {
  const _SkillCard(this.skill);

  final Skill skill;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final s = skill;
    final (titleSize, padding, gap) = switch (s.weight) {
      SkillWeight.main => (
        21.0,
        const EdgeInsets.fromLTRB(14, 14, 14, 13),
        9.0,
      ),
      SkillWeight.plus => (
        18.0,
        const EdgeInsets.fromLTRB(14, 14, 14, 13),
        9.0,
      ),
      SkillWeight.extra => (
        15.0,
        const EdgeInsets.fromLTRB(12, 11, 12, 11),
        7.0,
      ),
    };
    final body = Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(
              s.title,
              style: AppText.pixel(
                titleSize,
                weight: FontWeight.w600,
                height: 1.1,
                color: c.fg,
              ),
            ),
          ),
          SizedBox(height: gap),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [for (final t in s.tags) TagChip(t)],
          ),
          SizedBox(height: gap),
          Text(s.proof, style: AppText.body(12, color: c.fg2)),
        ],
      ),
    );

    return switch (s.weight) {
      // Bingkai tebal 2 px fg.
      SkillWeight.main => Container(
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: c.shadow2,
              offset: const Offset(0, 10),
              blurRadius: 24,
              spreadRadius: -14,
            ),
          ],
        ),
        // Bingkai digambar di atas kartu (inset), jadi isi tidak bergeser.
        foregroundDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.fg, width: 2),
        ),
        child: body,
      ),
      // Kartu surface biasa.
      SkillWeight.plus => Container(
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
        child: body,
      ),
      // Garis putus-putus tanpa latar.
      SkillWeight.extra => CustomPaint(
        foregroundPainter: DashedRRectPainter(color: c.line),
        child: body,
      ),
    };
  }
}

/// Bingkai sudut 12 bergaris putus-putus 1,5 px.
class DashedRRectPainter extends CustomPainter {
  DashedRRectPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const w = 1.5;
    final rrect = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(w / 2),
      const Radius.circular(12),
    );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = w;
    final path = Path()..addRRect(rrect);
    const dash = 5.0, gap = 4.0;
    for (final ui.PathMetric m in path.computeMetrics()) {
      for (var d = 0.0; d < m.length; d += dash + gap) {
        canvas.drawPath(m.extractPath(d, d + dash), paint);
      }
    }
  }

  @override
  bool shouldRepaint(DashedRRectPainter oldDelegate) =>
      oldDelegate.color != color;
}

// ---------------------------------------------------------------------------
// TOOLS
// ---------------------------------------------------------------------------

/// Game Engine, Bahasa Pemrograman, Tool Desain. [columns]: 2 di tablet.
class ToolsSection extends StatelessWidget {
  const ToolsSection({super.key, this.columns = 1});

  final int columns;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AboutSubtitle('Game Engine', first: true),
        _ToolGrid(AboutContent.engines, columns),
        const AboutSubtitle('Bahasa Pemrograman'),
        _ToolGrid(AboutContent.languages, columns),
        const AboutSubtitle('Tool Desain'),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [for (final t in AboutContent.designTools) TagChip(t)],
        ),
      ],
    );
  }
}

class _ToolGrid extends StatelessWidget {
  const _ToolGrid(this.tools, this.columns);

  final List<Tool> tools;
  final int columns;

  @override
  Widget build(BuildContext context) {
    const gap = 8.0;
    final rows = <Widget>[];
    for (var start = 0; start < tools.length; start += columns) {
      final row = tools.skip(start).take(columns).toList();
      if (rows.isNotEmpty) rows.add(const SizedBox(height: gap));
      rows.add(
        columns == 1
            ? _ToolTile(row.first)
            : IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < columns; i++) ...[
                      if (i > 0) const SizedBox(width: gap),
                      Expanded(
                        child: i < row.length
                            ? _ToolTile(row[i])
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ],
                ),
              ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rows,
    );
  }
}

class _ToolTile extends StatelessWidget {
  const _ToolTile(this.tool);

  final Tool tool;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final t = tool;
    final wide = t.note != null;
    final name = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final logo in t.logos) ...[
          Image.asset(
            logo,
            width: 18,
            height: 18,
            color: c.fg,
            filterQuality: FilterQuality.medium,
            excludeFromSemantics: true,
          ),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(
            t.name,
            softWrap: false,
            style: AppText.pixel(
              16,
              weight: FontWeight.w600,
              height: 1.1,
              color: c.fg,
            ),
          ),
        ),
      ],
    );
    final detail = Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Text(
        wide ? t.note! : t.projects.join(' · '),
        style: wide
            ? AppText.pixel(14, height: 1.45, color: c.fg2)
            : AppText.pixel(
                14.5,
                weight: FontWeight.w500,
                height: 1.5,
                color: c.fg2,
              ),
      ),
    );
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Kolom nama 112 (C++ · Python: selebar isinya).
          if (wide)
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 30),
              child: Align(alignment: Alignment.centerLeft, child: name),
            )
          else
            SizedBox(
              width: 112,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 30),
                child: Align(alignment: Alignment.centerLeft, child: name),
              ),
            ),
          SizedBox(width: wide ? 14 : 10),
          Expanded(child: detail),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// JOURNEY
// ---------------------------------------------------------------------------

/// Timeline terbaru di atas: penanda kotak pixel (terisi = terbaru) dan
/// garis putus-putus.
class JourneySection extends StatelessWidget {
  const JourneySection({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final items = AboutContent.journey;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < items.length; i++)
          CustomPaint(
            painter: _TimelinePainter(
              color: c.fg,
              background: c.bg,
              filled: i == 0,
              last: i == items.length - 1,
            ),
            child: Padding(
              padding: EdgeInsets.only(
                left: 26,
                bottom: i == items.length - 1 ? 0 : 18,
              ),
              child: _JourneyEntry(items[i]),
            ),
          ),
      ],
    );
  }
}

class _JourneyEntry extends StatelessWidget {
  const _JourneyEntry(this.item);

  final JourneyItem item;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.year,
          style: AppText.label(
            10.5,
            color: c.fg2,
            spacing: 0.06,
          ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
        ),
        const SizedBox(height: 3),
        Text(
          item.title,
          style: AppText.pixel(
            18,
            weight: FontWeight.w600,
            height: 1.15,
            color: c.fg,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          item.subtitle,
          style: AppText.body(13, height: 1.45, color: c.fg2),
        ),
        if (item.award != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Container(
              constraints: const BoxConstraints(minHeight: 26),
              padding: const EdgeInsets.fromLTRB(7, 4, 10, 4),
              decoration: BoxDecoration(
                color: c.btn,
                borderRadius: BorderRadius.circular(7),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PixelIcon(PixelIcons.trophy, size: 15, color: c.onBtn),
                  const SizedBox(width: 7),
                  Flexible(
                    child: Text(
                      item.award!,
                      style: AppText.label(10, color: c.onBtn, spacing: 0.04),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _TimelinePainter extends CustomPainter {
  _TimelinePainter({
    required this.color,
    required this.background,
    required this.filled,
    required this.last,
  });

  final Color color;
  final Color background;
  final bool filled;
  final bool last;

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()..isAntiAlias = false;
    // Kotak 10×10 di (4, 6) berbingkai 2 px; terbaru terisi penuh.
    const box = Rect.fromLTWH(4, 6, 10, 10);
    canvas.drawRect(box, fill..color = color);
    if (!filled) canvas.drawRect(box.deflate(2), fill..color = background);
    // Garis putus-putus 2 px (4 garis, 2 jeda) ke penanda berikutnya.
    if (!last) {
      fill.color = color;
      for (var y = 18.0; y < size.height - 2; y += 6) {
        final h = (y + 4 > size.height - 2) ? size.height - 2 - y : 4.0;
        canvas.drawRect(Rect.fromLTWH(8, y, 2, h), fill);
      }
    }
  }

  @override
  bool shouldRepaint(_TimelinePainter old) =>
      old.color != color ||
      old.background != background ||
      old.filled != filled ||
      old.last != last;
}

// ---------------------------------------------------------------------------
// EDUCATION
// ---------------------------------------------------------------------------

/// Pendidikan tanpa tahun, dikelompokkan Universitas, Sekolah, Non-formal.
class EducationSection extends StatelessWidget {
  const EducationSection({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final groups = AboutContent.education;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var g = 0; g < groups.length; g++) ...[
          AboutSubtitle(groups[g].label, first: g == 0),
          for (var i = 0; i < groups[g].items.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: c.shadow1,
                        offset: const Offset(0, 1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: PixelIcon(
                    groups[g].items[i].icon,
                    size: 22,
                    color: c.fg,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        groups[g].items[i].level,
                        style: AppText.pixel(
                          16,
                          weight: FontWeight.w600,
                          height: 1.2,
                          color: c.fg,
                        ),
                      ),
                      Text(
                        groups[g].items[i].school,
                        style: AppText.body(12.5, height: 1.4, color: c.fg2),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ],
    );
  }
}
