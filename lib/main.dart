import 'package:flutter/material.dart';
import 'app/router.dart';
import 'app/theme.dart';
import 'data/api.dart';
import 'data/store.dart';
import 'services/connectivity_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppStore.init();
  await api.init();
  await connectivity.init();
  // When any request gets a 401, clear the session and send the user to login.
  api.onUnauthorized = () => router.go('/login');
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
      // Overlay a persistent offline banner above every screen.
      builder: (context, child) => _ConnectivityOverlay(child: child),
    );
  }
}

/// Wraps the whole app so an offline banner can appear over any route.
class _ConnectivityOverlay extends StatelessWidget {
  const _ConnectivityOverlay({this.child});
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: connectivity.isOnline,
      builder: (context, online, _) {
        return Stack(
          children: [
            ?child,
            if (!online)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Material(
                  color: Colors.transparent,
                  child: SafeArea(
                    bottom: false,
                    child: Container(
                      width: double.infinity,
                      color: AppColors.error,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.wifi_off, size: 16, color: Colors.white),
                          SizedBox(width: 8),
                          Text('No internet connection',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
