import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Lightweight local persistence (shared_preferences) so state survives app
/// restarts: exam autosave, published-results flag, notification read state,
/// and settings toggles. Initialized once in main().
class AppStore {
  static late SharedPreferences _prefs;
  static bool _ready = false;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _ready = true;
  }

  // ---- Exam autosave / recovery (#14) ----
  static const _kExamProgress = 'exam_progress';

  static void saveExamProgress({
    required int question,
    required Map<int, int> answers,
    required Set<int> marked,
  }) {
    if (!_ready) return;
    _prefs.setString(
        _kExamProgress,
        jsonEncode({
          'q': question,
          'answers': answers.map((k, v) => MapEntry('$k', v)),
          'marked': marked.toList(),
        }));
  }

  static ({int question, Map<int, int> answers, Set<int> marked})?
      loadExamProgress() {
    if (!_ready) return null;
    final raw = _prefs.getString(_kExamProgress);
    if (raw == null) return null;
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      return (
        question: m['q'] as int,
        answers: (m['answers'] as Map<String, dynamic>)
            .map((k, v) => MapEntry(int.parse(k), v as int)),
        marked: ((m['marked'] as List).cast<int>()).toSet(),
      );
    } catch (_) {
      return null;
    }
  }

  static void clearExamProgress() {
    if (_ready) _prefs.remove(_kExamProgress);
  }

  // ---- Results publishing (#9) ----
  static bool get resultsPublished =>
      _ready && (_prefs.getBool('results_published') ?? false);
  static set resultsPublished(bool v) {
    if (_ready) _prefs.setBool('results_published', v);
  }

  // ---- Notifications read state (#6) ----
  static bool get notificationsRead =>
      _ready && (_prefs.getBool('notifications_read') ?? false);
  static set notificationsRead(bool v) {
    if (_ready) _prefs.setBool('notifications_read', v);
  }

  // ---- Settings toggles (#15) ----
  static bool getFlag(String key, {bool fallback = true}) =>
      _ready ? (_prefs.getBool('flag_$key') ?? fallback) : fallback;
  static void setFlag(String key, bool v) {
    if (_ready) _prefs.setBool('flag_$key', v);
  }
}
