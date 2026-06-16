import 'package:flutter/material.dart';
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
