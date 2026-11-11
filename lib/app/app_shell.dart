import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/layout/device_layout.dart';
import '../core/theme/app_colors.dart';
import '../core/widgets/app_navigation.dart';
import '../features/about/about_page.dart';
import '../features/home/home_page.dart';
import '../features/minigame/mini_game_page.dart';
import '../features/projects/projects_page.dart';

/// Indeks tab, sesuai urutan [appDestinations].
abstract final class AppTab {
  static const int home = 0;
  static const int projects = 1;
  static const int about = 2;
  static const int miniGame = 3;
}

/// Kerangka aplikasi: 4 halaman + navigasi yang menyesuaikan ukuran layar.
///
/// Keempat halaman hidup terus di satu [IndexedStack] yang dipasangi
/// [GlobalKey]. Saat tata letak berganti (rotasi, layar depan ↔ layar utama
/// Flip, jendela diubah ukurannya), hanya navigasi di sekelilingnya yang
/// berganti; state halaman (tab, scroll, carousel, filter) tidak dibuat ulang.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with RestorationMixin {
  final _pagesKey = GlobalKey(debugLabel: 'pages');
  final _tab = RestorableInt(AppTab.home);
  final _navVisible = ValueNotifier<bool>(true);

  /// Akumulasi jarak scroll searah (logika sama dengan mockup).
  double _scrollAcc = 0;

  static const _pages = <Widget>[
    HomePage(),
    ProjectsPage(),
    AboutPage(),
    MiniGamePage(),
  ];

  @override
  String get restorationId => 'shell';

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_tab, 'tab');
  }

  @override
  void dispose() {
    _tab.dispose();
    _navVisible.dispose();
    super.dispose();
  }

  void _goToTab(int index) {
    if (index != _tab.value) setState(() => _tab.value = index);
    _navVisible.value = true;
  }

  /// Navigation bar bawah: sembunyi saat scroll ke bawah, muncul saat
  /// scroll ke atas atau saat kembali ke dekat puncak halaman.
  bool _onScroll(ScrollNotification n) {
    if (n.metrics.axis != Axis.vertical) return false;
    if (n is ScrollUpdateNotification) {
      final d = n.scrollDelta ?? 0;
      final s = n.metrics.pixels;
      _scrollAcc = (d.sign == _scrollAcc.sign) ? _scrollAcc + d : d;
      if (s < 8 || _scrollAcc < -6) {
        _navVisible.value = true;
      } else if (_scrollAcc > 10 && s > 40) {
        _navVisible.value = false;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final layout = DeviceLayout.fromSize(mq.size);
    final c = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final pages = KeyedSubtree(
      key: _pagesKey,
      child: NotificationListener<ScrollNotification>(
        onNotification: _onScroll,
        child: IndexedStack(
          index: _tab.value,
          children: [
            for (var i = 0; i < _pages.length; i++)
              TickerMode(
                enabled: i == _tab.value,
                child: ExcludeFocus(
                  excluding: i != _tab.value,
                  child: _pages[i],
                ),
              ),
          ],
        ),
      ),
    );

    final Widget body = switch (layout) {
      DeviceLayout.phonePortrait ||
      DeviceLayout.flipCover =>
        _withBottomBar(mq, layout, pages),
      DeviceLayout.phoneLandscape => _withRail(mq, c, pages, railOnLeft: false),
      DeviceLayout.tablet => _withRail(mq, c, pages, railOnLeft: true),
    };

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: (isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
          .copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarContrastEnforced: false,
      ),
      child: PopScope(
        // Tombol kembali Android: dari tab lain kembali ke Beranda dulu.
        canPop: _tab.value == AppTab.home,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _goToTab(AppTab.home);
        },
        child: ShellScope(
          layout: layout,
          tabIndex: _tab.value,
          navVisible: _navVisible,
          goToTab: _goToTab,
          child: Scaffold(
            backgroundColor: c.bg,
            resizeToAvoidBottomInset: false,
            body: body,
          ),
        ),
      ),
    );
  }

  Widget _withBottomBar(MediaQueryData mq, DeviceLayout layout, Widget pages) {
    final compact = layout == DeviceLayout.flipCover;
    final barHeight = AppBottomBar.barHeight(compact: compact);
    return Stack(
      children: [
        // Halaman berada di bawah bar kaca; padding bawah ditambah tinggi bar
        // agar isi paling bawah tetap bisa di-scroll ke atas bar.
        Positioned.fill(
          child: MediaQuery(
            data: mq.copyWith(
              padding: mq.padding.copyWith(bottom: mq.padding.bottom + barHeight),
            ),
            child: pages,
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: ValueListenableBuilder<bool>(
            valueListenable: _navVisible,
            builder: (context, visible, child) => AnimatedSlide(
              offset: visible ? Offset.zero : const Offset(0, 1.05),
              duration: const Duration(milliseconds: 250),
              curve: Curves.ease,
              child: child,
            ),
            child: AppBottomBar(
              selectedIndex: _tab.value,
              onSelected: _goToTab,
              compact: compact,
            ),
          ),
        ),
      ],
    );
  }

  Widget _withRail(
    MediaQueryData mq,
    AppColors c,
    Widget pages, {
    required bool railOnLeft,
  }) {
    final rail = AppNavRail(
      selectedIndex: _tab.value,
      onSelected: _goToTab,
      side: railOnLeft ? AxisDirection.left : AxisDirection.right,
    );
    final content = Expanded(
      child: MediaQuery(
        // Sisi kiri/kanan sudah ditangani rail & area aman, halaman tidak
        // perlu menambah padding horizontal sendiri.
        data: mq.copyWith(
          padding: mq.padding.copyWith(left: 0, right: 0),
          viewPadding: mq.viewPadding.copyWith(left: 0, right: 0),
        ),
        child: pages,
      ),
    );
    if (railOnLeft) return Row(children: [rail, content]);
    return Row(
      children: [
        // Area aman kiri (kamera/notch) berlatar bg, di luar halaman.
        SizedBox(width: mq.padding.left),
        content,
        rail,
      ],
    );
  }
}

/// Informasi shell untuk halaman: tata letak aktif, tab aktif, status
/// navigation bar (untuk filter yang ikut bersembunyi), dan perpindahan tab
/// (mis. tombol "MAIN SEKARANG" di Beranda).
class ShellScope extends InheritedWidget {
  const ShellScope({
    super.key,
    required this.layout,
    required this.tabIndex,
    required this.navVisible,
    required this.goToTab,
    required super.child,
  });

  final DeviceLayout layout;
  final int tabIndex;
  final ValueListenable<bool> navVisible;
  final ValueChanged<int> goToTab;

  static ShellScope of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ShellScope>()!;

  @override
  bool updateShouldNotify(ShellScope oldWidget) =>
      layout != oldWidget.layout || tabIndex != oldWidget.tabIndex;
}
