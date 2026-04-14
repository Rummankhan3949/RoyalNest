import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/manual_payment_model.dart';
import '../../models/payment_model.dart';
import '../../services/manual_payment_service.dart';
import '../../services/payment_service.dart';

class ClientManualPaymentsScreen extends StatelessWidget {
  const ClientManualPaymentsScreen({super.key});

  PaymentService get _paymentService => PaymentService();

  Color _statusColor(String status) {
    switch (status) {
      case ManualPaymentStatus.approved:
        return Colors.green;
      case ManualPaymentStatus.rejected:
        return Colors.red;
      default:
        return Colors.amber.shade800;
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final service = ManualPaymentService();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.royalBlue,
        title: const Text(
          'My Payments / Orders',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<List<ManualPaymentModel>>(
        stream: service.getMyPayments(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Could not load payments.',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            );
          }

          final payments = snapshot.data ?? [];
          if (payments.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.receipt_long,
                    size: 72,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'No payment orders yet.',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(14),
            itemCount: payments.length,
            itemBuilder: (context, index) {
              final payment = payments[index];
              final statusColor = _statusColor(payment.status);

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              payment.propertyName,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(40),
                            ),
                            child: Text(
                              payment.status.toUpperCase(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Amount: PKR ${payment.amount.toStringAsFixed(0)}'),
                      Text('Method: ${payment.paymentMethod}'),
                      const SizedBox(height: 8),
                      _buildInstallmentTracking(
                        context: context,
                        userId: userId,
                        manualPayment: payment,
                      ),
                      if (payment.rejectionReason != null &&
                          payment.rejectionReason!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Reason: ${payment.rejectionReason}',
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => _showProofPreview(
                              context,
                              payment.screenshotUrl,
                            ),
                            icon: const Icon(Icons.image_outlined),
                            label: const Text('View Proof'),
                          ),
                          if (payment.status == ManualPaymentStatus.approved)
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pushNamed(
                                  context,
                                  '/client-manual-payment-receipt',
                                  arguments: payment.id,
                                );
                              },
                              style: AppTheme.primaryButtonStyle,
                              icon: const Icon(
                                Icons.receipt_long,
                                color: Colors.white,
                              ),
                              label: const Text(
                                'View Receipt',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showProofPreview(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: InteractiveViewer(
          child: Image.network(url, fit: BoxFit.contain),
        ),
      ),
    );
  }

  Widget _buildInstallmentTracking({
    required BuildContext context,
    required String userId,
    required ManualPaymentModel manualPayment,
  }) {
    return FutureBuilder<PaymentModel?>(
      future: _resolveLinkedPayment(
        userId: userId,
        manualPayment: manualPayment,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LinearProgressIndicator(minHeight: 2);
        }

        final linkedPayment = snapshot.data;
        if (linkedPayment == null) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'Installment plan is being prepared. Please check again shortly.',
              style: TextStyle(fontSize: 12),
            ),
          );
        }

        final total = linkedPayment.totalInstallments <= 0
            ? 1
            : linkedPayment.totalInstallments;
        final paid = linkedPayment.paidInstallments.clamp(0, total);
        final pending = linkedPayment.status == 'paid'
            ? 0
            : (total - paid).clamp(0, total);
        final upcoming = pending <= 1 ? 0 : pending - 1;
        final nextInstallmentNo = paid + 1;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.lightBlue,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.royalBlue.withValues(alpha: 0.15),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Installment Tracking',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _metricChip('Paid', '$paid', Colors.green),
                  const SizedBox(width: 8),
                  _metricChip('Pending', '$pending', AppTheme.royalBlue),
                  const SizedBox(width: 8),
                  _metricChip('Upcoming', '$upcoming', Colors.grey),
                ],
              ),
              if (pending > 0) ...[
                const SizedBox(height: 10),
                Text(
                  'Next Installment #$nextInstallmentNo • PKR ${linkedPayment.monthlyInstallment.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  linkedPayment.nextDueDate != null
                      ? 'Due: ${linkedPayment.nextDueDate!.day}/${linkedPayment.nextDueDate!.month}/${linkedPayment.nextDueDate!.year}'
                      : 'Due date: to be confirmed by admin schedule',
                  style: const TextStyle(fontSize: 12, color: Colors.black87),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, '/client-payments');
                    },
                    style: AppTheme.primaryButtonStyle,
                    icon: const Icon(Icons.payment, color: Colors.white),
                    label: const Text(
                      'Pay Next Installment',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ] else
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'All installments are paid for this plot.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<PaymentModel?> _resolveLinkedPayment({
    required String userId,
    required ManualPaymentModel manualPayment,
  }) async {
    final linkedId = manualPayment.linkedPaymentId;
    if (linkedId != null && linkedId.isNotEmpty) {
      final byId = await _paymentService.getPaymentById(linkedId);
      if (byId != null) return byId;
    }

    return _paymentService.getPaymentByClientAndPlot(
      clientId: userId,
      plotId: manualPayment.propertyId,
    );
  }

  Widget _metricChip(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
