import 'package:url_launcher/url_launcher.dart';

/// Membuka tautan di aplikasi luar (browser, aplikasi email).
/// Gagal (tidak ada aplikasi yang bisa membukanya) diabaikan.
Future<void> openExternal(String url) async {
  try {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  } catch (_) {
    // Abaikan.
  }
}
