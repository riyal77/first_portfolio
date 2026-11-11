import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_text.dart';

/// Membangun [ThemeData] terang dan gelap dari token [AppColors].
abstract final class AppTheme {
  static ThemeData get light => _build(Brightness.light, AppColors.light);
  static ThemeData get dark => _build(Brightness.dark, AppColors.dark);

  static ThemeData _build(Brightness brightness, AppColors c) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: c.btn,
      onPrimary: c.onBtn,
      secondary: c.fg2,
      onSecondary: c.bg,
      error: const Color(0xFFB3261E),
      onError: AppColors.paper,
      surface: c.bg,
      onSurface: c.fg,
      onSurfaceVariant: c.fg2,
      surfaceContainerHighest: c.surface,
      outline: c.line,
      outlineVariant: c.line,
      shadow: c.shadow2,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: AppFonts.body,
      scaffoldBackgroundColor: c.bg,
      canvasColor: c.bg,
      dividerColor: c.line,
      splashFactory: InkRipple.splashFactory,
      highlightColor: c.fg.withValues(alpha: 0.06),
      splashColor: c.fg.withValues(alpha: 0.10),
      hoverColor: c.fg.withValues(alpha: 0.06),
      focusColor: c.fg.withValues(alpha: 0.10),
      extensions: [c],
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(
        fontFamily: AppFonts.body,
        bodyColor: c.fg,
        displayColor: c.fg,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: c.btn,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: AppText.body(12, color: c.onBtn, weight: FontWeight.w600),
      ),
    );
  }
}
