import 'api.dart';

/// Typed wrappers over the backend API. All methods return decoded JSON
/// (maps/lists) — screens map these onto their own view state.
class Repo {
  // ---- Teacher auth ----

  static Future<Map<String, dynamic>> teacherRegister({
    required String email,
    required String password,
    required String fullName,
    required String institutionName,
    String? board,
    String? city,
  }) async {
    final r = await api.post('/v1/auth/register', {
      'email': email,
      'password': password,
      'full_name': fullName,
      'institution_name': institutionName,
      if (board != null) 'board': board,
      if (city != null) 'city': city,
    });
    await api.setSession(r['token'] as String, 'teacher');
    await _captureTeacherIdentity(r);
    return r as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> teacherLogin(
      String email, String password) async {
    final r = await api.post('/v1/auth/login', {
      'email': email,
      'password': password,
    });
    await api.setSession(r['token'] as String, 'teacher');
    await _captureTeacherIdentity(r);
    return r as Map<String, dynamic>;
  }

  static Future<void> _captureTeacherIdentity(dynamic r) async {
    final t = r['teacher'] as Map<String, dynamic>?;
    if (t != null) {
      final role = t['role'] == 'admin' ? 'Super Admin' : 'Educator';
      await api.setIdentity(t['full_name'] as String?, role);
    }
  }

  static Future<Map<String, dynamic>> me() async =>
      (await api.get('/v1/auth/me')) as Map<String, dynamic>;

  // ---- Classes & students ----

  static Future<List<dynamic>> classes() async =>
      (await api.get('/v1/classes')) as List<dynamic>;

  static Future<Map<String, dynamic>> createClass(String name,
      {String? board, String? grade, String? section}) async {
    return (await api.post('/v1/classes', {
      'name': name,
      if (board != null) 'board': board,
      if (grade != null) 'grade': grade,
      if (section != null) 'section': section,
    })) as Map<String, dynamic>;
  }

  static Future<List<dynamic>> roster(String classId) async =>
      (await api.get('/v1/classes/$classId/roster')) as List<dynamic>;

  static Future<void> enroll(String classId, List<String> studentIds) async =>
      api.post('/v1/classes/$classId/roster', {'student_ids': studentIds});

  static Future<List<dynamic>> students() async =>
      (await api.get('/v1/students')) as List<dynamic>;

  static Future<List<dynamic>> bulkStudents(
          List<Map<String, dynamic>> rows) async =>
      (await api.post('/v1/students/bulk', rows)) as List<dynamic>;

  // ---- Question bank ----

  static Future<List<dynamic>> questions(
      {String? subject, String? topic, String? status}) async {
    return (await api.get('/v1/questions', query: {
      if (subject != null) 'subject': subject,
      if (topic != null) 'topic': topic,
      if (status != null) 'status': status,
    })) as List<dynamic>;
  }

  static Future<Map<String, dynamic>> updateQuestion(
          String id, Map<String, dynamic> body) async =>
      (await api.put('/v1/questions/$id', body)) as Map<String, dynamic>;

  static Future<Map<String, dynamic>> createQuestion(
          Map<String, dynamic> body) async =>
      (await api.post('/v1/questions', body)) as Map<String, dynamic>;

  static Future<Map<String, dynamic>> uploadQuestionImage(
          String id, List<int> bytes, String filename) async =>
      (await api.upload('/v1/questions/$id/images',
          bytes: bytes, filename: filename)) as Map<String, dynamic>;

  static Future<Map<String, dynamic>> removeQuestionImage(
          String id, String url) async =>
      (await api.delete('/v1/questions/$id/images', {'url': url}))
          as Map<String, dynamic>;

  // ---- PDF import ----

  static Future<Map<String, dynamic>> uploadPaper(
          List<int> bytes, String filename) async =>
      (await api.upload('/v1/imports', bytes: bytes, filename: filename))
          as Map<String, dynamic>;

  static Future<Map<String, dynamic>> importStatus(String jobId) async =>
      (await api.get('/v1/imports/$jobId')) as Map<String, dynamic>;

  // ---- Exams ----

  static Future<List<dynamic>> exams() async =>
      (await api.get('/v1/exams')) as List<dynamic>;

  static Future<Map<String, dynamic>> createExam({
    required String title,
    required String board,
    String? subtitle,
    String? description,
    String? format,
    int? durationMin,
    DateTime? scheduledFor,
  }) async {
    return (await api.post('/v1/exams', {
      'title': title,
      'board': board,
      if (subtitle != null) 'subtitle': subtitle,
      if (description != null) 'description': description,
      if (format != null) 'format': format,
      if (durationMin != null) 'duration_min': durationMin,
      if (scheduledFor != null)
        'scheduled_for': scheduledFor.toUtc().toIso8601String(),
    })) as Map<String, dynamic>;
  }

  static Future<List<dynamic>> examQuestions(String examId) async =>
      (await api.get('/v1/exams/$examId/questions')) as List<dynamic>;

  /// Topics (chapters) available in the teacher's question bank.
  static Future<List<dynamic>> examTopics() async =>
      (await api.get('/v1/exams/topics')) as List<dynamic>;

  /// Assembles an exam from chosen topics, assigns it to classes, and
  /// optionally publishes — all in one call.
  static Future<Map<String, dynamic>> createTopicExam({
    required String title,
    String? board,
    int? durationMin,
    required List<String> classIds,
    required List<Map<String, dynamic>> items,
    bool publish = false,
  }) async {
    return (await api.post('/v1/exams/from-topics', {
      'title': title,
      if (board != null) 'board': board,
      if (durationMin != null) 'duration_min': durationMin,
      'class_ids': classIds,
      'items': items,
      'publish': publish,
    })) as Map<String, dynamic>;
  }

  static Future<void> setExamQuestions(
      String examId, List<Map<String, dynamic>> items) async {
    await api.put('/v1/exams/$examId/questions', {'items': items});
  }

  static Future<void> setExamTargets(
      String examId, List<String> classIds) async {
    await api.post('/v1/exams/$examId/targets', {'class_ids': classIds});
  }

  static Future<Map<String, dynamic>> publishExam(String examId) async =>
      (await api.post('/v1/exams/$examId/publish')) as Map<String, dynamic>;

  // ---- Submissions & grading ----

  static Future<List<dynamic>> submissionsForExam(String examId) async =>
      (await api.get('/v1/submissions/exam/$examId')) as List<dynamic>;

  static Future<Map<String, dynamic>> submission(String id) async =>
      (await api.get('/v1/submissions/$id')) as Map<String, dynamic>;

  static Future<Map<String, dynamic>> grade(
          String submissionId, List<Map<String, dynamic>> items) async =>
      (await api.post('/v1/submissions/$submissionId/grade', {'items': items}))
          as Map<String, dynamic>;

  // ---- Analytics ----

  static Future<Map<String, dynamic>> dashboard() async =>
      (await api.get('/v1/analytics/dashboard')) as Map<String, dynamic>;

  static Future<Map<String, dynamic>> examAnalytics(String examId) async =>
      (await api.get('/v1/analytics/exam/$examId')) as Map<String, dynamic>;

  static Future<Map<String, dynamic>> classAnalytics() async =>
      (await api.get('/v1/analytics/class')) as Map<String, dynamic>;

  // ---- Student practice ----

  static Future<List<dynamic>> practiceSubjects() async =>
      (await api.get('/v1/student/practice/subjects')) as List<dynamic>;

  /// Topics (chapters) available for practice, each with its question count.
  static Future<List<dynamic>> practiceTopics() async =>
      (await api.get('/v1/student/practice/topics')) as List<dynamic>;

  static Future<Map<String, dynamic>> practiceGenerate(
          List<Map<String, dynamic>> items) async =>
      (await api.post('/v1/student/practice/generate', {'items': items}))
          as Map<String, dynamic>;

  static Future<Map<String, dynamic>> practiceGrade(
          List<Map<String, dynamic>> answers) async =>
      (await api.post('/v1/student/practice/grade', {'answers': answers}))
          as Map<String, dynamic>;

  static Future<List<dynamic>> practiceHistory() async =>
      (await api.get('/v1/student/practice/history')) as List<dynamic>;

  static Future<Map<String, dynamic>> practiceSession(String id) async =>
      (await api.get('/v1/student/practice/history/$id'))
          as Map<String, dynamic>;

  /// AI worked-solution (answer, hint, steps, explanation) for a question.
  static Future<Map<String, dynamic>> explainQuestion(String questionId) async =>
      (await api.post('/v1/student/practice/explain',
          {'question_id': questionId})) as Map<String, dynamic>;

  // ---- Student flow ----

  static Future<Map<String, dynamic>> studentLogin(
      String email, String password) async {
    final r = await api.post('/v1/student/login', {
      'email': email,
      'password': password,
    });
    await api.setSession(r['token'] as String, 'student');
    final s = r['student'] as Map<String, dynamic>?;
    if (s != null) {
      await api.setIdentity(
          s['full_name'] as String?, 'Roll ${s['roll_no'] ?? ''}'.trim());
    }
    return r as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> studentRegister({
    required String fullName,
    required String email,
    required String password,
    String? teacherCode,
  }) async {
    final r = await api.post('/v1/student/register', {
      'full_name': fullName,
      'email': email,
      'password': password,
      if (teacherCode != null && teacherCode.trim().isNotEmpty)
        'teacher_code': teacherCode.trim(),
    });
    await api.setSession(r['token'] as String, 'student');
    final s = r['student'] as Map<String, dynamic>?;
    if (s != null) {
      await api.setIdentity(
          s['full_name'] as String?, 'Roll ${s['roll_no'] ?? ''}'.trim());
    }
    return r as Map<String, dynamic>;
  }

  static Future<List<dynamic>> studentExams() async =>
      (await api.get('/v1/student/exams')) as List<dynamic>;

  static Future<Map<String, dynamic>> startExam(String examId) async =>
      (await api.post('/v1/student/exams/$examId/start'))
          as Map<String, dynamic>;

  static Future<void> saveAnswers(
      String examId, List<Map<String, dynamic>> answers) async {
    await api.put('/v1/student/exams/$examId/answers', {'answers': answers});
  }

  static Future<Map<String, dynamic>> submitExam(String examId) async =>
      (await api.post('/v1/student/exams/$examId/submit'))
          as Map<String, dynamic>;

  static Future<void> reportIncident(String examId, String kind,
      {int severity = 1}) async {
    await api.post('/v1/student/exams/$examId/incidents',
        {'kind': kind, 'severity': severity});
  }
}
