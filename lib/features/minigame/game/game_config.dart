/// Semua angka penyetelan (tuning) Debug Rush dikumpulkan di sini.
///
/// Sumber: GDD Mini Game. Kurva kesulitan dan angka spawner ditambahkan di
/// branch `debugRush` bersama game Flame-nya.
abstract final class GameConfig {
  /// Durasi satu permainan (detik).
  static const double roundSeconds = 120;

  /// Hitung mundur sebelum bug pertama muncul: "3, 2, 1".
  static const int countdownFrom = 3;

  /// Lama tulisan "Waktu habis!" sebelum pindah ke layar kontak (detik).
  static const double timeUpSeconds = 1;

  /// Freeze setelah bug meledak; semua sentuhan diabaikan (detik).
  static const double freezeSeconds = 0.6;

  /// Lama tap dan tahan untuk menghancurkan Bug 4 (detik).
  static const double holdSeconds = 2;

  /// Ukuran sentuh minimal bug (dp).
  static const double minTouchSize = 48;

  /// Jumlah maksimal bug di layar.
  static const int maxBugsPhonePortrait = 6;
  static const int maxBugsPhoneLandscape = 7;
  static const int maxBugsTablet = 10;

  /// Selang antarbingkai di atas ini dianggap jeda (pindah tab, aplikasi di
  /// latar belakang) dan tidak dihitung, sehingga permainan berlanjut persis
  /// dari posisi terakhir (detik).
  static const double maxFrameGap = 0.25;
}

/// Empat jenis bug. Makin sulit dihancurkan, makin besar skornya.
enum BugKind {
  bug1(name: 'Bug 1', taps: 1, score: 2, weight: 51),
  bug2(name: 'Bug 2', taps: 2, score: 5, weight: 28),
  bug3(name: 'Bug 3', taps: 4, score: 10, weight: 15),

  /// Tap dan tahan [GameConfig.holdSeconds] detik.
  bug4(name: 'Bug 4', taps: 0, score: 20, weight: 6);

  const BugKind({
    required this.name,
    required this.taps,
    required this.score,
    required this.weight,
  });

  final String name;

  /// Jumlah tap untuk menghancurkan; 0 = tap dan tahan.
  final int taps;

  final int score;

  /// Peluang muncul (persen).
  final int weight;

  bool get isHold => taps == 0;

  /// Cara menghancurkan, mis. "2 tap" atau "Tahan 2 detik".
  String get howTo =>
      isHold ? 'Tahan ${GameConfig.holdSeconds.round()} detik' : '$taps tap';
}
