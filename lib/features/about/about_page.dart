import 'package:flutter/material.dart';

import '../../core/layout/device_layout.dart';
import '../../core/layout/scroll_anchor.dart';
import '../../core/widgets/app_banner.dart';
import 'widgets/about_sections.dart';

/// About Me: perkenalan (bio dipotong + Read More..), SKILLS, TOOLS,
/// JOURNEY, EDUCATION.
///
/// - HP portrait & layar depan Flip: satu kolom.
/// - HP landscape: dua kolom dalam satu scroll (kiri perkenalan, journey,
///   education; kanan skills, tools).
/// - Tablet portrait: perkenalan selebar layar (foto + nama kiri, bio
///   kanan), SKILLS 3 kartu berjajar, TOOLS grid 2 kolom, lalu JOURNEY dan
///   EDUCATION berdampingan.
/// - Tablet landscape: kolom kiri 380 (perkenalan, journey, education),
///   kolom kanan (skills berjajar, tools 2 kolom), satu scroll.
///
/// Scroll dan status bio disimpan di sini, di atas pemilih tata letak.
class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

/// Urutan kunci bagian (untuk pemetaan scroll per bagian).
abstract final class _Section {
  static const intro = 0;
  static const skills = 1;
  static const tools = 2;
  static const journey = 3;
  static const education = 4;
}

class _AboutPageState extends State<AboutPage> {
  final _scroll = ScrollController();
  final _bioExpanded = ValueNotifier<bool>(false);
  final _keys = List.generate(5, (i) => GlobalKey(debugLabel: 'about$i'));
  late final _anchor = ScrollAnchorKeeper(_scroll, () => _keys);
  DeviceLayout? _layout;

  @override
  void dispose() {
    _scroll.dispose();
    _bioExpanded.dispose();
    super.dispose();
  }

  Widget _section(int i, String? title, Widget child, {bool first = false}) {
    return Padding(
      key: _keys[i],
      padding: EdgeInsets.only(top: first ? 0 : 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [?(title == null ? null : AboutSectionTitle(title)), child],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final layout = DeviceLayout.fromSize(size);
    if (_layout != null && _layout != layout) _anchor.layoutChanged();
    _layout = layout;

    final pad = MediaQuery.paddingOf(context);
    final bannerTotal = AppBanner.totalHeight(context);
    final cover = layout == DeviceLayout.flipCover;
    final h = switch (layout) {
      DeviceLayout.tablet => 24.0,
      DeviceLayout.flipCover => 16.0,
      _ => 20.0,
    };
    final endPad = pad.bottom + (layout.usesBottomBar ? 38 : 28);

    final Widget body = switch (layout) {
      DeviceLayout.phonePortrait ||
      DeviceLayout.flipCover => _oneColumn(cover: cover),
      DeviceLayout.phoneLandscape => _twoColumns(left: null, gap: 28),
      DeviceLayout.tablet =>
        size.width > size.height
            ? _twoColumns(left: 380, gap: 32, rowCards: true)
            : _tabletPortrait(),
    };

    return Stack(
      children: [
        Positioned.fill(
          child: NotificationListener<UserScrollNotification>(
            onNotification: (n) {
              if (n.metrics.axis == Axis.vertical) _anchor.userScrolled();
              return false;
            },
            child: SingleChildScrollView(
              key: const PageStorageKey<String>('about'),
              controller: _scroll,
              padding: EdgeInsets.fromLTRB(h, bannerTotal + 20, h, endPad),
              child: body,
            ),
          ),
        ),
        const Positioned(
          left: 0,
          right: 0,
          top: 0,
          child: AppBanner(leading: BannerTitle('About Me')),
        ),
      ],
    );
  }

  Widget _intro({bool cover = false}) => _section(
    _Section.intro,
    null,
    Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        IntroHeader(photo: cover ? 72 : 96, nameSize: cover ? 22 : 24),
        const SizedBox(height: 16),
        // Layar depan Flip: bio lebih pendek (4 baris).
        BioSection(expanded: _bioExpanded, collapsedLines: cover ? 4 : 5),
      ],
    ),
    first: true,
  );

  Widget _skills({bool row = false, bool first = false}) =>
      _section(_Section.skills, 'SKILLS', SkillsCards(row: row), first: first);

  Widget _tools({int columns = 1}) =>
      _section(_Section.tools, 'TOOLS', ToolsSection(columns: columns));

  Widget _journey({bool first = false}) => _section(
    _Section.journey,
    'JOURNEY',
    const JourneySection(),
    first: first,
  );

  Widget _education({bool first = false}) => _section(
    _Section.education,
    'EDUCATION',
    const EducationSection(),
    first: first,
  );

  Widget _oneColumn({required bool cover}) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _intro(cover: cover),
      _skills(),
      _tools(),
      _journey(),
      _education(),
    ],
  );

  /// Kiri: perkenalan, journey, education. Kanan: skills, tools.
  /// [left] null = dua kolom sama lebar.
  Widget _twoColumns({
    required double? left,
    required double gap,
    bool rowCards = false,
  }) {
    final leftCol = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [_intro(), _journey(), _education()],
    );
    final rightCol = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _skills(row: rowCards, first: true),
        _tools(columns: rowCards ? 2 : 1),
      ],
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (left == null)
          Expanded(child: leftCol)
        else
          SizedBox(width: left, child: leftCol),
        SizedBox(width: gap),
        Expanded(child: rightCol),
      ],
    );
  }

  /// Tablet portrait: perkenalan selebar layar (foto + nama kiri, bio
  /// kanan), skills berjajar, tools 2 kolom, journey & education
  /// berdampingan.
  Widget _tabletPortrait() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _section(
        _Section.intro,
        null,
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(child: IntroHeader()),
            const SizedBox(width: 28),
            Expanded(child: BioSection(expanded: _bioExpanded)),
          ],
        ),
        first: true,
      ),
      _skills(row: true),
      _tools(columns: 2),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _journey()),
          const SizedBox(width: 32),
          Expanded(child: _education()),
        ],
      ),
    ],
  );
}
