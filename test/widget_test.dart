import 'package:flutter_test/flutter_test.dart';

import 'package:olympiadpro_teacher/main.dart';

void main() {
  testWidgets('App boots to the login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const VidyoraApp());
    await tester.pump();

    // The login screen shows the brand and a sign-in call to action.
    expect(find.text('Vidyora'), findsWidgets);
    expect(find.text('Welcome Back'), findsOneWidget);
  });
}
