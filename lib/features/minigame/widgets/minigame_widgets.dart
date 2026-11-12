import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/assets/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/pixel_image.dart';
import '../game/game_config.dart';

/// Gambar bug sementara (kotak sederhana berwarna token tema), dipakai di
/// layar ajakan. Sprite pixel menyusul; [BugPainter] cukup ditukar.
///
/// - Bug 1: kotak penuh fg.
/// - Bug 2: kotak bergaris diagonal fg / fg2.
/// - Bug 3: kotak berbingkai fg dengan isi kotak kecil.
/// - Bug 4: kotak abu (fg2).
class BugGlyph extends StatelessWidget {
  const BugGlyph(this.kind, {super.key, required this.size});

  final BugKind kind;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: BugPainter(kind, AppColors.of(context)),
    );
  }
}

class BugPainter extends CustomPainter {
  BugPainter(this.kind, this.colors);

  final BugKind kind;
  final AppColors colors;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final rect = Offset.zero & Size.square(s);
    final radius = Radius.circular(math.max(3, s * 0.13));
    final rrect = RRect.fromRectAndRadius(rect, radius);
    final fill = Paint()..color = colors.fg;
    switch (kind) {
      case BugKind.bug1:
        canvas.drawRRect(rrect, fill);
      case BugKind.bug2:
        canvas.save();
        canvas.clipRRect(rrect);
        canvas.drawRect(rect, fill);
        final stripe = Paint()
          ..color = colors.fg2
          ..strokeWidth = s / 7;
        final step = s / 3.5;
        for (var d = -s; d < s * 2; d += step) {
          canvas.drawLine(Offset(d, 0), Offset(d + s, s), stripe);
        }
        canvas.restore();
      case BugKind.bug3:
        final w = math.max(2.0, s * 0.09);
        canvas.drawRRect(
          rrect.deflate(w / 2),
          Paint()
            ..color = colors.fg
            ..style = PaintingStyle.stroke
            ..strokeWidth = w,
        );
        final inner = rect.deflate(s * 0.24);
        canvas.drawRRect(
          RRect.fromRectAndRadius(inner, Radius.circular(radius.x * 0.4)),
          fill,
        );
      case BugKind.bug4:
        canvas.drawRRect(rrect, Paint()..color = colors.fg2);
    }
  }

  @override
  bool shouldRepaint(BugPainter oldDelegate) =>
      oldDelegate.kind != kind || oldDelegate.colors != colors;
}

/// Bar progres tahan Bug 4 (terisi kiri → kanan).
class HoldBar extends StatelessWidget {
  const HoldBar({super.key, required this.progress, this.width = 64});

  final double progress;
  final double width;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: SizedBox(
        width: width,
        height: 4,
        child: ColoredBox(
          color: c.tag,
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress.clamp(0.0, 1.0),
            child: ColoredBox(color: c.fg),
          ),
        ),
      ),
    );
  }
}

/// Judul bagian (Silkscreen 13), sama dengan judul bagian About Me.
class GameSectionTitle extends StatelessWidget {
  const GameSectionTitle(this.text, {super.key, this.bottom = 14});

  final String text;
  final double bottom;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
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

/// Tombol utama selebar kolom: tinggi 52, sudut 10, Pixelify 600 17 dengan
/// letter-spacing 0,08 em (MULAI, MAIN LAGI, LANJUTKAN).
class GamePrimaryButton extends StatelessWidget {
  const GamePrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback onPressed;
  final PixelIcons? icon;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: c.shadow2,
            offset: const Offset(0, 12),
            blurRadius: 24,
            spreadRadius: -14,
          ),
        ],
      ),
      child: Material(
        color: c.btn,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            height: 52,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  PixelIcon(icon!, size: 20, color: c.onBtn),
                  const SizedBox(width: 10),
                ],
                Text(
                  label,
                  style: AppText.pixel(
                    17,
                    weight: FontWeight.w600,
                    color: c.onBtn,
                    letterSpacing: 17 * 0.08,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Tombol sekunder selebar kolom: tinggi 44, bingkai 1 px garis, tanpa
/// latar, Plus Jakarta Sans 600 15 (atau Pixelify 600 16 bila [pixelFont]).
class GameSecondaryButton extends StatelessWidget {
  const GameSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.pixelFont = false,
  });

  final String label;
  final VoidCallback onPressed;

  /// Font pixel (tombol sekunder layar ajakan).
  final bool pixelFont;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
      side: BorderSide(color: c.line),
    );
    return Material(
      type: MaterialType.transparency,
      shape: shape,
      child: InkWell(
        onTap: onPressed,
        customBorder: shape,
        child: SizedBox(
          height: 44,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: pixelFont
                    ? AppText.pixel(16, weight: FontWeight.w600, color: c.fg)
                    : AppText.body(15, weight: FontWeight.w600, color: c.fg),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
