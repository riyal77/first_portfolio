import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../app/app_shell.dart';
import '../../core/layout/device_layout.dart';
import '../../data/project.dart';
import '../../data/project_repository.dart';
import 'widgets/home_morph_view.dart';
import 'widgets/home_tablet_view.dart';

/// Beranda.
///
/// Semua controller disimpan di sini, di atas pemilih tata letak, sehingga
/// rotasi atau perpindahan layar depan ↔ layar utama Flip tidak membuat
/// ulang state. Posisi scroll dipetakan per bagian (hero, skills, featured,
/// ajakan), bukan per piksel, karena tinggi tiap bagian berbeda antar
/// tata letak.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

/// Posisi baca: bagian ke-[section], [fraction] dari tingginya.
typedef _Anchor = ({int section, double fraction});

class _HomePageState extends State<HomePage> {
  final _scroll = ScrollController();
  final _skillsScroll = ScrollController();
  final _carousel = ScrollController();
  final _carouselIndex = ValueNotifier<int>(0);
  final _sectionKeys = List.generate(4, (i) => GlobalKey(debugLabel: 'home$i'));

  DeviceLayout? _layout;

  /// Posisi baca terakhir yang dikembalikan. Dipakai lagi pada pergantian
  /// tata letak berikutnya selama pengguna belum menggeser, supaya
  /// bolak-balik (mis. layar depan ↔ layar utama) tidak menggeser posisi
  /// walau di tata letak antara posisinya sempat terpotong ujung konten.
  _Anchor? _restored;

  @override
  void dispose() {
    _scroll.dispose();
    _skillsScroll.dispose();
    _carousel.dispose();
    _carouselIndex.dispose();
    super.dispose();
  }

  /// Offset scroll yang membuat bagian [i] tepat di puncak layar,
  /// beserta tingginya.
  (double, double)? _sectionGeometry(int i) {
    final box =
        _sectionKeys[i].currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.attached || !box.hasSize) return null;
    final viewport = RenderAbstractViewport.maybeOf(box);
    if (viewport == null) return null;
    return (viewport.getOffsetToReveal(box, 0).offset, box.size.height);
  }

  _Anchor? _captureAnchor() {
    if (!_scroll.hasClients) return null;
    final pixels = _scroll.offset;
    _Anchor? anchor;
    for (var i = 0; i < _sectionKeys.length; i++) {
      final g = _sectionGeometry(i);
      if (g == null) return anchor;
      final (top, height) = g;
      if (top > pixels + 0.5) break;
      // Boleh > 1: posisi di celah antara bagian ini dan berikutnya.
      final f = height <= 0 ? 0.0 : ((pixels - top) / height).clamp(0.0, 2.0);
      anchor = (section: i, fraction: f);
    }
    return anchor;
  }

  void _restoreAnchor(_Anchor anchor) {
    if (!mounted || !_scroll.hasClients) return;
    final g = _sectionGeometry(anchor.section);
    if (g == null) return;
    final (top, height) = g;
    final pos = _scroll.position;
    final target = (top + anchor.fraction * height).clamp(
      pos.minScrollExtent,
      pos.maxScrollExtent,
    );
    if ((target - pos.pixels).abs() > 0.5) _scroll.jumpTo(target);
  }

  /// Kartu unggulan: pindah ke tab Proyek dan buka detailnya.
  void _openProject(Project project) =>
      ShellScope.read(context).openProject(project.id);

  void _play() => ShellScope.read(context).goToTab(AppTab.miniGame);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final layout = DeviceLayout.fromSize(size);
    final previous = _layout;
    if (previous != null && previous != layout) {
      // Render dari tata letak lama masih ada di fase build: catat posisi
      // baca, lalu kembalikan setelah tata letak baru selesai diukur.
      final anchor = _restored ?? _captureAnchor();
      if (anchor != null) {
        _restored = anchor;
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _restoreAnchor(anchor),
        );
      }
    }
    _layout = layout;

    return NotificationListener<UserScrollNotification>(
      onNotification: (n) {
        // Pengguna menggeser halaman: posisi baca baru berlaku.
        if (n.metrics.axis == Axis.vertical) _restored = null;
        return false;
      },
      child: _buildView(layout, size),
    );
  }

  Widget _buildView(DeviceLayout layout, Size size) {
    final featured = ProjectsScope.of(context).featured;

    if (layout == DeviceLayout.tablet) {
      return HomeTabletView(
        landscape: size.width > size.height,
        scrollController: _scroll,
        carouselController: _carousel,
        carouselIndex: _carouselIndex,
        sectionKeys: _sectionKeys,
        featured: featured,
        onOpenProject: _openProject,
        onPlay: _play,
      );
    }

    return HomeMorphView(
      spec: switch (layout) {
        DeviceLayout.phoneLandscape => MorphSpec.landscape,
        DeviceLayout.flipCover => MorphSpec.cover,
        _ => MorphSpec.portrait,
      },
      scrollController: _scroll,
      skillsController: _skillsScroll,
      carouselController: _carousel,
      carouselIndex: _carouselIndex,
      sectionKeys: _sectionKeys,
      featured: featured,
      onOpenProject: _openProject,
      onPlay: _play,
    );
  }
}
