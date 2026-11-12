import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'game/game_session.dart';

/// Layar yang tampil di halaman Mini Game.
enum MiniGameStage { intro, playing, contact }

/// Hasil permainan yang baru selesai (untuk kartu hasil di layar kontak).
class GameResult {
  GameResult({required this.score, required this.isRecord});

  final int score;

  /// Skor ini memecahkan skor tertinggi sebelumnya.
  final bool isRecord;

  /// Animasi hitung naik sudah diputar (tidak diulang saat layar dibangun
  /// ulang, mis. pindah tab atau tata letak berganti).
  bool countedUp = false;
}

/// Tahap halaman Mini Game, status tersimpan, dan sesi permainan.
///
/// Status disimpan offline (shared_preferences): "pernah melihat kontak"
/// (selesai bermain atau menekan Lewati), "pernah bermain", dan skor
/// tertinggi. Sesi permainan dipegang di sini, di luar widget, supaya tetap
/// utuh saat tata letak berganti.
class MiniGameController extends ChangeNotifier {
  MiniGameController._({
    required this._seenContact,
    required this._hasPlayed,
    required this._bestScore,
    required this._prefs,
    math.Random? random,
  }) : _random = random ?? math.Random();

  static const _kSeenContact = 'minigame_seen_contact';
  static const _kHasPlayed = 'minigame_has_played';
  static const _kBestScore = 'minigame_best_score';

  /// Membaca status tersimpan. Gagal membaca = kunjungan pertama.
  static Future<MiniGameController> load() async {
    final prefs = SharedPreferencesAsync();
    var seen = false, played = false, best = 0;
    try {
      final values = await prefs.getAll(
        allowList: {_kSeenContact, _kHasPlayed, _kBestScore},
      );
      seen = values[_kSeenContact] == true;
      played = values[_kHasPlayed] == true;
      best = (values[_kBestScore] as int?) ?? 0;
    } catch (_) {
      // Penyimpanan tidak tersedia: mulai dari layar ajakan.
    }
    return MiniGameController._(
      seenContact: seen,
      hasPlayed: played,
      bestScore: best,
      prefs: prefs,
    );
  }

  /// Tanpa penyimpanan (pengujian, atau bila status tidak dimuat).
  MiniGameController.inMemory({
    bool seenContact = false,
    bool hasPlayed = false,
    int bestScore = 0,
    math.Random? random,
  }) : this._(
         seenContact: seenContact,
         hasPlayed: hasPlayed,
         bestScore: bestScore,
         prefs: null,
         random: random,
       );

  final SharedPreferencesAsync? _prefs;
  final math.Random _random;

  /// Setiap kali aplikasi dibuka (termasuk setelah dimatikan di latar
  /// belakang), halaman dimulai dari layar ajakan yang menampilkan judul
  /// game; tombolnya menyesuaikan [hasPlayed].
  MiniGameStage _stage = MiniGameStage.intro;
  bool _seenContact;
  bool _hasPlayed;
  int _bestScore;
  GameResult? _lastResult;
  GameSession? _session;

  MiniGameStage get stage => _stage;

  /// Pernah selesai bermain atau menekan Lewati.
  bool get seenContact => _seenContact;
  bool get hasPlayed => _hasPlayed;
  int get bestScore => _bestScore;

  /// Hasil permainan terakhir selama aplikasi terbuka; null setelah Lewati
  /// atau saat kunjungan berikutnya (layar kontak menampilkan skor
  /// tertinggi).
  GameResult? get lastResult => _lastResult;

  /// Sesi yang sedang berjalan (hanya saat [stage] = playing).
  GameSession? get session => _session;

  /// Mulai permainan baru: langsung ke hitung mundur.
  void start() {
    _session?.removeListener(_onSession);
    _session = GameSession(random: _random)..addListener(_onSession);
    _stage = MiniGameStage.playing;
    notifyListeners();
  }

  /// Ke layar kontak tanpa bermain: "Lewati untuk melihat kontak." (tanpa
  /// skor) atau "Lihat Skor & Kontak" (skor tertinggi).
  void skip() {
    _seenContact = true;
    _lastResult = null;
    _stage = MiniGameStage.contact;
    _save();
    notifyListeners();
  }

  /// "Akhiri permainan" dari dialog jeda: ke layar kontak dengan skor yang
  /// sudah terkumpul.
  void endEarly() {
    final session = _session;
    if (session != null) _finish(session.score);
  }

  void _onSession() {
    final session = _session;
    if (session != null && session.phase == PlayPhase.ended) {
      _finish(session.score);
    }
  }

  void _finish(int score) {
    _session?.removeListener(_onSession);
    _session = null;
    final isRecord = score > _bestScore;
    if (isRecord) _bestScore = score;
    _hasPlayed = true;
    _seenContact = true;
    _lastResult = GameResult(score: score, isRecord: isRecord);
    _stage = MiniGameStage.contact;
    _save();
    notifyListeners();
  }

  void _save() {
    final prefs = _prefs;
    if (prefs == null) return;
    unawaited(() async {
      try {
        await prefs.setBool(_kSeenContact, _seenContact);
        await prefs.setBool(_kHasPlayed, _hasPlayed);
        await prefs.setInt(_kBestScore, _bestScore);
      } catch (_) {
        // Abaikan: status tetap berlaku selama aplikasi terbuka.
      }
    }());
  }
}

/// Menyediakan [MiniGameController] ke halaman Mini Game.
class MiniGameScope extends InheritedWidget {
  const MiniGameScope({
    super.key,
    required this.controller,
    required super.child,
  });

  final MiniGameController controller;

  static MiniGameController of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<MiniGameScope>()!.controller;

  @override
  bool updateShouldNotify(MiniGameScope oldWidget) =>
      controller != oldWidget.controller;
}
