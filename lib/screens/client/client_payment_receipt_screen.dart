import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';
import '../../models/receipt_model.dart';
import '../../services/payment_service.dart';

/// Premium payment receipt screen with animations
class ClientPaymentReceiptScreen extends StatefulWidget {
  final String receiptNumber;

  const ClientPaymentReceiptScreen({
    super.key,
    required this.receiptNumber,
  });

  @override
  State<ClientPaymentReceiptScreen> createState() =>
      _ClientPaymentReceiptScreenState();
}

class _ClientPaymentReceiptScreenState extends State<ClientPaymentReceiptScreen>
    with TickerProviderStateMixin {
  final PaymentService _paymentService = PaymentService();

  ReceiptModel? _receipt;
  bool _isLoading = true;

  late AnimationController _slideController;
  late AnimationController _stampController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _stampScale;
  late Animation<double> _stampRotation;
  late Animation<double> _stampOpacity;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadReceipt();
  }

  void _setupAnimations() {
    // Receipt slide-up animation
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeIn),
    );

    // PAID stamp animation
    _stampController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _stampScale = Tween<double>(begin: 3.0, end: 1.0).animate(
      CurvedAnimation(parent: _stampController, curve: Curves.elasticOut),
    );
    _stampRotation = Tween<double>(begin: -0.3, end: -0.15).animate(
      CurvedAnimation(parent: _stampController, curve: Curves.easeOut),
    );
    _stampOpacity = Tween<double>(begin: 0, end: 0.2).animate(
      CurvedAnimation(parent: _stampController, curve: Curves.easeIn),
    );
  }

  Future<void> _loadReceipt() async {
    final receipt =
        await _paymentService.getReceiptByNumber(widget.receiptNumber);
    if (mounted) {
      setState(() {
        _receipt = receipt;
        _isLoading = false;
      });
      if (receipt != null) {
        _slideController.forward();
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) _stampController.forward();
        });
      }
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    _stampController.dispose();
    super.dispose();
  }

  String _formatAmount(double amount) {
    if (amount >= 10000000) {
      return 'PKR ${(amount / 10000000).toStringAsFixed(2)} Crore';
    } else if (amount >= 100000) {
      return 'PKR ${(amount / 100000).toStringAsFixed(2)} Lac';
    }
    return 'PKR ${amount.toStringAsFixed(0)}';
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}, '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _copyReceiptInfo() {
    if (_receipt == null) return;

    final info = '''
═══════════════════════════════
     ROYAL NEST - PAYMENT RECEIPT
═══════════════════════════════

Receipt No: ${_receipt!.receiptNumber}
Date: ${_formatDate(_receipt!.paidDate)}
Status: ${_receipt!.status.toUpperCase()}

Client: ${_receipt!.clientName}
Plot: ${_receipt!.plotDetails}

Amount Paid: ${_formatAmount(_receipt!.amount)}
Payment Method: ${_receipt!.paymentMethod}
${_receipt!.stripePaymentIntentId != null ? 'Transaction ID: ${_receipt!.stripePaymentIntentId}' : ''}

Installment: ${_receipt!.installmentNumber} of ${_receipt!.totalInstallments}
Total Paid So Far: ${_formatAmount(_receipt!.totalPaidSoFar)}
Total Amount: ${_formatAmount(_receipt!.totalAmount)}

═══════════════════════════════
    Thank you for your payment!
═══════════════════════════════
''';

    Clipboard.setData(ClipboardData(text: info));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('Receipt copied to clipboard'),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        backgroundColor: AppTheme.royalBlue,
        elevation: 0,
        title: const Text(
          'Payment Receipt',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_receipt != null)
            IconButton(
              icon: const Icon(Icons.share_rounded, color: Colors.white),
              onPressed: _copyReceiptInfo,
              tooltip: 'Share Receipt',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.royalBlue),
            )
          : _receipt == null
              ? _buildNotFound()
              : _buildReceipt(),
    );
  }

  Widget _buildNotFound() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.receipt_long, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Receipt Not Found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Receipt ${widget.receiptNumber} was not found.',
            style: TextStyle(color: Colors.grey.shade500),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            style: AppTheme.primaryButtonStyle,
            onPressed: () => Navigator.pop(context),
            child: const Text('Go Back', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildReceipt() {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Receipt card
              Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 25,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Header
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF0050FF), Color(0xFF002899)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(20),
                            ),
                          ),
                          child: Column(
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.1),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: Image.asset(
                                    'assets/royalnest_logo.png',
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => const Icon(
                                      Icons.home_work_rounded,
                                      color: AppTheme.royalBlue,
                                      size: 30,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'ROYAL NEST',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 3,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Payment Receipt',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Receipt body
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              // Receipt number & date
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Receipt No.',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: AppTheme.lightTextColor,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _receipt!.receiptNumber,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.royalBlue,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      const Text(
                                        'Date & Time',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: AppTheme.lightTextColor,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _formatDate(_receipt!.paidDate),
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),

                              const SizedBox(height: 20),
                              _buildDottedDivider(),
                              const SizedBox(height: 20),

                              // Amount
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0FFF4),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: Colors.green.shade200,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    const Text(
                                      'Amount Paid',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      _formatAmount(_receipt!.amount),
                                      style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.green.shade700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade600,
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                      child: const Text(
                                        'COMPLETED',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 20),
                              _buildDottedDivider(),
                              const SizedBox(height: 20),

                              // Details
                              _buildReceiptRow('Client', _receipt!.clientName),
                              const SizedBox(height: 12),
                              _buildReceiptRow('Plot', _receipt!.plotDetails),
                              const SizedBox(height: 12),
                              _buildReceiptRow(
                                'Payment Method',
                                _receipt!.paymentMethod,
                              ),
                              if (_receipt!.stripePaymentIntentId !=
                                  null) ...[
                                const SizedBox(height: 12),
                                _buildReceiptRow(
                                  'Transaction ID',
                                  _receipt!.stripePaymentIntentId!,
                                  isSmall: true,
                                ),
                              ],

                              const SizedBox(height: 20),
                              _buildDottedDivider(),
                              const SizedBox(height: 20),

                              // Installment info
                              _buildReceiptRow(
                                'Installment',
                                '${_receipt!.installmentNumber} of ${_receipt!.totalInstallments}',
                              ),
                              const SizedBox(height: 12),
                              _buildReceiptRow(
                                'Total Paid So Far',
                                _formatAmount(_receipt!.totalPaidSoFar),
                              ),
                              const SizedBox(height: 12),
                              _buildReceiptRow(
                                'Total Amount',
                                _formatAmount(_receipt!.totalAmount),
                              ),
                              const SizedBox(height: 12),

                              // Progress bar
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: _receipt!.totalAmount > 0
                                      ? _receipt!.totalPaidSoFar /
                                          _receipt!.totalAmount
                                      : 0,
                                  backgroundColor: Colors.grey.shade200,
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                    AppTheme.royalBlue,
                                  ),
                                  minHeight: 6,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _receipt!.totalAmount > 0
                                    ? '${((_receipt!.totalPaidSoFar / _receipt!.totalAmount) * 100).toStringAsFixed(1)}% Complete'
                                    : '0% Complete',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade500,
                                ),
                              ),

                              const SizedBox(height: 20),
                              _buildDottedDivider(),
                              const SizedBox(height: 16),

                              // Footer
                              Text(
                                'Thank you for your payment!',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Royal Nest — Premium Real Estate Management',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // PAID stamp watermark
                  Positioned(
                    top: 200,
                    right: 30,
                    child: AnimatedBuilder(
                      animation: _stampController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _stampScale.value,
                          child: Transform.rotate(
                            angle: _stampRotation.value,
                            child: Opacity(
                              opacity: _stampOpacity.value,
                              child: child,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.green.shade700,
                            width: 4,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'PAID',
                          style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.w900,
                            color: Colors.green.shade700,
                            letterSpacing: 8,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.royalBlue,
                        side: const BorderSide(color: AppTheme.royalBlue),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _copyReceiptInfo,
                      icon: const Icon(Icons.copy_rounded, size: 20),
                      label: const Text(
                        'Copy',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.royalBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_rounded, size: 20),
                      label: const Text(
                        'Back',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value, {bool isSmall = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.secondaryTextColor,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: isSmall ? 11 : 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryTextColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDottedDivider() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final dashWidth = 5.0;
        final dashCount = (constraints.maxWidth / (dashWidth * 2)).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(dashCount, (_) {
            return SizedBox(
              width: dashWidth,
              height: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(color: Colors.grey.shade300),
              ),
            );
          }),
        );
      },
    );
  }
}
