import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/assets/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/pixel_image.dart';
import '../../../core/widgets/project_widgets.dart';
import '../../../data/project.dart';

/// Membuka galeri layar penuh di atas seluruh aplikasi (termasuk navigasi).
/// Mengembalikan indeks gambar terakhir yang dilihat.
Future<int?> showGalleryLightbox(
  BuildContext context, {
  required Project project,
  required int initialIndex,
}) {
  return Navigator.of(context, rootNavigator: true).push<int>(
    PageRouteBuilder<int>(
      opaque: true,
      barrierColor: Colors.black,
      transitionDuration: const Duration(milliseconds: 200),
      reverseTransitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (_, _, _) =>
          GalleryLightbox(project: project, initialIndex: initialIndex),
      transitionsBuilder: (_, animation, _, child) =>
          FadeTransition(opacity: animation, child: child),
    ),
  );
}

/// Galeri layar penuh berlatar hitam: geser untuk gambar berikutnya,
/// penanda "1 / n" dan tombol tutup di atas.
class GalleryLightbox extends StatefulWidget {
  const GalleryLightbox({
    super.key,
    required this.project,
    required this.initialIndex,
  });

  final Project project;
  final int initialIndex;

  @override
  State<GalleryLightbox> createState() => _GalleryLightboxState();
}

class _GalleryLightboxState extends State<GalleryLightbox> {
  late final PageController _controller = PageController(
    initialPage: widget.initialIndex,
  );
  late int _index = widget.initialIndex;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _close() => Navigator.of(context).pop(_index);

  @override
  Widget build(BuildContext context) {
    final p = widget.project;
    final pad = MediaQuery.paddingOf(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.black,
      ),
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _close();
        },
        child: Material(
          color: Colors.black,
          child: Stack(
            children: [
              Positioned.fill(
                child: Semantics(
                  label: 'Galeri layar penuh',
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: p.imageCount,
                    onPageChanged: (i) => setState(() => _index = i),
                    itemBuilder: (context, i) => Semantics(
                      image: true,
                      label: '${p.title}, gambar ${i + 1}',
                      child: Center(
                        child: ProjectImage(p, i, fit: BoxFit.contain),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    20 + pad.left,
                    pad.top + 8,
                    12 + pad.right,
                    0,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${_index + 1} / ${p.imageCount}',
                          style:
                              AppText.label(
                                11,
                                color: AppColors.paper,
                                spacing: 0.06,
                              ).copyWith(
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                        ),
                      ),
                      Semantics(
                        button: true,
                        label: 'Tutup galeri',
                        excludeSemantics: true,
                        child: Material(
                          color: const Color(0x1FF6F4EE),
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            onTap: _close,
                            borderRadius: BorderRadius.circular(12),
                            child: const SizedBox.square(
                              dimension: 44,
                              child: Center(
                                child: PixelIcon(
                                  PixelIcons.close,
                                  color: AppColors.paper,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: pad.bottom + 16,
                child: IgnorePointer(
                  child: Text(
                    'Geser untuk gambar berikutnya',
                    textAlign: TextAlign.center,
                    style: AppText.body(12, color: const Color(0xFFBEB8AD))
                        .copyWith(
                          shadows: const [
                            Shadow(color: Color(0xE6000000), blurRadius: 3),
                          ],
                        ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
