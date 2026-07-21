/// Single source of truth for the exam → syllabus/state rule used across the
/// whole app (profile, hub, practice, onboarding).
///
/// A student picks the exam they are preparing for. NEET & JEE are **national**
/// (NCERT syllabus, available in every state). The rest are **state entrance
/// exams** — picking one scopes the student's practice to that state's bank
/// PLUS the national NEET/JEE/NCERT content (the backend widens every board
/// scope with the pan-India boards, so nothing national is lost). The state is
/// derived from the exam, never chosen separately, so scoping stays consistent
/// and combinations like "JEE + Kerala only" can't happen.
class ExamScope {
  const ExamScope._();

  /// The exams a student/teacher can target. NEET & JEE first (national), then
  /// the state entrance exams. Add a new state's exam here when its bank ships.
  static const exams = ['NEET', 'JEE', 'KCET', 'MHT-CET', 'KEAM'];

  /// NEET & JEE follow NCERT; the state entrance exams follow their State Board
  /// syllabus. This is the label shown to the student and sent as their
  /// curriculum — the backend still layers the national NCERT/PYQ bank on top,
  /// so a State-Board student is not cut off from national content.
  static const _curriculum = {
    'NEET': 'NCERT',
    'JEE': 'NCERT',
    'KCET': 'State Board',
    'MHT-CET': 'State Board',
    'KEAM': 'State Board',
  };

  /// The Indian state an exam belongs to. Null for the national exams
  /// (NEET/JEE), which apply everywhere. Lets the app show/derive the student's
  /// state from the exam they picked.
  static const _state = {
    'KCET': 'Karnataka',
    'MHT-CET': 'Maharashtra',
    'KEAM': 'Kerala',
  };

  /// The subjects an exam actually tests. NEET is medical (no Maths); JEE is
  /// engineering (no Biology). The state CETs are left out on purpose — they run
  /// both engineering and medical streams, so a student may take any of the four
  /// and we don't restrict them.
  static const _subjects = {
    'NEET': ['Physics', 'Chemistry', 'Biology'],
    'JEE': ['Physics', 'Chemistry', 'Mathematics'],
  };

  /// The syllabus/curriculum an exam follows.
  static String curriculumFor(String exam) =>
      _curriculum[exam.trim().toUpperCase()] ?? 'NCERT';

  /// The Indian state an exam scopes to, or null for the national exams.
  static String? stateFor(String exam) => _state[exam.trim().toUpperCase()];

  /// The subjects an exam covers, or null if it is not restricted (state CETs
  /// span both streams). Used to hide Maths from NEET and Biology from JEE.
  static List<String>? subjectsFor(String exam) =>
      _subjects[exam.trim().toUpperCase()];

  /// The exams to offer an educator in [state]: the national exams (NEET/JEE,
  /// which apply everywhere) plus only the entrance exam(s) belonging to that
  /// state. A null/empty state (the founder) gets the full list — they manage
  /// every state. This keeps a Karnataka teacher from being offered MHT-CET or
  /// KEAM, which belong to other states.
  static List<String> examsFor(String? state) {
    final s = state?.trim();
    if (s == null || s.isEmpty) return exams;
    return exams
        .where((e) => stateFor(e) == null || stateFor(e) == s)
        .toList();
  }

  /// Normalise a stored board label to one of [exams], or null if it isn't a
  /// recognised exam. Legacy Karnataka-first profiles stored a generic 'CET' /
  /// 'PUC'; map those to KCET so existing students keep a valid state exam.
  static String? normalize(String s) {
    final u = s.trim().toUpperCase();
    if (u == 'NEET') return 'NEET';
    if (u == 'JEE') return 'JEE';
    if (u == 'KCET') return 'KCET';
    if (u == 'MHT-CET' || u == 'MHTCET' || u == 'MHT CET') return 'MHT-CET';
    if (u == 'KEAM') return 'KEAM';
    // Legacy generic labels → the original Karnataka deployment's exam.
    if (u.contains('CET')) return 'KCET';
    if (u.contains('PUC')) return 'KCET';
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
