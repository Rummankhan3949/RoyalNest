import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/auth_service.dart';
import '../core/theme/app_theme.dart';
import '../services/app_startup_service.dart';
import 'admin/admin_home_screen.dart';
import 'auth/email_verification_screen.dart';
import 'auth/unified_auth_screen.dart';
import 'client/client_main_screen.dart';

/// Premium staged splash with typewriter effect and long visual hold.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const Duration _minimumVisualDuration = Duration(seconds: 8);
  static const String _appName = 'ROYALNEST';

  static const Duration _logoRevealDelay = Duration(milliseconds: 220);
  static const Duration _typingStartDelay = Duration(milliseconds: 520);
  static const Duration _typingStep = Duration(milliseconds: 100);
  static const Duration _loaderRevealDelay = Duration(milliseconds: 260);

  late final AnimationController _breathingController;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _textOpacity;
  late final Animation<double> _floatingOffset;

  bool _showLogo = false;
  bool _showText = false;
  bool _showLoader = false;
  int _typedCharacterCount = 0;

  @override
  void initState() {
    super.initState();

    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1900),
    )..repeat(reverse: true);

    _logoScale = Tween<double>(begin: 0.95, end: 1.04).animate(
      CurvedAnimation(parent: _breathingController, curve: Curves.easeInOut),
    );
    _logoOpacity = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _breathingController, curve: Curves.easeInOut),
    );
    _textOpacity = Tween<double>(begin: 0.75, end: 1.0).animate(
      CurvedAnimation(parent: _breathingController, curve: Curves.easeInOut),
    );
    _floatingOffset = Tween<double>(begin: -4, end: 4).animate(
      CurvedAnimation(
        parent: _breathingController,
        curve: Curves.easeInOutCubic,
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _configureSystemUi();
      _runSmartSplashSequence();
      _bootstrap();
    });
  }

  void _configureSystemUi() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
  }

  Future<void> _runSmartSplashSequence() async {
    await Future<void>.delayed(_logoRevealDelay);
    if (!mounted) {
      return;
    }
    setState(() => _showLogo = true);

    await Future<void>.delayed(_typingStartDelay);
    if (!mounted) {
      return;
    }
    setState(() => _showText = true);

    for (int i = 1; i <= _appName.length; i++) {
      if (!mounted) {
        return;
      }
      setState(() => _typedCharacterCount = i);
      await Future<void>.delayed(_typingStep);
    }

    await Future<void>.delayed(_loaderRevealDelay);
    if (!mounted) {
      return;
    }
    setState(() => _showLoader = true);
  }

  Future<void> _bootstrap() async {
    final startup = AppStartupService.instance;
    startup.startBackgroundInitialization();

    await Future<void>.delayed(_minimumVisualDuration);
    await startup.ensureCoreReady(timeout: const Duration(seconds: 4));

    if (!mounted) {
      return;
    }

    String targetRoute = '/login';
    try {
      final authService = AuthService();
      targetRoute = await authService.resolveStartupRoute();
    } catch (_) {
      targetRoute = '/login';
    }

    if (!mounted) {
      return;
    }

    final nextScreen = switch (targetRoute) {
      '/client-main' => const ClientMainScreen(),
      '/admin-home' => const AdminHomeScreen(),
      '/verify-email' => const EmailVerificationScreen(),
      _ => const UnifiedAuthScreen(),
    };

    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 520),
        reverseTransitionDuration: const Duration(milliseconds: 320),
        pageBuilder: (_, __, ___) => nextScreen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return FadeTransition(opacity: curved, child: child);
        },
      ),
    );

    startup.runPostNavigationWarmups();
  }

  @override
  void dispose() {
    _breathingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Center(
          child: AnimatedBuilder(
            animation: _breathingController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _floatingOffset.value),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 560),
                      curve: Curves.easeOutCubic,
                      opacity: _showLogo ? _logoOpacity.value : 0,
                      child: Transform.scale(
                        scale: _logoScale.value,
                        child: Container(
                          width: 178,
                          height: 178,
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: AppTheme.lightBlue.withValues(alpha: 0.55),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withValues(alpha: 0.55),
                                blurRadius: 36,
                                spreadRadius: 3,
                              ),
                              BoxShadow(
                                color: AppTheme.royalBlue.withValues(
                                  alpha: 0.16,
                                ),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Image.asset(
                            'assets/royalnest_logo.png',
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.home_work_rounded,
                                size: 86,
                                color: AppTheme.royalBlue,
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 26),
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOutCubic,
                      opacity: _showText ? _textOpacity.value : 0,
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(
                            color: AppTheme.royalBlue,
                            fontSize: 42,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 4.8,
                            shadows: [
                              Shadow(
                                color: AppTheme.royalBlue.withValues(
                                  alpha: 0.16,
                                ),
                                blurRadius: 14,
                              ),
                            ],
                          ),
                          children: [
                            TextSpan(
                              text: _appName.substring(0, _typedCharacterCount),
                            ),
                            TextSpan(
                              text: _typedCharacterCount < _appName.length
                                  ? '|'
                                  : '',
                              style: TextStyle(
                                color: AppTheme.royalBlue.withValues(
                                  alpha: _breathingController.value < 0.5
                                      ? 0.9
                                      : 0.2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 420),
                      curve: Curves.easeOut,
                      opacity: _showLoader ? 1 : 0,
                      child: Transform.translate(
                        offset: Offset(0, _showLoader ? 0 : 8),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppTheme.royalBlue.withValues(alpha: 0.9),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Loading secure experience...',
                              style: TextStyle(
                                color: AppTheme.secondaryTextColor.withValues(
                                  alpha: 0.9,
                                ),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
