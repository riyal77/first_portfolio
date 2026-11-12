/// Semua angka penyetelan (tuning) Debug Rush dikumpulkan di sini.
///
/// Sumber: GDD Mini Game (final 12 November 2026) dan
/// `bahan/mockup/minigame-gameplay-mockup.html` untuk angka yang tidak
/// tertulis di GDD. Waktu dalam detik, ukuran dalam dp.
abstract final class GameConfig {
  // --- Durasi ---------------------------------------------------------------

  /// Durasi satu permainan.
  static const double roundSeconds = 90;

  /// Hitung mundur "3, 2, 1" sebelum bug pertama muncul.
  static const int countdownFrom = 3;

  /// Lama tiap angka hitung mundur.
  static const double countdownStepSeconds = 0.75;

  /// Lama tulisan "Waktu habis!" sebelum pindah ke layar kontak.
  static const double timeUpSeconds = 1;

  /// Selang antarbingkai di atas ini dianggap jeda (pindah tab, aplikasi di
  /// latar belakang) dan tidak dihitung.
  static const double maxFrameGap = 0.25;

  // --- Bug: jumlah, ukuran, posisi -------------------------------------------

  /// Jumlah maksimal bug di layar.
  static const int maxBugsPhonePortrait = 6;
  static const int maxBugsPhoneLandscape = 7;
  static const int maxBugsTablet = 10;

  /// Ukuran dasar bug (sisi kotak saat muncul).
  static const double bugSizePhonePortrait = 60;
  static const double bugSizePhoneLandscape = 52;
  static const double bugSizeTablet = 68;

  /// Bug membesar linear 100% → 140% sepanjang hitung mundurnya.
  static const double growTo = 1.4;

  /// Pop saat muncul.
  static const double popSeconds = 0.16;

  /// Berkedip di 30% waktu terakhir, periode 0,22 → 0,07 detik; saat
  /// "padam" opacity 0,28.
  static const double blinkFrom = 0.7;
  static const double blinkPeriodStart = 0.22;
  static const double blinkPeriodEnd = 0.07;
  static const double blinkDimAlpha = 0.28;

  /// Bug 4: waktu sebelum meledak 1,25× bug lain.
  static const double bug4LifeFactor = 1.25;

  /// Jarak pusat antarbug saat muncul > 1,55 × ukuran dasar.
  static const double minCenterDistance = 1.55;

  /// Percobaan mencari posisi kosong sebelum menyerah (memakai posisi
  /// terakhir).
  static const int spawnTries = 24;

  /// Area main: 16 dp di bawah skor, 14 dp dari tepi kiri/kanan, 12 dp di
  /// atas navigation bar (HP portrait) atau 14 dp dari tepi bawah.
  static const double areaBelowScore = 16;
  static const double areaSideInset = 14;
  static const double areaAboveNav = 12;
  static const double areaBottomInset = 14;

  /// Area sentuh: setengah sisi = maks(26, ukuran/2 + 6) (±48 dp minimal).
  static const double minTouchHalf = 26;
  static const double touchPadding = 6;

  /// Bug yang tersisa saat waktu habis memudar.
  static const double endFadeSeconds = 0.25;

  // --- Bug 4 (tahan) -------------------------------------------------------

  static const double holdSeconds = 2;

  /// Bar progres: lebar = ukuran dasar, tinggi 6, sudut 3, 10 dp di bawah.
  static const double holdBarHeight = 6;
  static const double holdBarGap = 10;

  /// Getar ±1,4 dp selama ditahan.
  static const double holdJitter = 1.4;

  /// Runtuh ke tengah sebelum pecah.
  static const double collapseSeconds = 0.15;

  // --- Kesulitan (streak) --------------------------------------------------

  static const int maxLevel = 10;

  /// +1 level setiap 2 bug hancur berturut-turut.
  static const int bugsPerLevel = 2;

  /// Ledakan ke-1 s.d. ke-3 beruntun: level −2.
  static const int explosionPenalty = 2;

  /// Ledakan ke-4 beruntun: level kembali ke 0.
  static const int explosionsToReset = 4;

  /// Waktu sebelum meledak, level 0 → level 10.
  static const double lifeAtLevel0 = 3.6;
  static const double lifeAtMaxLevel = 1.85;

  /// Jeda kemunculan, level 0 → level 10, dikali acak 0,75–1,25.
  static const double gapAtLevel0 = 1.0;
  static const double gapAtMaxLevel = 0.48;
  static const double gapJitterMin = 0.75;
  static const double gapJitterMax = 1.25;

  /// Mulai level 6, 25% kemunculan berupa 2 bug sekaligus.
  static const int burstFromLevel = 6;
  static const double burstChance = 0.25;

  /// Bug pertama muncul sesaat setelah hitung mundur.
  static const double firstSpawnDelay = 0.2;

  // --- Ledakan -------------------------------------------------------------

  /// Freeze setelah bug meledak; semua sentuhan diabaikan.
  static const double freezeSeconds = 0.6;

  /// Guncangan ±6 dp yang meluruh selama 0,3 detik.
  static const double shakeAmplitude = 6;
  static const double shakeSeconds = 0.3;

  /// Splash dither: sel 6 dp, menutup layar dalam 35% pertama durasi.
  static const double splashCell = 6;
  static const double splashSpread = 0.35;

  // --- Efek tap dan hancur ---------------------------------------------------

  /// Squash 1 → 0,86 → 1,05 → 1.
  static const double squashSeconds = 0.26;

  /// Arsir Bug 2 memudar; 6 serpihan rontok.
  static const double hatchFadeSeconds = 0.18;
  static const int hatchFlakes = 6;

  /// Sisi bingkai Bug 3 jatuh sambil memudar.
  static const double sideFallSeconds = 0.55;

  /// Pecah 3×3 kotak kecil.
  static const double shatterSeconds = 0.36;

  /// "+N" naik 24 dp dan memudar.
  static const double popupSeconds = 0.5;
  static const double popupRise = 24;

  /// Angka skor melompat kecil (skala 1,18 → 1).
  static const double scoreBumpScale = 1.18;
  static const double scoreBumpSeconds = 0.16;
}

/// Empat jenis bug. Makin sulit dihancurkan, makin besar skornya.
enum BugKind {
  bug1(name: 'Bug 1', hits: 1, score: 2, weight: 51),
  bug2(name: 'Bug 2', hits: 2, score: 5, weight: 28, maxOnScreen: 5),
  bug3(name: 'Bug 3', hits: 4, score: 10, weight: 15, maxOnScreen: 3),

  /// Tap dan tahan [GameConfig.holdSeconds] detik.
  bug4(name: 'Bug 4', hits: 0, score: 20, weight: 6, maxOnScreen: 1);

  const BugKind({
    required this.name,
    required this.hits,
    required this.score,
    required this.weight,
    this.maxOnScreen,
  });

  final String name;

  /// Jumlah tap untuk menghancurkan; 0 = tap dan tahan.
  final int hits;

  final int score;

  /// Peluang muncul (weight, persen).
  final double weight;

  /// Batas jumlah di layar; null = hanya dibatasi jumlah maksimal total.
  final int? maxOnScreen;

  bool get isHold => hits == 0;

  /// Cara menghancurkan, mis. "2 tap" atau "Tahan 2 detik".
  String get howTo =>
      isHold ? 'Tahan ${GameConfig.holdSeconds.round()} detik' : '$hits tap';
}
