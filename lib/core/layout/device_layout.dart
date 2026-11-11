import 'package:flutter/widgets.dart';

/// Kelas tata letak. Dipilih dari ukuran layar, bukan jenis perangkat,
/// sehingga perpindahan layar depan ↔ layar utama Flip dan rotasi cukup
/// mengganti tata letak tanpa memuat ulang halaman.
enum DeviceLayout {
  /// HP portrait (mockup 402×874): navigation bar bawah.
  phonePortrait,

  /// HP landscape (mockup 874×402): rail kanan, safe area kiri.
  phoneLandscape,

  /// Layar depan Samsung Flip (±402×432): versi padat HP portrait.
  flipCover,

  /// Tablet (sisi terpendek ≥ 600 dp): rail kiri.
  tablet;

  /// Batas tablet Material.
  static const double tabletMinShortestSide = 600;

  /// Layar portrait yang lebih pendek dari ini dianggap layar depan Flip.
  static const double coverMaxHeight = 560;

  static DeviceLayout fromSize(Size size) {
    if (size.shortestSide >= tabletMinShortestSide) return tablet;
    if (size.width > size.height) return phoneLandscape;
    if (size.height < coverMaxHeight) return flipCover;
    return phonePortrait;
  }

  static DeviceLayout of(BuildContext context) =>
      fromSize(MediaQuery.sizeOf(context));

  bool get isTablet => this == tablet;
  bool get isLandscape => this == phoneLandscape;
  bool get isCover => this == flipCover;

  /// Navigation bar bawah (yang menghilang saat scroll) atau rail.
  bool get usesBottomBar => this == phonePortrait || this == flipCover;

  /// Tinggi isi App Banner (tanpa status bar).
  double get bannerHeight => switch (this) {
        phonePortrait || tablet => 64,
        phoneLandscape => 56,
        flipCover => 52,
      };
}
