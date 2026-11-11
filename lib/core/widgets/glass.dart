import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Kaca buram: latar `glass` tema + blur 20 (App Banner, navigation
/// bar/rail, tombol tema mengambang).
class Glass extends StatelessWidget {
  const Glass({
    super.key,
    required this.child,
    this.border,
    this.borderRadius,
    this.padding,
  });

  final Widget child;

  /// Garis tepi tipis (`glassLine`), mis. hanya sisi bawah untuk banner.
  final BoxBorder? border;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    Widget content = BackdropFilter(
      filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: c.glass,
          border: border,
          borderRadius: borderRadius,
        ),
        child: padding == null ? child : Padding(padding: padding!, child: child),
      ),
    );
    return borderRadius == null
        ? ClipRect(child: content)
        : ClipRRect(borderRadius: borderRadius!, child: content);
  }
}
