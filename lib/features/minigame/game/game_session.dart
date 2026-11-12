import 'package:flutter/foundation.dart';

import 'game_config.dart';

/// Tahap satu permainan.
enum PlayPhase {
  /// Hitung mundur "3, 2, 1".
  countdown,

  /// 2 menit permainan.
  running,

  /// Tulisan "Waktu habis!" ±1 detik.
  timeUp,

  /// Selesai; controller memindahkan ke layar kontak.
  ended,
}

/// Data satu sesi permainan (skor, sisa waktu, status jeda).
///
/// Disimpan di luar widget (dipegang [MiniGameController]) sehingga tetap
/// utuh saat tata letak berganti, mis. layar depan ↔ layar utama Flip.
/// Waktu hanya maju lewat [advance]; saat dijeda, tab tidak aktif, atau
/// layar depan Flip, [advance] tidak dipanggil sehingga semuanya berhenti.
class GameSession extends ChangeNotifier {
  PlayPhase _phase = PlayPhase.countdown;
  double _countdownLeft = GameConfig.countdownFrom.toDouble();
  double _remaining = GameConfig.roundSeconds;
  double _timeUpLeft = GameConfig.timeUpSeconds;
  int _score = 0;
  bool _paused = false;

  PlayPhase get phase => _phase;
  int get score => _score;

  /// Sisa waktu permainan (detik).
  double get remaining => _remaining;

  /// Angka hitung mundur yang tampil: 3, 2, lalu 1.
  int get countdownNumber =>
      _countdownLeft.ceil().clamp(1, GameConfig.countdownFrom);

  /// Dijeda lewat tombol kembali Android (dialog Lanjutkan / Akhiri).
  bool get paused => _paused;

  void setPaused(bool value) {
    if (_paused == value || _phase == PlayPhase.ended) return;
    _paused = value;
    notifyListeners();
  }

  /// Jeda otomatis (pindah tab, pindah aplikasi, tombol home) selama hitung
  /// mundur atau permainan; tidak saat "Waktu habis!".
  void pauseIfRunning() {
    if (_phase == PlayPhase.countdown || _phase == PlayPhase.running) {
      setPaused(true);
    }
  }

  /// Memajukan waktu sebanyak [dt] detik.
  void advance(double dt) {
    if (_paused || dt <= 0 || _phase == PlayPhase.ended) return;
    switch (_phase) {
      case PlayPhase.countdown:
        _countdownLeft -= dt;
        if (_countdownLeft <= 0) _phase = PlayPhase.running;
      case PlayPhase.running:
        _remaining -= dt;
        if (_remaining <= 0) {
          _remaining = 0;
          _phase = PlayPhase.timeUp;
        }
      case PlayPhase.timeUp:
        _timeUpLeft -= dt;
        if (_timeUpLeft <= 0) _phase = PlayPhase.ended;
      case PlayPhase.ended:
        return;
    }
    notifyListeners();
  }

  void addScore(int points) {
    _score += points;
    notifyListeners();
  }

  /// Mengakhiri waktu sekarang ("Waktu habis!" lalu layar kontak) dengan
  /// skor [score]. Dipakai tombol "Selesai (uji coba)" di layar bermain
  /// sementara.
  void endRoundNow(int score) {
    if (_phase != PlayPhase.running) return;
    _score = score;
    _remaining = 0;
    _phase = PlayPhase.timeUp;
    notifyListeners();
  }
}
