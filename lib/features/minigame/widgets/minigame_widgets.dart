import 'package:flutter/material.dart';

import '../../../core/assets/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/pixel_image.dart';
import '../game/bug_shapes.dart';
import '../game/game_config.dart';

/// Gambar bug di layar ajakan, memakai bentuk final yang sama dengan game
/// ([paintBug]): Bug 1 kotak penuh, Bug 2 berarsir, Bug 3 berbingkai tebal,
/// Bug 4 berbingkai putus-putus.
class BugGlyph extends StatelessWidget {
  const BugGlyph(this.kind, {super.key, required this.size});

  final BugKind kind;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: BugPainter(kind, gamePaletteOf(context)),
    );
  }
}

/// Palet permainan dari tema aktif.
GamePalette gamePaletteOf(BuildContext context) => GamePalette.from(
  AppColors.of(context),
  dark: Theme.of(context).brightness == Brightness.dark,
);

class BugPainter extends CustomPainter {
  BugPainter(this.kind, this.palette);

  final BugKind kind;
  final GamePalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    paintBug(
      canvas,
      center: size.center(Offset.zero),
      size: size.shortestSide,
      kind: kind,
      palette: palette,
    );
  }

  @override
  bool shouldRepaint(BugPainter oldDelegate) =>
      oldDelegate.kind != kind || oldDelegate.palette != palette;
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
