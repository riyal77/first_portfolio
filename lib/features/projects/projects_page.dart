import 'package:flutter/material.dart';

import '../../app/app_shell.dart';
import '../../core/layout/device_layout.dart';
import '../../core/layout/scroll_anchor.dart';
import '../../core/theme/app_colors.dart';
import '../../data/project.dart';
import '../../data/project_repository.dart';
import 'project_filter.dart';
import 'widgets/gallery_lightbox.dart';
import 'widgets/project_detail_view.dart';
import 'widgets/project_list_view.dart';

/// Game Projects: daftar + filter, detail proyek, galeri layar penuh.
///
/// Semua state (filter, scroll daftar & detail, proyek terbuka, posisi
/// galeri) disimpan di sini, di atas pemilih tata letak, sehingga rotasi atau
/// perpindahan layar depan ↔ layar utama Flip tidak membuat ulang apa pun.
/// Kembali dari detail mempertahankan scroll dan filter daftar.
class ProjectsPage extends StatefulWidget {
  const ProjectsPage({super.key});

  @override
  State<ProjectsPage> createState() => _ProjectsPageState();
}

class _ProjectsPageState extends State<ProjectsPage>
    with SingleTickerProviderStateMixin {
  ProjectFilter _filter = ProjectFilter.all;

  final _listScroll = ScrollController();
  final _detailScroll = ScrollController();
  final _filterVisible = ValueNotifier<bool>(true);
  final _filterStuck = ValueNotifier<bool>(false);
  double _scrollAcc = 0;

  final _cardKeys = <String, GlobalKey>{};
  final _detailKeys = List.generate(
    DetailSection.count,
    (i) => GlobalKey(debugLabel: 'detail$i'),
  );
  late final _listAnchor = ScrollAnchorKeeper(
    _listScroll,
    () => [for (final p in _visible) _cardKeys[p.id]!],
  );
  late final _detailAnchor = ScrollAnchorKeeper(
    _detailScroll,
    () => _detailKeys,
  );

  /// Proyek yang sedang terbuka (null = daftar). [_shown] tetap terisi
  /// selama animasi tutup agar detail tidak hilang mendadak.
  String? _openId;
  String? _shown;

  late final AnimationController _transition = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  );
  late final Animation<double> _curve = CurvedAnimation(
    parent: _transition,
    curve: const Cubic(0.2, 0.8, 0.2, 1),
  );

  PageController _gallery = PageController();
  final _galleryIndex = ValueNotifier<int>(0);

  DeviceLayout? _layout;
  ShellScope? _shell;

  List<Project> _all = const [];
  List<Project> get _visible => _all.where(_filter.matches).toList();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _all = ProjectsScope.of(context).projects;
    for (final p in _all) {
      _cardKeys.putIfAbsent(p.id, () => GlobalKey(debugLabel: 'card${p.id}'));
    }
    final shell = ShellScope.of(context);
    if (!identical(shell.projectRequest, _shell?.projectRequest)) {
      _shell?.projectRequest.removeListener(_onProjectRequest);
      shell.projectRequest.addListener(_onProjectRequest);
    }
    _shell = shell;
    // Permintaan yang datang sebelum halaman ini siap.
    if (shell.projectRequest.value != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _onProjectRequest());
    }
  }

  @override
  void dispose() {
    _shell?.projectRequest.removeListener(_onProjectRequest);
    _listScroll.dispose();
    _detailScroll.dispose();
    _filterVisible.dispose();
    _filterStuck.dispose();
    _transition.dispose();
    _gallery.dispose();
    _galleryIndex.dispose();
    super.dispose();
  }

  void _onProjectRequest() {
    final shell = _shell;
    final id = shell?.projectRequest.value;
    if (!mounted || shell == null || id == null) return;
    shell.projectRequest.value = null;
    _open(id, instant: true);
  }

  void _setFilter(ProjectFilter filter) {
    if (filter == _filter) return;
    setState(() => _filter = filter);
    _filterVisible.value = true;
    if (_listScroll.hasClients) _listScroll.jumpTo(0);
  }

  void _open(String id, {bool instant = false}) {
    final old = _gallery;
    setState(() {
      _openId = id;
      _shown = id;
      _gallery = PageController();
      _galleryIndex.value = 0;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
    if (_detailScroll.hasClients) _detailScroll.jumpTo(0);
    if (instant) {
      _transition.value = 1;
    } else {
      _transition.forward();
    }
    _shell?.setBackHandler(AppTab.projects, _close);
  }

  void _close() {
    if (_openId == null) return;
    setState(() => _openId = null);
    _shell?.setBackHandler(AppTab.projects, null);
    _transition.reverse().whenCompleteOrCancel(() {
      if (mounted && _openId == null) setState(() => _shown = null);
    });
  }

  Future<void> _fullscreen(Project project, int index) async {
    final last = await showGalleryLightbox(
      context,
      project: project,
      initialIndex: index,
    );
    // Galeri kembali ke gambar terakhir yang dilihat di layar penuh.
    if (last != null && mounted && _gallery.hasClients) {
      _gallery.jumpToPage(last);
    }
  }

  /// Filter bersembunyi saat scroll ke bawah dan muncul saat scroll ke atas
  /// (semua perangkat, termasuk tablet — keputusan Ryal, menggantikan catatan
  /// wireframe tablet); berlatar kaca begitu konten tergulir di bawahnya.
  bool _onListScroll(ScrollNotification n) {
    if (n.metrics.axis != Axis.vertical) return false;
    if (n is UserScrollNotification) _listAnchor.userScrolled();
    if (n is ScrollUpdateNotification) {
      final s = n.metrics.pixels;
      final d = n.scrollDelta ?? 0;
      _filterStuck.value = s > 2;
      _scrollAcc = (d.sign == _scrollAcc.sign) ? _scrollAcc + d : d;
      if (s < 8 || _scrollAcc < -6) {
        _filterVisible.value = true;
      } else if (_scrollAcc > 10 && s > 60) {
        _filterVisible.value = false;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final layout = DeviceLayout.fromSize(size);
    final previous = _layout;
    if (previous != null && previous != layout) {
      // Render tata letak lama masih ada: catat posisi baca per bagian.
      _listAnchor.layoutChanged();
      _detailAnchor.layoutChanged();
    }
    _layout = layout;
    final tabletLandscape =
        layout == DeviceLayout.tablet && size.width > size.height;
    final visible = _visible;

    final list = NotificationListener<ScrollNotification>(
      onNotification: _onListScroll,
      child: ProjectListView(
        layout: layout,
        landscape: tabletLandscape,
        projects: visible,
        total: _all.length,
        filter: _filter,
        onFilter: _setFilter,
        controller: _listScroll,
        filterVisible: _filterVisible,
        filterStuck: _filterStuck,
        cardKeys: _cardKeys,
        onOpen: (p) => _open(p.id),
      ),
    );

    final shownId = _shown;
    final shownProject = shownId == null
        ? null
        : ProjectsScope.of(context).byId(shownId);

    return LayoutBuilder(
      builder: (context, cons) {
        final w = cons.maxWidth;
        return AnimatedBuilder(
          animation: _curve,
          builder: (context, _) {
            final t = _curve.value;
            // Dipotong di batas halaman: daftar yang bergeser ke kiri tidak
            // boleh tergambar di atas rail navigasi (tablet) atau area aman.
            return ClipRect(
              child: Stack(
                children: [
                  // Daftar bergeser sedikit ke kiri saat detail masuk.
                  Positioned.fill(
                    child: IgnorePointer(
                      ignoring: _openId != null,
                      child: Transform.translate(
                        offset: Offset(-0.22 * w * t, 0),
                        child: ExcludeSemantics(excluding: t >= 1, child: list),
                      ),
                    ),
                  ),
                  if (shownProject != null)
                    Positioned.fill(
                      child: Transform.translate(
                        offset: Offset((1 - t) * w, 0),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.of(context).shadow2,
                                offset: const Offset(-12, 0),
                                blurRadius: 30,
                                spreadRadius: -18,
                              ),
                            ],
                          ),
                          child: NotificationListener<UserScrollNotification>(
                            onNotification: (n) {
                              if (n.metrics.axis == Axis.vertical) {
                                _detailAnchor.userScrolled();
                              }
                              return false;
                            },
                            child: ProjectDetailView(
                              project: shownProject,
                              layout: layout,
                              tabletLandscape: tabletLandscape,
                              scrollController: _detailScroll,
                              galleryController: _gallery,
                              galleryIndex: _galleryIndex,
                              sectionKeys: _detailKeys,
                              onBack: _close,
                              onFullscreen: (i) => _fullscreen(shownProject, i),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
