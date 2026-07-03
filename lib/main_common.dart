import 'package:flutter/material.dart';
import 'app/flavor.dart';
import 'app/router.dart';
import 'app/theme.dart';
import 'data/api.dart';
import 'data/store.dart';
import 'services/connectivity_service.dart';

/// Shared entrypoint for all three Vidyora apps. Each `main_*.dart` calls this
/// with its flavor; everything else (init, theme, connectivity, 401 handling)
/// is identical.
Future<void> bootstrap(AppFlavor flavor) async {
  WidgetsFlutterBinding.ensureInitialized();
  appFlavor = flavor;
  await AppStore.init();
  await api.init();
  await connectivity.init();
  final r = createRouter(flavor);
  // When any request gets a 401, clear the session and send the user to login.
  api.onUnauthorized = () => r.go('/login');
  runApp(VidyoraApp(router: r, title: flavor.title));
}

class VidyoraApp extends StatelessWidget {
  const VidyoraApp({super.key, required this.router, required this.title});
  final RouterConfig<Object> router;
  final String title;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: title,
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
