/// Single source of truth for the exam → syllabus rule used across the whole
/// app (profile, hub, practice, onboarding).
///
/// NEET and JEE are based on the **NCERT** syllabus; CET is based on the
/// **State Board** syllabus — so their question sets differ. The student picks
/// ONE exam; the curriculum is derived from it (never chosen independently),
/// which keeps every screen consistent and avoids contradictory combinations
/// like "JEE + State Board".
class ExamScope {
  const ExamScope._();

  /// The exams a student/teacher can target.
  static const exams = ['NEET', 'JEE', 'CET', 'PUC'];

  /// NEET & JEE → NCERT; CET → State Board; PUC has its own (Pre-University)
  /// syllabus and is kept as its own curriculum bucket.
  static const _curriculum = {
    'NEET': 'NCERT',
    'JEE': 'NCERT',
    'CET': 'State Board',
    'PUC': 'PUC',
  };

  /// The syllabus/curriculum an exam follows.
  static String curriculumFor(String exam) =>
      _curriculum[exam.trim().toUpperCase()] ?? 'NCERT';

  /// Normalise a stored board label to one of [exams], or null if it isn't a
  /// recognised exam (older profiles may hold 'PG CET', 'CBSE', etc.).
  static String? normalize(String s) {
    final u = s.trim().toUpperCase();
    if (u == 'NEET') return 'NEET';
    if (u == 'JEE') return 'JEE';
    if (u.contains('CET')) return 'CET';
    if (u.contains('PUC')) return 'PUC';
    return null;
  }

  /// The exam a student is targeting, from their stored boards (first match).
  static String? examOf(List<String> boards) {
    for (final b in boards) {
      final e = normalize(b);
      if (e != null) return e;
    }
    return null;
  }
}
