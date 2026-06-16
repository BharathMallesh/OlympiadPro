import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/api.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/registration_screen.dart';
import '../screens/auth/institution_setup_screen.dart';
import '../screens/auth/onboarding_finalize_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/wizard/exam_details_screen.dart';
import '../screens/wizard/topic_exam_screen.dart';
import '../screens/wizard/target_audience_screen.dart';
import '../screens/wizard/scheduling_screen.dart';
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
import '../screens/student/practice_generator_screen.dart';
import '../screens/student/practice_review_screen.dart';
import '../screens/student/practice_session_screen.dart';
import '../screens/student/exam_question_screen.dart';
import '../screens/student/practice_results_screen.dart';
import '../screens/student/profile_screen.dart';
import '../screens/student/my_exams_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/bank/question_bank_screen.dart';
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

final router = GoRouter(
  // Restore the persisted session: api.init() has already run in main(),
  // so a signed-in user skips the login screen on relaunch.
  initialLocation: !api.signedIn
      ? '/login'
      : api.role == 'student'
          ? '/student/hub'
          : '/dashboard',
  routes: [
    GoRoute(path: '/login', pageBuilder: (c, s) => _page(const LoginScreen(), s)),
    GoRoute(path: '/register', pageBuilder: (c, s) => _page(const RegistrationScreen(), s)),
    GoRoute(path: '/register/institution', pageBuilder: (c, s) => _page(const InstitutionSetupScreen(), s)),
    GoRoute(path: '/register/finalize', pageBuilder: (c, s) => _page(const OnboardingFinalizeScreen(), s)),
    GoRoute(path: '/dashboard', pageBuilder: (c, s) => _page(const DashboardScreen(), s)),

    // Exam-creation wizard
    GoRoute(path: '/wizard/details', pageBuilder: (c, s) => _page(const ExamDetailsScreen(), s)),
    GoRoute(path: '/wizard/topic-exam', pageBuilder: (c, s) => _page(const TopicExamScreen(), s)),
    GoRoute(path: '/wizard/audience', pageBuilder: (c, s) => _page(const TargetAudienceScreen(), s)),
    GoRoute(path: '/wizard/scheduling', pageBuilder: (c, s) => _page(const SchedulingScreen(), s)),
    GoRoute(path: '/wizard/upload', pageBuilder: (c, s) => _page(const UploadPaperScreen(), s)),
    GoRoute(path: '/wizard/ai-review', pageBuilder: (c, s) => _page(const AiReviewScreen(), s)),
    GoRoute(
      path: '/wizard/edit-question/:index',
      pageBuilder: (c, s) {
        final raw = s.pathParameters['index'] ?? '0';
        final index = raw == 'new' ? -1 : (int.tryParse(raw) ?? 0);
        return _page(
          EditQuestionScreen(
              index: index, returnTo: s.uri.queryParameters['from']),
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
        pageBuilder: (c, s) => _page(
            SubmissionListScreen(examId: s.uri.queryParameters['exam']), s)),
    GoRoute(
      path: '/grading/manual/:id',
      pageBuilder: (c, s) =>
          _page(ManualGradingScreen(submissionId: s.pathParameters['id'] ?? ''), s),
    ),
    GoRoute(path: '/grading/manual', redirect: (c, s) => '/grading/manual/-'),

    // Analytics
    GoRoute(path: '/analytics/exam', pageBuilder: (c, s) => _page(const ExamAnalyticsScreen(), s)),
    GoRoute(path: '/analytics/class', pageBuilder: (c, s) => _page(const ClassHeatmapScreen(), s)),

    // ---- Student flow ----
    GoRoute(path: '/student/register', pageBuilder: (c, s) => _page(const StudentRegistrationScreen(), s)),
    GoRoute(path: '/student/interests', pageBuilder: (c, s) => _page(const AcademicInterestsScreen(), s)),
    GoRoute(path: '/student/join-class', pageBuilder: (c, s) => _page(const JoinClassScreen(), s)),
    GoRoute(path: '/student/hub', pageBuilder: (c, s) => _page(const StudentHubScreen(), s)),
    GoRoute(path: '/student/practice-generator', pageBuilder: (c, s) => _page(const PracticeGeneratorScreen(), s)),
    GoRoute(
        path: '/student/exam',
        pageBuilder: (c, s) => _page(
            ExamQuestionScreen(examId: s.uri.queryParameters['exam'] ?? ''),
            s)),
    GoRoute(
        path: '/student/practice-session',
        pageBuilder: (c, s) => _page(
            PracticeSessionScreen(questions: s.extra as List<dynamic>), s)),
    GoRoute(
        path: '/student/practice-results',
        pageBuilder: (c, s) => _page(
            PracticeResultsScreen(
                payload: (s.extra as Map<String, dynamic>?) ?? const {}),
            s)),
    GoRoute(
        path: '/student/practice-review',
        pageBuilder: (c, s) => _page(
            PracticeReviewScreen(
                sessionId: s.uri.queryParameters['session'] ?? ''),
            s)),
    GoRoute(path: '/student/profile', pageBuilder: (c, s) => _page(const StudentProfileScreen(), s)),
    GoRoute(path: '/student/exams', pageBuilder: (c, s) => _page(const MyExamsScreen(), s)),
    GoRoute(path: '/student/settings', pageBuilder: (c, s) => _page(const SettingsScreen(role: 'student'), s)),

    // ---- Shared / new flows ----
    GoRoute(path: '/forgot-password', pageBuilder: (c, s) => _page(const ForgotPasswordScreen(), s)),
    GoRoute(path: '/bank', pageBuilder: (c, s) => _page(const QuestionBankScreen(), s)),
    GoRoute(
      path: '/notifications',
      pageBuilder: (c, s) => _page(
          NotificationsScreen(role: s.uri.queryParameters['role'] ?? 'teacher'), s),
    ),
    GoRoute(path: '/settings', pageBuilder: (c, s) => _page(const SettingsScreen(), s)),
    GoRoute(path: '/roster', pageBuilder: (c, s) => _page(const RosterScreen(), s)),
  ],
);
