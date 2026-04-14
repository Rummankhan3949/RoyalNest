import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../services/auth_service.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key, this.prefilledEmail});

  final String? prefilledEmail;

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  static const int _resendCooldownSeconds = 30;

  final AuthService _authService = AuthService();
  Timer? _resendTimer;
  Timer? _autoCheckTimer;

  bool _isChecking = false;
  bool _isResending = false;
  bool _didNavigate = false;
  int _remainingSeconds = _resendCooldownSeconds;

  String get _email {
    final currentUserEmail = FirebaseAuth.instance.currentUser?.email;
    if (currentUserEmail != null && currentUserEmail.trim().isNotEmpty) {
      return currentUserEmail;
    }
    return widget.prefilledEmail ?? '';
  }

  @override
  void initState() {
    super.initState();
    _startResendCooldown();
    _startAutoCheck();
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _autoCheckTimer?.cancel();
    super.dispose();
  }

  void _startResendCooldown() {
    _resendTimer?.cancel();
    setState(() => _remainingSeconds = _resendCooldownSeconds);

    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_remainingSeconds <= 1) {
        timer.cancel();
        setState(() => _remainingSeconds = 0);
      } else {
        setState(() => _remainingSeconds -= 1);
      }
    });
  }

  void _startAutoCheck() {
    _autoCheckTimer?.cancel();
    _autoCheckTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      _checkVerification(autoTriggered: true);
    });
  }

  Future<void> _checkVerification({bool autoTriggered = false}) async {
    if (_isChecking || _didNavigate) {
      return;
    }

    setState(() => _isChecking = true);

    try {
      final isVerified = await _authService.isCurrentUserEmailVerified();
      if (!mounted || _didNavigate) {
        return;
      }

      if (isVerified) {
        _didNavigate = true;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email verified successfully.'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        Navigator.of(context).pushReplacementNamed('/client-main');
        return;
      }

      if (!autoTriggered) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email not verified yet.'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      if (!autoTriggered) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not verify status. Please try again.'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isChecking = false);
      }
    }
  }

  Future<void> _resendVerificationEmail() async {
    if (_remainingSeconds > 0 || _isResending) {
      return;
    }

    setState(() => _isResending = true);

    final result = await _authService.sendVerificationEmail();
    if (!mounted) {
      return;
    }

    setState(() => _isResending = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['message']?.toString() ?? 'Please try again.'),
        backgroundColor: result['success'] == true
            ? AppTheme.successColor
            : AppTheme.errorColor,
      ),
    );

    if (result['success'] == true) {
      _startResendCooldown();
    }
  }

  Future<void> _goBackToLogin() async {
    await _authService.logout();
    if (!mounted) {
      return;
    }
    Navigator.of(context).pushReplacementNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.royalBlue,
        title: const Text(
          'Verify Email',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      height: 84,
                      width: 84,
                      decoration: BoxDecoration(
                        color: AppTheme.lightBlue,
                        borderRadius: BorderRadius.circular(42),
                      ),
                      child: const Icon(
                        Icons.mark_email_read_outlined,
                        color: AppTheme.royalBlue,
                        size: 42,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Check Your Inbox',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'A verification link has been sent to your email.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.secondaryTextColor,
                        height: 1.4,
                      ),
                    ),
                    if (_email.trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        _email,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppTheme.royalBlue,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isChecking
                            ? null
                            : () => _checkVerification(autoTriggered: false),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.royalBlue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isChecking
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'I have verified my email',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 50,
                      child: OutlinedButton(
                        onPressed: (_remainingSeconds == 0 && !_isResending)
                            ? _resendVerificationEmail
                            : null,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: AppTheme.royalBlue.withValues(alpha: 0.35),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isResending
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                _remainingSeconds == 0
                                    ? 'Resend Email'
                                    : 'Resend Email in ${_remainingSeconds}s',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _goBackToLogin,
                      child: const Text('Back to Login'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
