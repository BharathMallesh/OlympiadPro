/// Which of the three Vidyora apps this build is: student, teacher, or admin.
///
/// All three ship from ONE codebase (shared Repo/ApiClient/theme/widgets) but
/// build as separate installable apps via `--flavor` + a per-app entrypoint
/// (`lib/main_student.dart`, `lib/main_teacher.dart`, `lib/main_admin.dart`).
/// The flavor decides the login form, the landing route, the visible route set,
/// and the app title/branding.
enum AppFlavor { student, teacher, admin }

/// Set once by the entrypoint before `runApp`. Defaults to teacher so a bare
/// `flutter run` (which uses `lib/main.dart`) behaves like the educator app.
AppFlavor appFlavor = AppFlavor.teacher;

extension AppFlavorX on AppFlavor {
  bool get isStudent => this == AppFlavor.student;
  bool get isAdmin => this == AppFlavor.admin;

  /// Educator = teacher or admin: both use the dashboard/authoring surface.
  bool get isEducator => this == AppFlavor.teacher || this == AppFlavor.admin;

  /// Window/app title.
  String get title => switch (this) {
        AppFlavor.student => 'Vidyora',
        AppFlavor.teacher => 'Vidyora · Educator',
        AppFlavor.admin => 'Vidyora · Admin',
      };

  /// Where a signed-in user lands.
  String get landing => isStudent ? '/student/hub' : '/dashboard';
}
