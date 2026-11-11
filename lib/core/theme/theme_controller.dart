import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Menyimpan pilihan tema.
///
/// Saat pertama dibuka, aplikasi mengikuti tema perangkat ([ThemeMode.system]).
/// Setelah tombol tema ditekan, pilihan (terang/gelap) disimpan dan dipakai
/// lagi pada pembukaan berikutnya.
class ThemeController extends ChangeNotifier {
  ThemeController._(this._mode, this._prefs);

  static const _key = 'theme_mode';

  final SharedPreferencesAsync? _prefs;
  ThemeMode _mode;

  ThemeMode get mode => _mode;

  /// Membaca pilihan tersimpan. Gagal membaca = ikuti tema perangkat.
  static Future<ThemeController> load() async {
    final prefs = SharedPreferencesAsync();
    ThemeMode mode = ThemeMode.system;
    try {
      mode = switch (await prefs.getString(_key)) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
    } catch (_) {
      // Penyimpanan tidak tersedia: tetap jalan dengan tema perangkat.
    }
    return ThemeController._(mode, prefs);
  }

  /// Untuk pengujian: tanpa penyimpanan.
  @visibleForTesting
  ThemeController.inMemory([this._mode = ThemeMode.system]) : _prefs = null;

  /// Membalik tema yang sedang tampil ([current]) lalu menyimpannya.
  Future<void> toggle(Brightness current) async {
    _mode = current == Brightness.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
    try {
      await _prefs?.setString(_key, _mode == ThemeMode.dark ? 'dark' : 'light');
    } catch (_) {
      // Abaikan: pilihan tetap berlaku selama aplikasi terbuka.
    }
  }
}

/// Menyediakan [ThemeController] ke seluruh pohon widget.
class ThemeScope extends InheritedNotifier<ThemeController> {
  const ThemeScope({
    super.key,
    required ThemeController controller,
    required super.child,
  }) : super(notifier: controller);

  static ThemeController of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ThemeScope>()!.notifier!;
}
