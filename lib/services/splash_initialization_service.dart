import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';
import 'payment_service.dart';
import 'push_notification_service.dart';

/// ZERO PERCEIVED DELAY INITIALIZATION SERVICE
/// Performance-optimized app startup with deferred heavy work
///
/// Architecture for fastest perceived startup:
/// 1. Called AFTER splash screen first frame is painted (addPostFrameCallback)
/// 2. WidgetsFlutterBinding initialized during splash (not blocking app open)
/// 3. Firebase and heavy operations run in background while splash displays
/// 4. Progress callbacks keep user informed (professional UX)
/// 5. Minimum splash time ensures smooth experience (not rushed)
///
/// Usage:
/// ```dart
/// // Only call after splash is visible!
/// WidgetsBinding.instance.addPostFrameCallback((_) {
///   final service = SplashInitializationService();
///   await service.initialize(onProgress: (msg) => updateUI(msg));
/// });
/// ```
class SplashInitializationService {
  bool _isInitialized = false;

  /// Check if initialization is complete
  bool get isInitialized => _isInitialized;

  /// Initialize all app dependencies with professional progress tracking
  ///
  /// [onProgress]: Real-time callback for user feedback (e.g., "Loading...")
  /// [minDuration]: Minimum splash duration for smooth UX (default 4s)
  ///
  /// CRITICAL: This must be called AFTER splash screen is visible
  /// All heavy work happens during splash display, not before app opens
  Future<void> initialize({
    void Function(String message)? onProgress,
    Duration minDuration = const Duration(milliseconds: 400),
  }) async {
    if (_isInitialized) return;

    final startTime = DateTime.now();

    try {
      onProgress?.call('Initializing...');
      await _ensureFlutterBindingAsync();

      onProgress?.call('Connecting to services...');
      await _initializeFirebase();

      onProgress?.call('Loading configuration...');
      await Future.wait([_loadAppConfiguration(), _preCacheData()]);

      onProgress?.call('Preparing notifications...');
      await PushNotificationService().initializeForCurrentUser();

      // Ensure minimum splash duration for professional feel (not rushed)
      final elapsed = DateTime.now().difference(startTime);
      if (elapsed < minDuration) {
        final remaining = minDuration - elapsed;
        onProgress?.call('Ready!');
        await Future.delayed(remaining);
      }

      _isInitialized = true;
    } catch (e) {
      onProgress?.call('Error: ${e.toString()}');
      rethrow;
    }
  }

  /// Ensure WidgetsFlutterBinding is initialized
  Future<void> _ensureFlutterBindingAsync() async {
    WidgetsFlutterBinding.ensureInitialized();
  }

  /// Initialize Firebase with retry logic
  Future<void> _initializeFirebase() async {
    int retries = 3;
    while (retries > 0) {
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        return;
      } catch (e) {
        retries--;
        if (retries == 0) {
          throw Exception('Firebase initialization failed: $e');
        }
        await Future.delayed(const Duration(milliseconds: 200));
      }
    }
  }

  /// Load app-wide configuration
  Future<void> _loadAppConfiguration() async {
    // Add your configuration loading logic here
    // Examples:
    // - Load shared preferences
    // - Load remote config
    // - Set up crash reporting
    // Intentionally no artificial delay
  }

  /// Pre-cache critical data for faster app startup
  Future<void> _preCacheData() async {
    // Run reminder sweep with a strict timeout so startup remains fast.
    try {
      await PaymentService().runReminderSweepIfDue().timeout(
        const Duration(seconds: 2),
      );
    } catch (_) {
      // Ignore preload failures to keep launch resilient.
    }
  }

  /// Reset initialization state (useful for testing)
  void reset() {
    _isInitialized = false;
  }
}
