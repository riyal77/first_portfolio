import 'dart:math' as math;
import 'dart:ui';

import '../../../core/theme/app_colors.dart';
import 'game_config.dart';

/// Warna permainan yang diambil dari token tema aktif.
class GamePalette {
  const GamePalette({
    required this.bg,
    required this.fg,
    required this.hatch,
    required this.tag,
    required this.dark,
  });

  factory GamePalette.from(AppColors c, {required bool dark}) => GamePalette(
    bg: c.bg,
    fg: c.fg,
    // Sela arsir Bug 2: fg2 di tema terang, muted di tema gelap.
    hatch: dark ? c.muted : c.fg2,
    tag: c.tag,
    dark: dark,
  );

  final Color bg;

  /// Isi dan bingkai bug, serpihan, splash.
  final Color fg;

  /// Sela arsir Bug 2.
  final Color hatch;

  /// Lintasan bar progres Bug 4.
  final Color tag;

  final bool dark;

  /// Warna teks "+N" (tabel GDD).
  Color popupColor(int points) => switch ((points, dark)) {
    (<= 2, false) => const Color(0xFFBEB8AD),
    (<= 2, true) => const Color(0xFF5E5B55),
    (<= 5, false) => const Color(0xFF777777),
    (<= 5, true) => const Color(0xFF9C978E),
    (<= 10, false) => const Color(0xFF5E5B55),
    (<= 10, true) => const Color(0xFFBEB8AD),
    (_, false) => const Color(0xFF111111),
    (_, true) => const Color(0xFFF6F4EE),
  };

  /// Ukuran teks "+N".
  static double popupSize(int points) => switch (points) {
    <= 2 => 16,
    <= 5 => 18,
    <= 10 => 20,
    _ => 24,
  };

  @override
  bool operator ==(Object other) =>
      other is GamePalette &&
      other.bg == bg &&
      other.fg == fg &&
      other.hatch == hatch &&
      other.tag == tag &&
      other.dark == dark;

  @override
  int get hashCode => Object.hash(bg, fg, hatch, tag, dark);
}

/// Sisi bingkai Bug 3, urutan lepas: atas, kanan, bawah (kiri terakhir).
enum BugSide { top, right, bottom, left }

/// Menggambar bentuk final bug dengan kode (tanpa file sprite), berpusat di
/// [center] dengan sisi [size]. Dipakai bersama oleh komponen Flame dan
/// kartu JENIS BUG di layar ajakan.
///
/// - [hatch]: kekuatan arsir Bug 2 (1 = utuh, 0 = sudah terkelupas).
/// - [sidesLost]: jumlah sisi bingkai Bug 3 yang sudah lepas (0–3).
/// - [alpha]: opacity keseluruhan (berkedip, memudar).
void paintBug(
  Canvas canvas, {
  required Offset center,
  required double size,
  required BugKind kind,
  required GamePalette palette,
  double alpha = 1,
  double hatch = 1,
  int sidesLost = 0,
}) {
  if (size <= 0 || alpha <= 0) return;
  final s = size;
  final rect = Rect.fromCenter(center: center, width: s, height: s);
  final rrect = RRect.fromRectAndRadius(rect, Radius.circular(s * 0.14));
  final fill = Paint()..color = palette.fg.withValues(alpha: alpha);

  switch (kind) {
    case BugKind.bug1:
      canvas.drawRRect(rrect, fill);

    case BugKind.bug2:
      canvas.drawRRect(rrect, fill);
      if (hatch > 0) {
        // Arsir diagonal 45°: jarak 20% ukuran, lebar garis 45% jarak.
        canvas.save();
        canvas.clipRRect(rrect);
        canvas.translate(center.dx, center.dy);
        canvas.rotate(math.pi / 4);
        final stripe = Paint()
          ..color = palette.hatch.withValues(alpha: alpha * hatch);
        final pitch = s * 0.2;
        final width = pitch * 0.45;
        for (var x = -s * 1.5; x < s * 1.5; x += pitch) {
          canvas.drawRect(Rect.fromLTWH(x, -s, width, s * 2), stripe);
        }
        canvas.restore();
      }

    case BugKind.bug3:
      // Bingkai tebal 12% yang sisinya lepas satu per satu, kotak isi 42%.
      final th = s * 0.12;
      canvas.save();
      canvas.clipRRect(rrect);
      final left = rect.left, top = rect.top;
      if (sidesLost < 1) {
        canvas.drawRect(Rect.fromLTWH(left, top, s, th), fill);
      }
      if (sidesLost < 2) {
        canvas.drawRect(Rect.fromLTWH(rect.right - th, top, th, s), fill);
      }
      if (sidesLost < 3) {
        canvas.drawRect(Rect.fromLTWH(left, rect.bottom - th, s, th), fill);
      }
      canvas.drawRect(Rect.fromLTWH(left, top, th, s), fill);
      canvas.restore();
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: center, width: s * 0.42, height: s * 0.42),
          Radius.circular(s * 0.06),
        ),
        fill,
      );

    case BugKind.bug4:
      // Bingkai putus-putus (tebal 6,5%, putus 14% / 9%), kotak isi 28%.
      final inset = s * 0.06;
      final frame = RRect.fromRectAndRadius(
        rect.deflate(inset),
        Radius.circular(s * 0.14 * 0.9),
      );
      final stroke = Paint()
        ..color = palette.fg.withValues(alpha: alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.065;
      final dash = s * 0.14, gap = s * 0.09;
      for (final m in (Path()..addRRect(frame)).computeMetrics()) {
        for (var d = 0.0; d < m.length; d += dash + gap) {
          canvas.drawPath(
            m.extractPath(d, math.min(d + dash, m.length)),
            stroke,
          );
        }
      }
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: center, width: s * 0.28, height: s * 0.28),
          Radius.circular(s * 0.05),
        ),
        fill,
      );
  }
}

/// Bar progres Bug 4 di bawah bug: lebar [width] (ukuran dasar), terisi
/// kiri → kanan sebanyak [progress] (0–1).
void paintHoldBar(
  Canvas canvas, {
  required Offset topCenter,
  required double width,
  required double progress,
  required GamePalette palette,
  double alpha = 1,
}) {
  const height = GameConfig.holdBarHeight;
  final left = topCenter.dx - width / 2;
  const radius = Radius.circular(height / 2);
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTWH(left, topCenter.dy, width, height),
      radius,
    ),
    Paint()..color = palette.tag.withValues(alpha: alpha),
  );
  final filled = math.max(height, width * progress.clamp(0.0, 1.0));
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTWH(left, topCenter.dy, filled, height),
      radius,
    ),
    Paint()..color = palette.fg.withValues(alpha: alpha),
  );
}
