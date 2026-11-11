import 'package:flutter/material.dart';

import '../assets/app_assets.dart';
import '../theme/app_colors.dart';
import '../theme/theme_controller.dart';
import 'pixel_image.dart';

/// Tombol tema 44×44: ikon bulan di tema terang, matahari di tema gelap.
/// Selalu di kanan atas (di dalam App Banner, atau mengambang di tablet).
class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key, this.size = 44});

  final double size;

  @override
  Widget build(BuildContext context) {
    final controller = ThemeScope.of(context);
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    return Semantics(
      button: true,
      label: isDark ? 'Ganti ke tema terang' : 'Ganti ke tema gelap',
      excludeSemantics: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => controller.toggle(brightness),
          child: SizedBox.square(
            dimension: size,
            child: Center(
              child: PixelIcon(
                isDark ? PixelIcons.themeSun : PixelIcons.themeMoon,
                color: AppColors.of(context).fg,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
