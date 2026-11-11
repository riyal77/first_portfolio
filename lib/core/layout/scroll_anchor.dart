import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Posisi baca: bagian ke-[section], [fraction] dari tingginya.
typedef ScrollAnchor = ({int section, double fraction});

/// Menjaga posisi baca per bagian (bukan per piksel) saat tata letak
/// berganti, mis. rotasi atau layar depan ↔ layar utama Flip, ketika tinggi
/// tiap bagian berbeda antar tata letak.
///
/// Pemakaian di `build` halaman:
/// 1. Saat tata letak berubah, panggil [layoutChanged] (render tata letak
///    lama masih ada di fase build).
/// 2. Panggil [userScrolled] saat pengguna menggeser (mis. dari
///    `UserScrollNotification`).
///
/// Bagian yang tidak berada di scroll milik [controller] dilewati.
class ScrollAnchorKeeper {
  ScrollAnchorKeeper(this.controller, this.sectionKeys);

  final ScrollController controller;

  /// Kunci tiap bagian, berurutan dari atas.
  final List<GlobalKey> Function() sectionKeys;

  /// Posisi terakhir yang dikembalikan; dipakai lagi pada pergantian
  /// berikutnya selama pengguna belum menggeser, supaya bolak-balik tidak
  /// bergeser walau di tata letak antara posisinya sempat terpotong ujung
  /// konten.
  ScrollAnchor? _restored;

  void userScrolled() => _restored = null;

  void layoutChanged() {
    final anchor = _restored ?? capture();
    if (anchor == null) return;
    _restored = anchor;
    WidgetsBinding.instance.addPostFrameCallback((_) => restore(anchor));
  }

  /// Offset scroll yang membuat bagian tepat di puncak layar + tingginya.
  (double, double)? _geometry(GlobalKey key) {
    final context = key.currentContext;
    final box = context?.findRenderObject() as RenderBox?;
    if (context == null || box == null || !box.attached || !box.hasSize) {
      return null;
    }
    if (!controller.hasClients ||
        Scrollable.maybeOf(context)?.position != controller.position) {
      return null;
    }
    final viewport = RenderAbstractViewport.maybeOf(box);
    if (viewport == null) return null;
    return (viewport.getOffsetToReveal(box, 0).offset, box.size.height);
  }

  ScrollAnchor? capture() {
    if (!controller.hasClients || controller.positions.length != 1) {
      return null;
    }
    final pixels = controller.offset;
    final keys = sectionKeys();
    ScrollAnchor? anchor;
    var bestTop = double.negativeInfinity;
    // Bagian dengan puncak tertinggi yang sudah terlewati (urutan kunci
    // tidak harus sama dengan urutan di layar, mis. tata letak dua kolom).
    for (var i = 0; i < keys.length; i++) {
      final g = _geometry(keys[i]);
      if (g == null) continue;
      final (top, height) = g;
      if (top > pixels + 0.5 || top <= bestTop) continue;
      bestTop = top;
      // Boleh > 1: posisi di celah antara bagian ini dan berikutnya.
      final f = height <= 0 ? 0.0 : ((pixels - top) / height).clamp(0.0, 2.0);
      anchor = (section: i, fraction: f);
    }
    return anchor;
  }

  void restore(ScrollAnchor anchor) {
    if (!controller.hasClients || controller.positions.length != 1) return;
    final keys = sectionKeys();
    if (anchor.section >= keys.length) return;
    final g = _geometry(keys[anchor.section]);
    if (g == null) return;
    final (top, height) = g;
    final pos = controller.position;
    final target = (top + anchor.fraction * height).clamp(
      pos.minScrollExtent,
      pos.maxScrollExtent,
    );
    if ((target - pos.pixels).abs() > 0.5) controller.jumpTo(target);
  }
}
