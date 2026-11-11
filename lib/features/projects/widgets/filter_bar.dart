import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/glass.dart';
import '../project_filter.dart';

/// Baris chip filter satu baris yang digeser, menempel di bawah App Banner.
/// [stuck]: konten sudah tergulir di bawahnya, latar menjadi kaca.
class FilterBar extends StatelessWidget {
  const FilterBar({
    super.key,
    required this.selected,
    required this.onSelected,
    required this.stuck,
    this.compact = false,
    this.landscape = false,
  });

  final ProjectFilter selected;
  final ValueChanged<ProjectFilter> onSelected;
  final bool stuck;

  /// Layar depan Flip: chip 34 px.
  final bool compact;

  /// HP landscape: padding vertikal 10.
  final bool landscape;

  /// Tinggi baris filter (chip + padding).
  static double heightFor({bool compact = false, bool landscape = false}) {
    final chip = compact ? 34.0 : 36.0;
    if (compact) return chip + 10 + 10;
    return landscape ? chip + 10 + 10 : chip + 14 + 12;
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final vTop = compact || landscape ? 10.0 : 14.0;
    final vBottom = compact || landscape ? 10.0 : 12.0;
    final h = compact ? 16.0 : 20.0;

    final row = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.fromLTRB(h, vTop, h, vBottom),
      child: Row(
        children: [
          for (var g = 0; g < ProjectFilter.groups.length; g++) ...[
            if (g > 0)
              Container(
                width: 1,
                height: 20,
                margin: const EdgeInsets.symmetric(horizontal: 10),
                color: c.line,
              ),
            for (var i = 0; i < ProjectFilter.groups[g].length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              _FilterChip(
                filter: ProjectFilter.groups[g][i],
                selected: ProjectFilter.groups[g][i] == selected,
                onTap: () => onSelected(ProjectFilter.groups[g][i]),
                height: compact ? 34 : 36,
              ),
            ],
          ],
        ],
      ),
    );

    final content = Semantics(
      container: true,
      label: 'Filter proyek',
      explicitChildNodes: true,
      child: row,
    );

    // Latar kaca selalu selebar layar (lapisan tersendiri yang memudar),
    // chip tetap rata kiri walau semuanya muat dalam satu baris.
    return Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedOpacity(
              opacity: stuck ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              child: Glass(
                border: Border(bottom: BorderSide(color: c.glassLine)),
                child: const SizedBox.expand(),
              ),
            ),
          ),
        ),
        SizedBox(width: double.infinity, child: content),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.filter,
    required this.selected,
    required this.onTap,
    required this.height,
  });

  final ProjectFilter filter;
  final bool selected;
  final VoidCallback onTap;
  final double height;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final fg = selected ? c.onBtn : c.fg;
    return Semantics(
      button: true,
      selected: selected,
      label: 'Filter ${filter.label}',
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: c.shadow1,
              offset: const Offset(0, 1),
              blurRadius: 2,
            ),
          ],
        ),
        child: Material(
          color: selected ? c.btn : c.surface,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              height: height,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (filter.logo != null) ...[
                    Image.asset(
                      filter.logo!,
                      width: 15,
                      height: 15,
                      color: fg,
                      filterQuality: FilterQuality.medium,
                      excludeFromSemantics: true,
                    ),
                    const SizedBox(width: 7),
                  ],
                  Text(
                    filter.label,
                    style: AppText.body(13, weight: FontWeight.w600, color: fg),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
