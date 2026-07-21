/// Single source of truth for the exam → syllabus/state rule used across the
/// whole app (profile, hub, practice, onboarding).
///
/// A student prepares for two kinds of exam:
///  - **Entrance** exams (NEET/JEE nationally; KCET/MHT-CET/KEAM per state) —
///    the competitive tests that decide college admission.
///  - **Board** exams (CBSE nationally; 2nd PUC/Plus Two/HSC per state) — the
///    qualifying Class-12 examination.
///
/// Both are just board tags on the question bank, so picking either scopes
/// practice the same way: to that exam's content plus the pan-India NCERT
/// bank (the backend widens every scope with the national boards, so nothing
/// national is lost). The state is derived from the exam, never chosen
/// separately, so a "JEE + Kerala only" combination can't happen.
class ExamScope {
  const ExamScope._();

  /// Competitive entrance exams. NEET/JEE are national; the rest are per-state.
  static const entranceExams = ['NEET', 'JEE', 'KCET', 'MHT-CET', 'KEAM'];

  /// Class-12 board exams. CBSE is national; the rest are per-state boards
  /// (their tags in the bank: 2nd PUC→PUC, Plus Two→DHSE, HSC→HSC).
  static const boardExams = ['CBSE', 'PUC', 'DHSE', 'HSC'];

  /// Every exam a student/teacher can target — entrance first, then board.
  static const exams = [...entranceExams, ...boardExams];

  /// Entrance exams follow NCERT (national) or their State Board syllabus; board
  /// exams follow their own board's syllabus. Sent as the student's curriculum;
  /// the backend still layers the national NCERT/PYQ bank on top.
  static const _curriculum = {
    'NEET': 'NCERT',
    'JEE': 'NCERT',
    'KCET': 'State Board',
    'MHT-CET': 'State Board',
    'KEAM': 'State Board',
    'CBSE': 'CBSE',
    'PUC': 'State Board',
    'DHSE': 'State Board',
    'HSC': 'State Board',
  };

  /// The Indian state an exam belongs to. Null for the national exams
  /// (NEET/JEE/CBSE), which apply everywhere.
  static const _state = {
    'KCET': 'Karnataka',
    'MHT-CET': 'Maharashtra',
    'KEAM': 'Kerala',
    'PUC': 'Karnataka',
    'DHSE': 'Kerala',
    'HSC': 'Maharashtra',
  };

  /// Friendly display names. Entrance exams show their code; board exams show
  /// the name students know (the bank tag stays as the map key).
  static const _label = {
    'PUC': '2nd PUC',
    'DHSE': 'Plus Two',
    'HSC': 'HSC',
    'CBSE': 'CBSE',
  };

  /// The subjects an exam actually tests. NEET is medical (no Maths); JEE is
  /// engineering (no Biology). Everything else (state CETs, all board exams) is
  /// left out on purpose — they span both streams, so a student may take any of
  /// the four and we don't restrict them.
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
  /// and board exams span both streams).
  static List<String>? subjectsFor(String exam) =>
      _subjects[exam.trim().toUpperCase()];

  /// The board exam a student in [state] sits (their Class-12 qualifying exam),
  /// so the hub can offer board prep alongside their entrance exam. A national
  /// student (no state, e.g. pure JEE/NEET) defaults to CBSE.
  static const _stateBoardExam = {
    'Karnataka': 'PUC',
    'Kerala': 'DHSE',
    'Maharashtra': 'HSC',
  };
  static String boardExamFor(String? state) =>
      _stateBoardExam[state?.trim()] ?? 'CBSE';

  /// The name to show a student for this exam.
  static String label(String exam) =>
      _label[exam.trim().toUpperCase()] ?? exam.trim().toUpperCase();

  /// Whether this exam is a Class-12 board exam (vs a competitive entrance one).
  /// Lets a picker group "Board" separately from "Entrance".
  static bool isBoard(String exam) =>
      boardExams.contains(exam.trim().toUpperCase());

  /// The exams to offer someone in [state]: the national exams (which apply
  /// everywhere) plus only the exam(s) belonging to that state. A null/empty
  /// state (the founder) gets the full list. Keeps a Karnataka user from being
  /// offered MHT-CET/KEAM or Kerala's Plus Two board.
  static List<String> examsFor(String? state) {
    final s = state?.trim();
    if (s == null || s.isEmpty) return exams;
    return exams
        .where((e) => stateFor(e) == null || stateFor(e) == s)
        .toList();
  }

  /// Normalise a stored board label to one of [exams], or null if unrecognised.
  static String? normalize(String s) {
    final u = s.trim().toUpperCase();
    if (exams.contains(u)) return u; // exact match (entrance or board)
    if (u == 'MHTCET' || u == 'MHT CET') return 'MHT-CET';
    // Legacy generic 'CET' from the original Karnataka deployment → its entrance
    // exam. ('PUC' is now the board exam and matches exactly above.)
    if (u.contains('CET')) return 'KCET';
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
