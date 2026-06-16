import 'package:flutter/material.dart';
import '../app/theme.dart';
import '../models/models.dart';
import 'repo.dart';

/// In-memory store shared across the exam-creation wizard. A tiny ChangeNotifier
/// keeps the multi-step flow stateful without pulling in a heavier dependency.
class ExamDraft extends ChangeNotifier {
  String title = '';
  String board = 'JEE';
  String description = '';
  int duration = 90;
  String format = 'Mock Exam';
  final Set<String> targetClasses = {};
  final Map<String, String> classIdsByName = {}; // name -> backend id
  int reach = 0;
  String parsingEngine = 'Advanced';
  String fileName = '';
  bool strictStart = true;
  bool flexibleWindow = false;
  bool gracePeriod = true;
  bool randomize = false;
  int questions = 0;
  int marks = 0;

  // Backend wiring
  String? importJobId; // PDF parse job, set after upload
  List<String> importedQuestionIds = [];
  String? examId; // created on publish

  void reset() {
    title = '';
    description = '';
    duration = 90;
    targetClasses.clear();
    fileName = '';
    importJobId = null;
    importedQuestionIds = [];
    examId = null;
    questions = 0;
    marks = 0;
    notifyListeners();
  }

  void touch() => notifyListeners();
}

final examDraft = ExamDraft();

/// Shared store for the question list. The bank, AI-review, and edit screens
/// all read/write this; [loadFromApi] hydrates it from the backend.
class QuestionStore extends ChangeNotifier {
  final List<QuestionItem> questions = [];
  bool loading = false;
  String? error;

  Future<void> loadFromApi({List<String>? onlyIds}) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final rows = await Repo.questions();
      questions.clear();
      var pos = 1;
      for (final row in rows) {
        final q = QuestionItem.fromApi(row as Map<String, dynamic>, pos);
        if (onlyIds == null || onlyIds.contains(q.id)) {
          questions.add(q);
          pos++;
        }
      }
    } catch (e) {
      error = e.toString();
    }
    loading = false;
    notifyListeners();
  }

  void touch() => notifyListeners();
}

final questionStore = QuestionStore();

class Mock {
  static final exams = <Exam>[
    Exam(
        title: 'Calculus Mock Test 4',
        board: 'MATH-C4',
        status: ExamStatus.published,
        subtitle: 'Ends in 2 days',
        submissions: 40),
    Exam(
        title: 'Probability Distributions',
        board: 'STAT-M2',
        status: ExamStatus.gradingNeeded,
        subtitle: '33 Total Submissions',
        submissions: 33),
    Exam(
        title: 'Topology Basics',
        board: 'MATH',
        status: ExamStatus.draft,
        subtitle: 'Last edited 4h ago'),
  ];

  static const students = <Student>[
    Student('Elena Sideris', 'JEE-2024-8902',
        tag: '∫ sin x²·dx Master', score: 92, status: 'TOP 5%',
        color: AppColors.teal,
        trend: [0.4, 0.5, 0.45, 0.6, 0.7, 0.85, 0.92]),
    Student('Julian Martinez', 'JEE-2024-5512',
        tag: 'Vector Analysis Section', score: 78, status: 'AVERAGE',
        color: AppColors.secondary,
        trend: [0.6, 0.55, 0.62, 0.58, 0.65, 0.7, 0.78]),
    Student('Amina Wong', 'JEE-2024-1029',
        tag: 'Retake Required: Limits', score: 61, status: 'AT RISK',
        color: AppColors.error,
        trend: [0.7, 0.6, 0.5, 0.55, 0.48, 0.6, 0.61]),
  ];

  static const submissions = <Submission>[
    Submission(Student('Aravind Sharma', 'JEE-2024-8902', color: AppColors.teal),
        '2h ago', 84, true),
    Submission(Student('Ishita Rao', 'JEE-2024-5512', color: AppColors.secondary),
        '45m ago', null, false),
    Submission(Student('Raj Patel', 'JEE-2024-1029', color: AppColors.primary),
        '5h ago', 42, true),
    Submission(Student('Meera Nair', 'JEE-2024-4410', color: AppColors.success),
        '10m ago', null, false),
  ];

  static const topics = <TopicScore>[
    TopicScore('Integration', 0.58, 0.75),
    TopicScore('Derivatives', 0.82, 0.80),
    TopicScore('Infinite Series', 0.42, 0.70),
  ];

  // Class heatmap: rows of (topic, [top20, mid60, bottom20], overall)
  static const heatmap = <(String, List<int>, int)>[
    ('Kinematics', [98, 84, 62], 81),
    ('Thermodynamics', [76, 54, 28], 52),
    ('Organic Chemistry', [88, 72, 64], 74),
    ('Calculus I', [94, 91, 85], 90),
    ('Electromagnetism', [68, 42, 21], 44),
  ];

  // Live proctoring candidates
  static const liveCandidates = <(String, String, String, String)>[
    ('Julian D. Vance', '4892-X', 'In Progress', 'Q24 / 50'),
    ('Maya Wong', '3318-A', 'Flagged', 'Q12 / 50'),
    ('Kaleb Laurent', '1182-L', 'Submitted', 'Done'),
    ('Sarah P. Patel', '9980-B', 'In Progress', 'Q41 / 50'),
  ];
}
