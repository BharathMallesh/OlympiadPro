import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Tracks network reachability. Call [init] once at startup.
/// Listen to [isOnline] for reactive UI updates.
class ConnectivityService {
  ConnectivityService._();
  static final ConnectivityService instance = ConnectivityService._();

  final isOnline = ValueNotifier<bool>(true);

  Future<void> init() async {
    final results = await Connectivity().checkConnectivity();
    isOnline.value = _hasConnection(results);
    Connectivity().onConnectivityChanged.listen((results) {
      isOnline.value = _hasConnection(results);
    });
  }

  static bool _hasConnection(List<ConnectivityResult> results) =>
      results.any((r) => r != ConnectivityResult.none);
}

final connectivity = ConnectivityService.instance;
