import 'package:flutter/material.dart';

import '../assets/app_assets.dart';
import '../theme/app_colors.dart';
import 'glass.dart';
import 'pixel_image.dart';

/// Satu tujuan navigasi. Label hanya untuk pembaca layar (tombol ikon saja).
class NavDestination {
  const NavDestination(this.icon, this.label);

  final PixelIcons icon;
  final String label;
}

/// Urutan tab: Beranda, Proyek, Tentang, Mini Game.
const List<NavDestination> appDestinations = [
  NavDestination(PixelIcons.navHome, 'Beranda'),
  NavDestination(PixelIcons.navProjects, 'Proyek'),
  NavDestination(PixelIcons.navAbout, 'Tentang'),
  NavDestination(PixelIcons.navMiniGame, 'Mini Game'),
];

/// Tombol navigasi ikon-saja. Aktif = pil berisi warna `btn`.
class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.destination,
    required this.selected,
    required this.onTap,
    required this.width,
    required this.height,
  });

  final NavDestination destination;
  final bool selected;
  final VoidCallback onTap;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Semantics(
      button: true,
      selected: selected,
      label: destination.label,
      excludeSemantics: true,
      child: Tooltip(
        message: destination.label,
        excludeFromSemantics: true,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              width: width,
              height: height,
              decoration: BoxDecoration(
                color: selected ? c.btn : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: PixelIcon(
                destination.icon,
                color: selected ? c.onBtn : c.muted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Navigation bar bawah (HP portrait & layar depan Flip), berlatar kaca.
/// Menghilang saat scroll ke bawah diatur oleh shell (lihat `AppShell`).
class AppBottomBar extends StatelessWidget {
  const AppBottomBar({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
    this.compact = false,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  /// Versi padat untuk layar depan Flip (tinggi 56).
  final bool compact;

  /// Tinggi bar tanpa inset sistem.
  static double barHeight({bool compact = false}) => compact ? 56 : 62;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Glass(
      border: Border(top: BorderSide(color: c.glassLine)),
      padding: EdgeInsets.fromLTRB(
        compact ? 16 : 20,
        compact ? 6 : 8,
        compact ? 16 : 20,
        (compact ? 8 : 10) + bottomInset,
      ),
      child: Semantics(
        container: true,
        label: 'Navigasi utama',
        explicitChildNodes: true,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (var i = 0; i < appDestinations.length; i++)
              _NavButton(
                destination: appDestinations[i],
                selected: i == selectedIndex,
                onTap: () => onSelected(i),
                width: compact ? 60 : 64,
                height: compact ? 42 : 44,
              ),
          ],
        ),
      ),
    );
  }
}

/// Navigation rail berlatar kaca, lebar 76, tombol 52×44, jarak 36.
/// HP landscape: di kanan, tombol di tengah. Tablet: di kiri, mulai dari atas.
class AppNavRail extends StatelessWidget {
  const AppNavRail({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
    required this.side,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  /// Sisi layar tempat rail berada.
  final AxisDirection side;

  static const double width = 76;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final pad = MediaQuery.paddingOf(context);
    final onLeft = side == AxisDirection.left;
    final borderSide = BorderSide(color: c.glassLine);
    return Glass(
      border: onLeft ? Border(right: borderSide) : Border(left: borderSide),
      child: Padding(
        // Rail ikut menutupi area aman di sisinya.
        padding: EdgeInsets.only(
          left: onLeft ? pad.left : 0,
          right: onLeft ? 0 : pad.right,
          top: onLeft ? pad.top + 24 : 0,
        ),
        child: SizedBox(
          width: width,
          child: Semantics(
            container: true,
            label: 'Navigasi utama',
            explicitChildNodes: true,
            child: Column(
              mainAxisAlignment: onLeft
                  ? MainAxisAlignment.start
                  : MainAxisAlignment.center,
              children: [
                for (var i = 0; i < appDestinations.length; i++) ...[
                  if (i > 0) const SizedBox(height: 36),
                  _NavButton(
                    destination: appDestinations[i],
                    selected: i == selectedIndex,
                    onTap: () => onSelected(i),
                    width: 52,
                    height: 44,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
