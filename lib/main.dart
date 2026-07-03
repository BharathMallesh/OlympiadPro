import 'app/flavor.dart';
import 'main_common.dart';

/// Default entrypoint (a bare `flutter run` / web build) → the Educator app.
/// The dedicated apps use lib/main_student.dart, main_teacher.dart, main_admin.dart.
void main() => bootstrap(AppFlavor.teacher);
