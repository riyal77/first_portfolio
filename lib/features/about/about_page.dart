import 'package:flutter/material.dart';

import '../../core/widgets/placeholder_page.dart';

/// About Me. Sementara placeholder; dibangun di branch `aboutMe`.
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderPage(
      title: 'About Me',
      message: 'Halaman About Me dibangun di branch aboutMe.',
      storageKey: 'about',
    );
  }
}
