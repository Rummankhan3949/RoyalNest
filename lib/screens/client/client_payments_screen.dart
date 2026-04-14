import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../core/theme/app_theme.dart';
import '../../models/payment_model.dart';
import '../../models/payment_method_model.dart';
import '../../services/manual_payment_service.dart';
import '../../services/payment_service.dart';
import 'client_manual_payment_screen.dart';
import 'client_payment_receipt_screen.dart';
import 'client_drawer.dart';

/// Client Payments Screen with real-time updates and animations
class ClientPaymentsScreen extends StatefulWidget {
  const ClientPaymentsScreen({super.key});

  @override
  State<ClientPaymentsScreen> createState() => _ClientPaymentsScreenState();
}

class _ClientPaymentsScreenState extends State<ClientPaymentsScreen>
    with SingleTickerProviderStateMixin {
  final PaymentService _paymentService = PaymentService();
  final ManualPaymentService _manualPaymentService = ManualPaymentService();
  String get userId => FirebaseAuth.instance.currentUser?.uid ?? '';

  late AnimationController _listAnimController;

  @override
  void initState() {
    super.initState();
    _listAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _listAnimController.forward();
  }

  @override
  void dispose() {
    _listAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.royalBlue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'My Payments',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: const ClientDrawer(),
      body: Column(
        children: [
          _buildPaymentSummary(),
          Expanded(
            child: StreamBuilder<List<PaymentModel>>(
              stream: _paymentService.getClientPayments(userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final payments = snapshot.data ?? [];

                if (payments.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.payment_outlined,
                          size: 80,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No Payment Records',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your payment history will appear here',
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: payments.length,
                  itemBuilder: (context, index) {
                    // Staggered fade-in animation
                    final delay = (index * 0.15).clamp(0.0, 1.0);
                    final end = (delay + 0.5).clamp(0.0, 1.0);
                    final animation = Tween<double>(begin: 0, end: 1).animate(
                      CurvedAnimation(
                        parent: _listAnimController,
                        curve: Interval(delay, end, curve: Curves.easeOutCubic),
                      ),
                    );

                    return AnimatedBuilder(
                      animation: animation,
                      builder: (context, child) {
                        return Opacity(
                          opacity: animation.value,
                          child: Transform.translate(
                            offset: Offset(0, 30 * (1 - animation.value)),
                            child: child,
                          ),
                        );
                      },
                      child: _buildPaymentCard(payments[index]),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSummary() {
    return FutureBuilder<Map<String, double>>(
      future: _paymentService.getClientPaymentSummary(userId),
      builder: (context, snapshot) {
        final data = snapshot.data ?? {};
        final total = data['total'] ?? 0.0;
        final paid = data['paid'] ?? 0.0;
        final remaining = total - paid;

        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(AppTheme.largeRadius),
            boxShadow: [
              BoxShadow(
                color: AppTheme.royalBlue.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              const Text(
                'Payment Overview',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryItem('Total', _formatAmount(total)),
                  ),
                  Container(width: 1, height: 40, color: Colors.white30),
                  Expanded(
                    child: _buildSummaryItem('Paid', _formatAmount(paid)),
                  ),
                  Container(width: 1, height: 40, color: Colors.white30),
                  Expanded(
                    child: _buildSummaryItem(
                      'Remaining',
                      _formatAmount(remaining),
                    ),
                  ),
                ],
              ),
              if (total > 0) ...[
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: total > 0 ? paid / total : 0,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${((paid / total) * 100).toStringAsFixed(1)}% Completed',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentCard(PaymentModel payment) {
    final totalInstallments = _safeTotalInstallments(payment);
    final paidInstallments = _paidInstallments(payment);
    final unpaidInstallments = _unpaidInstallments(payment);
    final upcomingInstallments = _upcomingInstallments(payment);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
        boxShadow: AppTheme.lightShadow,
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppTheme.lightBlue,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppTheme.mediumRadius),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.royalBlue,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.landscape,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        payment.plotDetails,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        '$paidInstallments/$totalInstallments Installments',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(payment.status),
              ],
            ),
          ),

          // Progress
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildInstallmentTimelineStrip(payment),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Progress',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      '${payment.progressPercentage.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.royalBlue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: payment.progressPercentage / 100,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      payment.progressPercentage > 80
                          ? Colors.green
                          : payment.progressPercentage > 50
                          ? Colors.blue
                          : Colors.orange,
                    ),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildAmountItem(
                        'Total Amount',
                        _formatAmount(payment.totalAmount),
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildAmountItem(
                        'Paid',
                        _formatAmount(payment.paidAmount),
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildAmountItem(
                        'Remaining',
                        _formatAmount(payment.remainingAmount),
                        Colors.orange,
                      ),
                    ),
                  ],
                ),
                if (unpaidInstallments > 0) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.orange.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.event,
                              color: Colors.orange,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Next Payment Due',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.orange,
                                    ),
                                  ),
                                  Text(
                                    payment.nextDueDate != null
                                        ? _formatDate(payment.nextDueDate)
                                        : 'Due soon',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              _formatAmount(payment.monthlyInstallment),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.royalBlue,
                              foregroundColor: Colors.white,
                              elevation: 4,
                              shadowColor: AppTheme.royalBlue.withValues(
                                alpha: 0.3,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () => _navigateToCheckout(payment),
                            icon: const Icon(
                              Icons.payment_rounded,
                              color: Colors.white,
                            ),
                            label: const Text(
                              'Pay Next Installment',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: AppTheme.outlineButtonStyle,
                    onPressed: () => _showPaymentHistory(payment),
                    icon: const Icon(Icons.history),
                    label: Text(
                      'History • Unpaid: $unpaidInstallments • Upcoming: $upcomingInstallments',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToCheckout(PaymentModel payment) async {
    final nextInstallmentNumber = (payment.paidInstallments + 1).clamp(
      1,
      _safeTotalInstallments(payment),
    );

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ClientManualPaymentScreen(
          propertyId: payment.plotId,
          propertyName: payment.plotDetails,
          amount: payment.monthlyInstallment,
          linkedPaymentId: payment.id,
          installmentNumber: nextInstallmentNumber,
          installmentType: 'installment',
          isOnlineFlow: true,
          initialMode: 'online',
          hasVoucher: true,
          onDownloadChallan: () =>
              _downloadInstallmentVoucher(payment, nextInstallmentNumber),
        ),
      ),
    );

    if (!mounted) return;
    _listAnimController.forward(from: 0);
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;

    switch (status) {
      case 'paid':
        color = Colors.green;
        label = 'Paid';
        break;
      case 'partial':
        color = Colors.blue;
        label = 'Active';
        break;
      default:
        color = Colors.orange;
        label = 'Unpaid';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInstallmentTimelineStrip(PaymentModel payment) {
    final paidInstallments = _paidInstallments(payment);
    final unpaidInstallments = _unpaidInstallments(payment);
    final upcomingInstallments = _upcomingInstallments(payment);
    final isOverdue =
        payment.nextDueDate != null &&
        payment.status != 'paid' &&
        payment.nextDueDate!.isBefore(DateTime.now());

    Widget item({
      required IconData icon,
      required String label,
      required String value,
      required Color color,
    }) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            item(
              icon: Icons.check_circle,
              label: 'Paid',
              value: '$paidInstallments',
              color: Colors.green,
            ),
            const SizedBox(width: 10),
            item(
              icon: Icons.play_circle,
              label: 'Unpaid',
              value: '$unpaidInstallments',
              color: AppTheme.royalBlue,
            ),
            const SizedBox(width: 10),
            item(
              icon: Icons.schedule,
              label: 'Upcoming',
              value: '$upcomingInstallments',
              color: Colors.orange,
            ),
          ],
        ),
        if (payment.nextDueDate != null && payment.status != 'paid') ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isOverdue
                    ? Colors.red.withValues(alpha: 0.12)
                    : Colors.orange.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Text(
                isOverdue
                    ? 'Overdue since ${_formatDate(payment.nextDueDate)}'
                    : 'Next due: ${_formatDate(payment.nextDueDate)}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isOverdue ? Colors.red : Colors.orange.shade800,
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 10),
        _buildInstallmentStepper(payment),
      ],
    );
  }

  Widget _buildInstallmentStepper(PaymentModel payment) {
    final total = _safeTotalInstallments(payment);
    final paid = _paidInstallments(payment);
    final unpaid = _unpaidInstallments(payment);
    final current = unpaid > 0 ? (paid + 1).clamp(1, total) : 0;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(total, (index) {
          final number = index + 1;
          final isPaid = number <= paid;
          final isCurrent = current > 0 && !isPaid && number == current;
          final color = isPaid
              ? Colors.green
              : isCurrent
              ? AppTheme.royalBlue
              : Colors.grey;

          return Row(
            children: [
              Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 280),
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: color.withValues(
                        alpha: isPaid || isCurrent ? 0.2 : 0.12,
                      ),
                      border: Border.all(color: color, width: 1.4),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: isPaid
                          ? const Icon(
                              Icons.check,
                              size: 14,
                              color: Colors.green,
                            )
                          : Text(
                              '$number',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: color,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isPaid
                        ? 'Paid'
                        : isCurrent
                        ? 'Unpaid'
                        : 'Upcoming',
                    style: TextStyle(
                      fontSize: 9,
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              if (number < total)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 280),
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  width: 20,
                  height: 2,
                  color: number <= payment.paidInstallments
                      ? Colors.green
                      : Colors.grey.shade300,
                ),
            ],
          );
        }),
      ),
    );
  }

  int _safeTotalInstallments(PaymentModel payment) {
    if (payment.totalInstallments > 0) {
      return payment.totalInstallments;
    }
    if (payment.installmentHistory.isNotEmpty) {
      return payment.installmentHistory.length + 1;
    }
    return 1;
  }

  int _paidInstallments(PaymentModel payment) {
    return payment.paidInstallments.clamp(0, _safeTotalInstallments(payment));
  }

  int _unpaidInstallments(PaymentModel payment) {
    if (payment.status == 'paid') return 0;
    final total = _safeTotalInstallments(payment);
    final paid = _paidInstallments(payment);
    return (total - paid).clamp(0, total);
  }

  int _upcomingInstallments(PaymentModel payment) {
    final unpaid = _unpaidInstallments(payment);
    if (unpaid <= 1) return 0;
    return unpaid - 1;
  }

  Future<void> _downloadInstallmentVoucher(
    PaymentModel payment,
    int installmentNumber,
  ) async {
    List<PaymentMethodModel> methods = [];
    try {
      methods = await _manualPaymentService.getActivePaymentMethodsOnce();
    } catch (_) {
      methods = [];
    }

    final bytes = await _buildInstallmentVoucherPdf(
      payment: payment,
      installmentNumber: installmentNumber,
      paymentMethods: methods,
    );

    await Printing.sharePdf(
      bytes: bytes,
      filename:
          'royalnest_installment_${payment.plotId}_$installmentNumber.pdf',
    );
  }

  Future<Uint8List> _buildInstallmentVoucherPdf({
    required PaymentModel payment,
    required int installmentNumber,
    required List<PaymentMethodModel> paymentMethods,
  }) async {
    final doc = pw.Document();
    final now = DateTime.now();
    final issuedAt =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final voucherNumber =
        'RN-INS-${payment.plotId.toUpperCase()}-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';

    pw.Widget item(String label, String value, {bool strong = false}) {
      return pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 8),
        child: pw.Row(
          children: [
            pw.SizedBox(
              width: 160,
              child: pw.Text(
                label,
                style: const pw.TextStyle(
                  fontSize: 11,
                  color: PdfColors.blueGrey800,
                ),
              ),
            ),
            pw.Expanded(
              child: pw.Text(
                value,
                style: pw.TextStyle(
                  fontSize: strong ? 13 : 11,
                  fontWeight: strong
                      ? pw.FontWeight.bold
                      : pw.FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      );
    }

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (_) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(14),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.blue900,
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'ROYAL NEST - INSTALLMENT VOUCHER',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      pw.Text(
                        voucherNumber,
                        style: const pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 16),
                item('Issued At', issuedAt),
                item('Plot', payment.plotDetails),
                item('Client', payment.clientName),
                item('Installment Number', '#$installmentNumber'),
                item(
                  'Amount Due Now',
                  'PKR ${payment.monthlyInstallment.toStringAsFixed(0)}',
                  strong: true,
                ),
                item(
                  'Due Date',
                  payment.nextDueDate != null
                      ? _formatDate(payment.nextDueDate)
                      : 'Due soon',
                ),
                pw.Divider(color: PdfColors.grey400),
                pw.Text(
                  'Admin Payment Channels',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                pw.SizedBox(height: 6),
                if (paymentMethods.isEmpty)
                  item(
                    'Account Details',
                    'Will be provided in app payment methods',
                  )
                else
                  ...paymentMethods
                      .take(4)
                      .map(
                        (method) => item(
                          method.methodName,
                          '${method.accountTitle} - ${method.accountNumber}',
                        ),
                      ),
                pw.SizedBox(height: 16),
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Text(
                    'Instructions: Pay only the currently due installment amount shown above, then upload paid proof in app for admin verification.',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    return doc.save();
  }

  Widget _buildAmountItem(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 10, color: color)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 10000000) {
      return 'PKR ${(amount / 10000000).toStringAsFixed(2)} Cr';
    } else if (amount >= 100000) {
      return 'PKR ${(amount / 100000).toStringAsFixed(2)} L';
    }
    return 'PKR ${amount.toStringAsFixed(0)}';
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showPaymentHistory(PaymentModel payment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Payment History',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: payment.installmentHistory.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.history,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No payments yet',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: payment.installmentHistory.length,
                      itemBuilder: (context, index) {
                        final installment = payment.installmentHistory[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Text(
                                    '#${installment.installmentNumber}',
                                    style: const TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _formatAmount(installment.amount),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      installment.paymentMethod,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    _formatDate(installment.paidDate),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  if (installment.receiptNumber != null)
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.pop(ctx);
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                ClientPaymentReceiptScreen(
                                                  receiptNumber: installment
                                                      .receiptNumber!,
                                                ),
                                          ),
                                        );
                                      },
                                      child: Container(
                                        margin: const EdgeInsets.only(top: 4),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppTheme.royalBlue.withValues(
                                            alpha: 0.1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.receipt_long,
                                              size: 12,
                                              color: AppTheme.royalBlue,
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              'View Receipt',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: AppTheme.royalBlue,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
