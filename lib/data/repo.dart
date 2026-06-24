import 'api.dart';

/// Typed wrappers over the backend API. All methods return decoded JSON
/// (maps/lists) — screens map these onto their own view state.
class Repo {
  /// Unauthenticated: classes a registering student can pick from (the
  /// platform's, or a specific teacher's when a join code is given).
  static Future<List<dynamic>> publicClasses({String? teacherCode}) async =>
      (await api.get('/v1/student/classes', query: {
        if (teacherCode != null && teacherCode.trim().isNotEmpty)
          'teacher_code': teacherCode.trim(),
      })) as List<dynamic>;

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
      // Label shown under the user's name in the shell. The platform founder is
      // 'Founder'; institution admins, validators and teachers are all
      // 'Educator' (they use the same educator app).
      final role = t['role'] == 'super_admin' ? 'Founder' : 'Educator';
      await api.setIdentity(t['full_name'] as String?, role);
    }
  }

  static Future<Map<String, dynamic>> me() async =>
      (await api.get('/v1/auth/me')) as Map<String, dynamic>;

  /// Update the signed-in teacher's display name.
  static Future<Map<String, dynamic>> updateProfile(String fullName) async =>
      (await api.put('/v1/auth/me', {'full_name': fullName}))
          as Map<String, dynamic>;

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

  /// Verbatim source snippet a question was parsed from (for View Original /
  /// Compare). Returns {source_text, prompt}; source_text may be null.
  static Future<Map<String, dynamic>> questionSource(String id) async =>
      (await api.get('/v1/questions/$id/source')) as Map<String, dynamic>;

  /// Ask Gemini for a fresh variant of a question; persists and returns it.
  static Future<Map<String, dynamic>> regenerateQuestion(String id) async =>
      (await api.post('/v1/questions/$id/regenerate')) as Map<String, dynamic>;

  /// Ask Gemini to repair a flagged question in place; persists and returns it.
  static Future<Map<String, dynamic>> aiFixQuestion(String id) async =>
      (await api.post('/v1/questions/$id/ai-fix')) as Map<String, dynamic>;

  static Future<Map<String, dynamic>> uploadQuestionImage(
          String id, List<int> bytes, String filename) async =>
      (await api.upload('/v1/questions/$id/images',
          bytes: bytes, filename: filename)) as Map<String, dynamic>;

  static Future<Map<String, dynamic>> removeQuestionImage(
          String id, String url) async =>
      (await api.delete('/v1/questions/$id/images', {'url': url}))
          as Map<String, dynamic>;

  // ---- Syllabus → AI generation → review (validator / teacher) ----

  /// Stored syllabi with their chapter lists.
  static Future<List<dynamic>> syllabi() async =>
      (await api.get('/v1/syllabi')) as List<dynamic>;

  /// Upload a syllabus PDF for a subject; the server extracts its chapters
  /// (Gemini), so allow plenty of time.
  static Future<Map<String, dynamic>> uploadSyllabus(
          List<int> bytes, String filename, String subject,
          {String? classId,
          List<String> boards = const [],
          String? academicYear}) async =>
      (await api.upload('/v1/syllabi',
          bytes: bytes,
          filename: filename,
          fields: {
            'subject': subject,
            if (classId != null && classId.isNotEmpty) 'class_id': classId,
            if (boards.isNotEmpty) 'boards': boards.join(','),
            if (academicYear != null && academicYear.isNotEmpty)
              'academic_year': academicYear,
          },
          timeout: const Duration(seconds: 180))) as Map<String, dynamic>;

  /// Archive (hide from the generate picker) or restore a syllabus version.
  static Future<void> archiveSyllabus(String id, bool archived) async {
    await api.post('/v1/syllabi/$id/archive', {'archived': archived});
  }

  /// Generate a mix of questions for the chosen chapters into staging.
  static Future<Map<String, dynamic>> generateFromSyllabus(
    String syllabusId, {
    required List<String> chapterIds,
    int mcq = 0,
    int short = 0,
    int long = 0,
  }) async {
    return (await api.post('/v1/syllabi/$syllabusId/generate', {
      'chapter_ids': chapterIds,
      'mcq': mcq,
      'short': short,
      'long': long,
    }, const Duration(seconds: 240))) as Map<String, dynamic>;
  }

  /// Generated questions awaiting review (`pending`) or history (`approved`).
  static Future<List<dynamic>> generatedQuestions({String status = 'pending'}) async =>
      (await api.get('/v1/chapters/generated', query: {'status': status}))
          as List<dynamic>;

  /// Fix a pending generated question before approving (mark the correct
  /// option and/or edit the prompt).
  static Future<Map<String, dynamic>> editGenerated(String id,
      {int? correct, String? prompt}) async {
    return (await api.put('/v1/chapters/generated/$id', {
      if (correct != null) 'correct': correct,
      if (prompt != null) 'prompt': prompt,
    })) as Map<String, dynamic>;
  }

  /// Bank MCQs that still have no correct option flagged (imported/parsed
  /// questions awaiting an answer key) — shown in the validator Review tab.
  static Future<List<dynamic>> bankNeedsKey() async =>
      (await api.get('/v1/questions/needs-key')) as List<dynamic>;

  /// Mark the correct option on a bank MCQ, making it practice-eligible.
  static Future<Map<String, dynamic>> setAnswerKey(String id, int correct) async =>
      (await api.post('/v1/questions/$id/answer-key', {'correct': correct}))
          as Map<String, dynamic>;

  /// Approve a generated question into the live bank (practice/exam eligible).
  static Future<Map<String, dynamic>> approveGenerated(String id) async =>
      (await api.post('/v1/chapters/generated/$id/approve'))
          as Map<String, dynamic>;

  /// Discard a generated question without adding it to the bank.
  static Future<Map<String, dynamic>> rejectGenerated(String id) async =>
      (await api.post('/v1/chapters/generated/$id/reject'))
          as Map<String, dynamic>;

  /// Attach a figure to a generated question (for `needs_figure` ones) before
  /// approval. Returns the updated generated row (with image_urls).
  static Future<Map<String, dynamic>> uploadGeneratedImage(
          String id, List<int> bytes, String filename) async =>
      (await api.upload('/v1/chapters/generated/$id/images',
          bytes: bytes, filename: filename)) as Map<String, dynamic>;

  static Future<Map<String, dynamic>> removeGeneratedImage(
          String id, String url) async =>
      (await api.delete('/v1/chapters/generated/$id/images', {'url': url}))
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
          List<Map<String, dynamic>> items,
          {List<String> curricula = const [],
          List<String> boards = const []}) async =>
      (await api.post('/v1/student/practice/generate', {
        'items': items,
        if (curricula.isNotEmpty) 'curricula': curricula,
        if (boards.isNotEmpty) 'boards': boards,
      })) as Map<String, dynamic>;

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
    _captureStudentIdentity(r);
    return r as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> studentRegister({
    required String fullName,
    required String email,
    required String password,
    String? teacherCode,
    String? classId,
    List<String> targetBoards = const [],
    List<String> curricula = const [],
  }) async {
    final r = await api.post('/v1/student/register', {
      'full_name': fullName,
      'email': email,
      'password': password,
      if (teacherCode != null && teacherCode.trim().isNotEmpty)
        'teacher_code': teacherCode.trim(),
      if (classId != null && classId.isNotEmpty) 'class_id': classId,
      if (targetBoards.isNotEmpty) 'target_boards': targetBoards,
      if (curricula.isNotEmpty) 'curricula': curricula,
    });
    await api.setSession(r['token'] as String, 'student');
    _captureStudentIdentity(r);
    return r as Map<String, dynamic>;
  }

  /// Step 1 of password reset: request a one-time code be emailed. The backend
  /// always returns 200 (it never reveals whether the email is registered).
  static Future<void> studentForgotPassword(String email) async {
    await api.post('/v1/student/forgot-password', {'email': email});
  }

  /// Step 2: submit the emailed code + a new password.
  static Future<void> studentResetPassword(
      String email, String code, String newPassword) async {
    await api.post('/v1/student/reset-password', {
      'email': email,
      'code': code,
      'new_password': newPassword,
    });
  }

  /// The exam boards the student is preparing for (JEE / NEET / CET …).
  static Future<List<String>> studentBoards() async {
    final r = await api.get('/v1/student/boards') as Map<String, dynamic>;
    return ((r['target_boards'] as List?) ?? const []).cast<String>();
  }

  /// Replace the student's target boards; returns the saved (normalised) list.
  static Future<List<String>> setStudentBoards(List<String> boards) async {
    final r = await api.put('/v1/student/boards', {'target_boards': boards})
        as Map<String, dynamic>;
    return ((r['target_boards'] as List?) ?? const []).cast<String>();
  }

  /// The curricula the student follows (NCERT / CBSE / State Board …).
  static Future<List<String>> studentCurricula() async {
    final r = await api.get('/v1/student/curricula') as Map<String, dynamic>;
    return ((r['curricula'] as List?) ?? const []).cast<String>();
  }

  /// Replace the student's curricula; returns the saved (normalised) list.
  static Future<List<String>> setStudentCurricula(List<String> curricula) async {
    final r = await api.put('/v1/student/curricula', {'curricula': curricula})
        as Map<String, dynamic>;
    return ((r['curricula'] as List?) ?? const []).cast<String>();
  }

  /// Subtitle under the student's name shows their class (e.g. "2 PUC-KCET"),
  /// or their roll number if they didn't join a class.
  static Future<void> _captureStudentIdentity(dynamic r) async {
    final s = r['student'] as Map<String, dynamic>?;
    if (s == null) return;
    final cls = (s['class'] as String?)?.trim();
    final subtitle = (cls != null && cls.isNotEmpty)
        ? cls
        : 'Roll ${s['roll_no'] ?? ''}'.trim();
    await api.setIdentity(s['full_name'] as String?, subtitle);
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
