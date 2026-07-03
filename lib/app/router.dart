import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'flavor.dart';
import '../data/api.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/registration_screen.dart';
import '../screens/auth/institution_setup_screen.dart';
import '../screens/auth/onboarding_finalize_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/wizard/exam_details_screen.dart';
import '../screens/wizard/exam_preview_screen.dart';
import '../screens/wizard/topic_exam_screen.dart';
import '../screens/wizard/target_audience_screen.dart';
import '../screens/wizard/upload_paper_screen.dart';
import '../screens/wizard/ai_review_screen.dart';
import '../screens/wizard/edit_question_screen.dart';
import '../screens/wizard/finalize_settings_screen.dart';
import '../screens/wizard/review_publish_screen.dart';
import '../screens/wizard/publish_success_screen.dart';
import '../screens/grading/submission_list_screen.dart';
import '../screens/grading/manual_grading_screen.dart';
import '../screens/analytics/exam_analytics_screen.dart';
import '../screens/analytics/class_heatmap_screen.dart';
import '../screens/student/registration_screen.dart';
import '../screens/student/interests_screen.dart';
import '../screens/student/join_class_screen.dart';
import '../screens/student/hub_screen.dart';
import '../screens/student/insights_screen.dart';
import '../screens/student/practice_generator_screen.dart';
import '../screens/student/previous_years_screen.dart';
import '../screens/student/practice_review_screen.dart';
import '../screens/student/practice_session_screen.dart';
import '../screens/student/exam_question_screen.dart';
import '../screens/student/practice_results_screen.dart';
import '../screens/student/profile_screen.dart';
import '../screens/student/my_exams_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/bank/question_bank_screen.dart';
import '../screens/wizard/generate_screen.dart';
import '../screens/wizard/puc_paper_screen.dart';
import '../screens/shared/notifications_screen.dart';
import '../screens/shared/settings_screen.dart';
import '../screens/dashboard/roster_screen.dart';

/// Fade transition keeps the academic, low-distraction feel between routes.
CustomTransitionPage<void> _page(Widget child, GoRouterState s) =>
    CustomTransitionPage(
      key: s.pageKey,
      child: child,
      transitionsBuilder: (context, anim, secondary, c) =>
          FadeTransition(opacity: anim, child: c),
    );

/// The active router. Assigned by [createRouter]; used for programmatic
/// navigation outside a widget context (e.g. the global 401 handler).
late GoRouter router;

/// Build the router for a given app flavor. Each of the three Vidyora apps
/// (student / teacher / admin) registers ONLY its own route set, so the student
/// app can't navigate into the authoring/grading screens and vice-versa.
GoRouter createRouter(AppFlavor flavor) {
  router = GoRouter(
    // Restore the persisted session: api.init() has already run in main(), so
    // a signed-in user skips login and lands on this app's home.
    initialLocation: !api.signedIn ? '/login' : flavor.landing,
    routes: [
      ..._authRoutes,
      if (flavor.isStudent) ..._studentRoutes else ..._educatorRoutes,
    ],
  );
  return router;
}

/// Shared by every flavor.
final List<RouteBase> _authRoutes = [
  GoRoute(path: '/login', pageBuilder: (c, s) => _page(const LoginScreen(), s)),
  GoRoute(
      path: '/forgot-password',
      pageBuilder: (c, s) => _page(const ForgotPasswordScreen(), s)),
  GoRoute(
      path: '/settings', pageBuilder: (c, s) => _page(const SettingsScreen(), s)),
];

/// The student app.
final List<RouteBase> _studentRoutes = [
  GoRoute(path: '/student/register', pageBuilder: (c, s) => _page(const StudentRegistrationScreen(), s)),
  GoRoute(path: '/student/interests', pageBuilder: (c, s) => _page(const AcademicInterestsScreen(), s)),
  GoRoute(path: '/student/join-class', pageBuilder: (c, s) => _page(const JoinClassScreen(), s)),
  GoRoute(path: '/student/hub', pageBuilder: (c, s) => _page(const StudentHubScreen(), s)),
  GoRoute(path: '/student/insights', pageBuilder: (c, s) => _page(const InsightsScreen(), s)),
  GoRoute(
      path: '/student/previous-years',
      pageBuilder: (c, s) => _page(const PreviousYearsScreen(), s)),
  GoRoute(
      path: '/student/practice-generator',
      pageBuilder: (c, s) {
        List<String>? csv(String k) {
          final v = s.uri.queryParameters[k];
          if (v == null || v.isEmpty) return null;
          return v.split(',').where((e) => e.isNotEmpty).toList();
        }
        return _page(
            PracticeGeneratorScreen(
                initialSubject: s.uri.queryParameters['subject'],
                initialCurricula: csv('curricula'),
                initialBoards: csv('boards'),
                pyq: s.uri.queryParameters['pyq'] == '1'),
            s);
      }),
  GoRoute(
      path: '/student/exam',
      pageBuilder: (c, s) => _page(
          ExamQuestionScreen(examId: s.uri.queryParameters['exam'] ?? ''), s)),
  GoRoute(
      path: '/student/practice-session',
      pageBuilder: (c, s) =>
          _page(PracticeSessionScreen(questions: s.extra as List<dynamic>), s)),
  GoRoute(
      path: '/student/practice-results',
      pageBuilder: (c, s) => _page(
          PracticeResultsScreen(
              payload: (s.extra as Map<String, dynamic>?) ?? const {}),
          s)),
  GoRoute(
      path: '/student/practice-review',
      pageBuilder: (c, s) => _page(
          PracticeReviewScreen(sessionId: s.uri.queryParameters['session'] ?? ''),
          s)),
  GoRoute(path: '/student/profile', pageBuilder: (c, s) => _page(const StudentProfileScreen(), s)),
  GoRoute(path: '/student/exams', pageBuilder: (c, s) => _page(const MyExamsScreen(), s)),
  GoRoute(path: '/student/settings', pageBuilder: (c, s) => _page(const SettingsScreen(role: 'student'), s)),
  GoRoute(
    path: '/notifications',
    pageBuilder: (c, s) => _page(
        NotificationsScreen(role: s.uri.queryParameters['role'] ?? 'student'), s),
  ),
];

/// The teacher AND admin apps (both use the dashboard/authoring surface).
final List<RouteBase> _educatorRoutes = [
  GoRoute(path: '/register', pageBuilder: (c, s) => _page(const RegistrationScreen(), s)),
  GoRoute(path: '/register/institution', pageBuilder: (c, s) => _page(const InstitutionSetupScreen(), s)),
  GoRoute(path: '/register/finalize', pageBuilder: (c, s) => _page(const OnboardingFinalizeScreen(), s)),
  GoRoute(path: '/dashboard', pageBuilder: (c, s) => _page(const DashboardScreen(), s)),

  // Exam-creation wizard
  GoRoute(path: '/wizard/details', pageBuilder: (c, s) => _page(const ExamDetailsScreen(), s)),
  GoRoute(path: '/wizard/topic-exam', pageBuilder: (c, s) => _page(const TopicExamScreen(), s)),
  GoRoute(
    path: '/exam-preview/:id',
    pageBuilder: (c, s) =>
        _page(ExamPreviewScreen(examId: s.pathParameters['id']!), s),
  ),
  GoRoute(path: '/wizard/audience', pageBuilder: (c, s) => _page(const TargetAudienceScreen(), s)),
  GoRoute(path: '/wizard/upload', pageBuilder: (c, s) => _page(const UploadPaperScreen(), s)),
  GoRoute(path: '/wizard/ai-review', pageBuilder: (c, s) => _page(const AiReviewScreen(), s)),
  GoRoute(
    path: '/wizard/edit-question/:index',
    pageBuilder: (c, s) {
      final raw = s.pathParameters['index'] ?? '0';
      final index = raw == 'new' ? -1 : (int.tryParse(raw) ?? 0);
      return _page(
        EditQuestionScreen(index: index, returnTo: s.uri.queryParameters['from']),
        s,
      );
    },
  ),
  GoRoute(path: '/wizard/finalize', pageBuilder: (c, s) => _page(const FinalizeSettingsScreen(), s)),
  GoRoute(path: '/wizard/review', pageBuilder: (c, s) => _page(const ReviewPublishScreen(), s)),
  GoRoute(path: '/wizard/success', pageBuilder: (c, s) => _page(const PublishSuccessScreen(), s)),

  // Grading
  GoRoute(
      path: '/grading/submissions',
      pageBuilder: (c, s) =>
          _page(SubmissionListScreen(examId: s.uri.queryParameters['exam']), s)),
  GoRoute(
    path: '/grading/manual/:id',
    pageBuilder: (c, s) =>
        _page(ManualGradingScreen(submissionId: s.pathParameters['id'] ?? ''), s),
  ),
  GoRoute(path: '/grading/manual', redirect: (c, s) => '/grading/manual/-'),

  // Analytics
  GoRoute(path: '/analytics/exam', pageBuilder: (c, s) => _page(const ExamAnalyticsScreen(), s)),
  GoRoute(path: '/analytics/class', pageBuilder: (c, s) => _page(const ClassHeatmapScreen(), s)),

  // Question bank / generation
  GoRoute(path: '/bank', pageBuilder: (c, s) => _page(const QuestionBankScreen(), s)),
  GoRoute(path: '/generate', pageBuilder: (c, s) => _page(const GenerateScreen(), s)),
  GoRoute(path: '/puc-paper', pageBuilder: (c, s) => _page(const PucPaperScreen(), s)),
  GoRoute(path: '/roster', pageBuilder: (c, s) => _page(const RosterScreen(), s)),
  GoRoute(
    path: '/notifications',
    pageBuilder: (c, s) => _page(
        NotificationsScreen(role: s.uri.queryParameters['role'] ?? 'teacher'), s),
  ),
];
