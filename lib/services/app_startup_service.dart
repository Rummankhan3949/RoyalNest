import 'dart:async';

import 'package:firebase_core/firebase_core.dart';

import '../firebase_options.dart';
import 'push_notification_service.dart';

class AppStartupService {
  AppStartupService._();

  static final AppStartupService instance = AppStartupService._();

  final Completer<void> _coreReadyCompleter = Completer<void>();
  bool _isStarted = false;

  bool get isCoreReady => _coreReadyCompleter.isCompleted;

  void startBackgroundInitialization() {
    if (_isStarted) {
      return;
    }

    _isStarted = true;
    unawaited(_initializeCore());
  }

  Future<bool> ensureCoreReady({
    Duration timeout = const Duration(seconds: 6),
  }) async {
    startBackgroundInitialization();

    try {
      await _coreReadyCompleter.future.timeout(timeout);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> runPostNavigationWarmups() async {
    startBackgroundInitialization();

    // Do not block UI navigation on these non-critical tasks.
    unawaited(_runWarmups());
  }

  Future<void> _initializeCore() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
    } catch (_) {
      // Keep startup resilient. Core readiness is still signaled below.
    } finally {
      if (!_coreReadyCompleter.isCompleted) {
        _coreReadyCompleter.complete();
      }
    }
  }

  Future<void> _runWarmups() async {
    await ensureCoreReady();

    try {
      await PushNotificationService().initializeForCurrentUser().timeout(
        const Duration(seconds: 3),
      );
    } catch (_) {}
  }
}
