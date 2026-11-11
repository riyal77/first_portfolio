import 'package:flutter/material.dart';

import '../../core/widgets/placeholder_page.dart';

/// Mini Game. Belum dirancang; dibangun di branch `miniGame`.
class MiniGamePage extends StatelessWidget {
  const MiniGamePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderPage(
      title: 'Mini Game',
      message: 'Mini Game sedang disiapkan.',
      storageKey: 'minigame',
    );
  }
}
