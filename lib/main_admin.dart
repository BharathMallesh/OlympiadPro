import 'app/flavor.dart';
import 'main_common.dart';

/// Vidyora Admin — the founder/super-admin app. Shares the educator surface for
/// now (dashboard, authoring, analytics); admin-only screens (institutions,
/// validators) can be added behind [AppFlavor.admin] later.
/// Build: flutter run --flavor admin -t lib/main_admin.dart
void main() => bootstrap(AppFlavor.admin);
