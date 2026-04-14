import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';

import 'client_payment_receipt_screen.dart';

/// Premium animated Stripe checkout screen for card payments.
class ClientCheckoutScreen extends StatefulWidget {
  final String title;
  final String description;
  final double amount;
  final String currency;
  final String paymentPurpose;
  final Map<String, dynamic>? metadata;
  final Future<String?> Function(String? paymentIntentId) onSuccess;

  const ClientCheckoutScreen({
    super.key,
    required this.title,
    required this.description,
    required this.amount,
    this.currency = 'pkr',
    required this.paymentPurpose,
    this.metadata,
    required this.onSuccess,
  });

  @override
  State<ClientCheckoutScreen> createState() => _ClientCheckoutScreenState();
}

enum _CheckoutState { summary, processing, success, failed }

class _ClientCheckoutScreenState extends State<ClientCheckoutScreen>
    with TickerProviderStateMixin {
  _CheckoutState _state = _CheckoutState.summary;
  String _processingMessage = 'Preparing payment...';
  String _errorMessage = '';
  String? _receiptNumber;
  String? _paymentIntentId;

  // Animation controllers
  late AnimationController _cardController;
  late AnimationController _pulseController;
  late AnimationController _successController;
  late AnimationController _shakeController;
  late AnimationController _confettiController;

  // Animations
  late Animation<double> _cardSlide;
  late Animation<double> _cardFade;
  late Animation<double> _pulseAnimation;
  late Animation<double> _successScale;
  late Animation<double> _successRotation;
  late Animation<double> _shakeAnimation;

  // Confetti particles
  final List<_ConfettiParticle> _particles = [];
  final _random = Random();

  String _formatAmount(double amount) {
    if (amount >= 10000000) {
      return 'PKR ${(amount / 10000000).toStringAsFixed(2)} Cr';
    } else if (amount >= 100000) {
      return 'PKR ${(amount / 100000).toStringAsFixed(2)} Lac';
    }
    return 'PKR ${amount.toStringAsFixed(0)}';
  }

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    // Card entry animation
    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _cardSlide = Tween<double>(begin: 60, end: 0).animate(
      CurvedAnimation(parent: _cardController, curve: Curves.easeOutCubic),
    );
    _cardFade = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _cardController, curve: Curves.easeIn));
    _cardController.forward();

    // Pulse animation for processing
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Success animation
    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _successScale = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _successController,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );
    _successRotation = Tween<double>(begin: -0.5, end: 0).animate(
      CurvedAnimation(
        parent: _successController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    // Shake animation for failure
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 24).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );

    // Confetti animation
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );
  }

  void _generateConfetti() {
    _particles.clear();
    final colors = [
      const Color(0xFF4CAF50),
      const Color(0xFF2196F3),
      const Color(0xFFFFC107),
      const Color(0xFFE91E63),
      const Color(0xFF9C27B0),
      const Color(0xFFFF5722),
      AppTheme.royalBlue,
      Colors.white,
    ];

    for (int i = 0; i < 60; i++) {
      _particles.add(
        _ConfettiParticle(
          x: _random.nextDouble() * 400,
          y: -_random.nextDouble() * 200 - 50,
          speedX: (_random.nextDouble() - 0.5) * 4,
          speedY: _random.nextDouble() * 6 + 3,
          size: _random.nextDouble() * 8 + 4,
          color: colors[_random.nextInt(colors.length)],
          rotation: _random.nextDouble() * 2 * pi,
          rotationSpeed: (_random.nextDouble() - 0.5) * 0.3,
        ),
      );
    }
  }

  @override
  void dispose() {
    _cardController.dispose();
    _pulseController.dispose();
    _successController.dispose();
    _shakeController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _handlePay() async {
    setState(() {
      _state = _CheckoutState.processing;
      _processingMessage = 'Preparing payment...';
    });
    _pulseController.repeat(reverse: true);

    // Simulate payment processing delay since Stripe is removed
    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;

    setState(() => _processingMessage = 'Verifying payment...');

    // Generate a mock payment intent ID for the receipt
    _paymentIntentId = 'sys_${DateTime.now().millisecondsSinceEpoch}';

    try {
      // Record the installment and get receipt number
      final receiptNumber = await widget.onSuccess(_paymentIntentId);
      _receiptNumber = receiptNumber;

      if (!mounted) return;
      _pulseController.stop();

      // Trigger success animations
      setState(() => _state = _CheckoutState.success);
      HapticFeedback.heavyImpact();
      _generateConfetti();
      _successController.forward();
      _confettiController.forward();
    } catch (e) {
      if (!mounted) return;
      _pulseController.stop();
      setState(() {
        _state = _CheckoutState.failed;
        _errorMessage = 'An unexpected error occurred. Please try again.';
      });
      HapticFeedback.vibrate();
      _shakeController.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: _state == _CheckoutState.success
          ? null
          : AppBar(
              backgroundColor: AppTheme.royalBlue,
              elevation: 0,
              title: Text(
                widget.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              iconTheme: const IconThemeData(color: Colors.white),
            ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeIn,
        child: _buildCurrentState(),
      ),
    );
  }

  Widget _buildCurrentState() {
    switch (_state) {
      case _CheckoutState.summary:
        return _buildSummaryState();
      case _CheckoutState.processing:
        return _buildProcessingState();
      case _CheckoutState.success:
        return _buildSuccessState();
      case _CheckoutState.failed:
        return _buildFailedState();
    }
  }

  // ─── SUMMARY STATE ───
  Widget _buildSummaryState() {
    return AnimatedBuilder(
      animation: _cardController,
      builder: (context, child) {
        return Opacity(
          opacity: _cardFade.value,
          child: Transform.translate(
            offset: Offset(0, _cardSlide.value),
            child: child,
          ),
        );
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Amount card with gradient
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0050FF), Color(0xFF002899)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.royalBlue.withValues(alpha: 0.35),
                    blurRadius: 25,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.payment_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Payment Amount',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _formatAmount(widget.amount),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.currency.toUpperCase(),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Payment details card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Payment Details',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow(
                    Icons.description_outlined,
                    'Description',
                    widget.description,
                  ),
                  const Divider(height: 24),
                  _buildDetailRow(
                    Icons.category_outlined,
                    'Purpose',
                    widget.paymentPurpose == 'installment'
                        ? 'Installment Payment'
                        : widget.paymentPurpose,
                  ),
                  const Divider(height: 24),
                  _buildDetailRow(
                    Icons.credit_card_rounded,
                    'Method',
                    'Credit/Debit Card',
                  ),
                  const Divider(height: 24),
                  _buildDetailRow(
                    Icons.security_rounded,
                    'Security',
                    'SSL Encrypted & Secure',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Security note
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FFF4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFB7E4C7)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lock_rounded,
                    color: Colors.green.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Your payment is encrypted and processed securely.',
                      style: TextStyle(
                        color: Colors.green.shade800,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Pay button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.royalBlue,
                  foregroundColor: Colors.white,
                  elevation: 6,
                  shadowColor: AppTheme.royalBlue.withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: _handlePay,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.lock_rounded, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      'Pay ${_formatAmount(widget.amount)}',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.royalBlue.withValues(alpha: 0.7)),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.lightTextColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryTextColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─── PROCESSING STATE ───
  Widget _buildProcessingState() {
    return Center(
      key: const ValueKey('processing'),
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Transform.scale(scale: _pulseAnimation.value, child: child);
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated circles
            Stack(
              alignment: Alignment.center,
              children: [
                // Outer ring
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.royalBlue.withValues(alpha: 0.15),
                      width: 3,
                    ),
                  ),
                ),
                // Middle ring
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.royalBlue.withValues(alpha: 0.25),
                      width: 3,
                    ),
                  ),
                ),
                // Inner circle with spinner
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.royalBlue.withValues(alpha: 0.1),
                  ),
                  child: const Center(
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.royalBlue,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                _processingMessage,
                key: ValueKey(_processingMessage),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryTextColor,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Please do not close this screen',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  // ─── SUCCESS STATE ───
  Widget _buildSuccessState() {
    return Stack(
      children: [
        // Confetti layer
        AnimatedBuilder(
          animation: _confettiController,
          builder: (context, _) {
            return CustomPaint(
              size: MediaQuery.of(context).size,
              painter: _ConfettiPainter(
                particles: _particles,
                progress: _confettiController.value,
              ),
            );
          },
        ),

        // Success content
        SafeArea(
          child: Center(
            key: const ValueKey('success'),
            child: AnimatedBuilder(
              animation: _successController,
              builder: (context, child) {
                return Transform.scale(
                  scale: _successScale.value,
                  child: Transform.rotate(
                    angle: _successRotation.value,
                    child: child,
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Success icon
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withValues(alpha: 0.4),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 64,
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'Payment Successful!',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _formatAmount(widget.amount),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.green.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_receiptNumber != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Text(
                          'Receipt: $_receiptNumber',
                          style: TextStyle(
                            color: Colors.green.shade800,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    const SizedBox(height: 40),

                    // View Receipt button
                    if (_receiptNumber != null)
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.royalBlue,
                            foregroundColor: Colors.white,
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (_) => ClientPaymentReceiptScreen(
                                  receiptNumber: _receiptNumber!,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.receipt_long_rounded),
                          label: const Text(
                            'View Receipt',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),

                    const SizedBox(height: 12),

                    // Back to Payments button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.royalBlue,
                          side: const BorderSide(color: AppTheme.royalBlue),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text(
                          'Back to Payments',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── FAILED STATE ───
  Widget _buildFailedState() {
    return Center(
      key: const ValueKey('failed'),
      child: AnimatedBuilder(
        animation: _shakeController,
        builder: (context, child) {
          final shake =
              sin(_shakeAnimation.value * pi * 4) *
              (1 - _shakeController.value) *
              12;
          return Transform.translate(offset: Offset(shake, 0), child: child);
        },
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Failure icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red.shade50,
                  border: Border.all(color: Colors.red.shade200, width: 3),
                ),
                child: Icon(
                  Icons.close_rounded,
                  color: Colors.red.shade600,
                  size: 64,
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Payment Failed',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primaryTextColor,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),

              // Retry button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.royalBlue,
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    setState(() => _state = _CheckoutState.summary);
                    _cardController.forward(from: 0);
                  },
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text(
                    'Try Again',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Cancel button
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── CONFETTI ───

class _ConfettiParticle {
  double x;
  double y;
  final double speedX;
  final double speedY;
  final double size;
  final Color color;
  double rotation;
  final double rotationSpeed;

  _ConfettiParticle({
    required this.x,
    required this.y,
    required this.speedX,
    required this.speedY,
    required this.size,
    required this.color,
    required this.rotation,
    required this.rotationSpeed,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;
  final double progress;

  _ConfettiPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    for (final p in particles) {
      final currentY = p.y + progress * p.speedY * size.height * 0.4;
      final currentX = p.x + progress * p.speedX * 60;
      final opacity = (1 - progress).clamp(0.0, 1.0);

      paint.color = p.color.withValues(alpha: opacity);

      canvas.save();
      canvas.translate(currentX, currentY);
      canvas.rotate(p.rotation + progress * p.rotationSpeed * 20);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: p.size,
          height: p.size * 0.6,
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
