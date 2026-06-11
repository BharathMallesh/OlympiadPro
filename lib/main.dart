import 'package:flutter/material.dart';
import 'app/router.dart';
import 'app/theme.dart';
import 'data/store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppStore.init();
  runApp(const OlympiadProApp());
}

class OlympiadProApp extends StatelessWidget {
  const OlympiadProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'OlympiadPro · Educator',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      routerConfig: router,
    );
  }
}
