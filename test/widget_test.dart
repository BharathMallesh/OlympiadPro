import 'package:flutter_test/flutter_test.dart';

import 'package:olympiadpro_teacher/app/flavor.dart';
import 'package:olympiadpro_teacher/app/router.dart';
import 'package:olympiadpro_teacher/main_common.dart';

void main() {
  testWidgets('App boots to the login screen', (WidgetTester tester) async {
    final router = createRouter(AppFlavor.teacher);
    await tester.pumpWidget(VidyoraApp(router: router, title: 'Vidyora'));
    await tester.pump();

    // The login screen shows the brand and a sign-in call to action.
    expect(find.text('Vidyora'), findsWidgets);
    expect(find.text('Welcome Back'), findsOneWidget);
  });
}
