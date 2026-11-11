import 'package:flutter/material.dart';

import '../../core/widgets/placeholder_page.dart';

/// Beranda. Sementara placeholder; dibangun di branch `homePage`.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderPage(
      title: 'Beranda',
      message: 'Halaman Beranda dibangun di branch homePage.',
      storageKey: 'home',
    );
  }
}
