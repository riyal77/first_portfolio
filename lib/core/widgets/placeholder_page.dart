import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import 'app_banner.dart';

/// Halaman sementara selama halaman aslinya belum dibangun di branch-nya.
/// Isinya cukup panjang untuk menguji App Banner, navigation bar yang
/// bersembunyi saat scroll, dan state scroll saat tata letak berganti.
class PlaceholderPage extends StatelessWidget {
  const PlaceholderPage({
    super.key,
    required this.title,
    required this.message,
    this.subtitle,
    this.storageKey,
  });

  final String title;
  final String? subtitle;
  final String message;

  /// Kunci [PageStorage] agar posisi scroll tersimpan.
  final String? storageKey;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final pad = MediaQuery.paddingOf(context);
    return Stack(
      children: [
        ListView.separated(
          key: storageKey == null ? null : PageStorageKey<String>(storageKey!),
          padding: EdgeInsets.fromLTRB(
            20,
            AppBanner.totalHeight(context) + 16,
            20,
            pad.bottom + 24,
          ),
          itemCount: 13,
          separatorBuilder: (_, _) => const SizedBox(height: 16),
          itemBuilder: (context, i) {
            if (i == 0) {
              return Text(message, style: AppText.paragraph(color: c.fg));
            }
            return Container(
              height: 120,
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: c.cardShadow,
              ),
              alignment: Alignment.center,
              child: Text('BAGIAN $i', style: AppText.label(11, color: c.fg2)),
            );
          },
        ),
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          child: AppBanner(leading: BannerTitle(title, subtitle: subtitle)),
        ),
      ],
    );
  }
}
