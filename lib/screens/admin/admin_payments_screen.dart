import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';
import '../../models/document_model.dart';
import '../../models/payment_model.dart';
import '../../services/document_service.dart';
import '../../services/payment_service.dart';
import 'admin_drawer.dart';

/// Admin Payments & Installments Screen
class AdminPaymentsScreen extends StatefulWidget {
  const AdminPaymentsScreen({super.key});

  @override
  State<AdminPaymentsScreen> createState() => _AdminPaymentsScreenState();
}

class _AdminPaymentsScreenState extends State<AdminPaymentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final PaymentService _paymentService = PaymentService();
  final DocumentService _documentService = DocumentService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.royalBlue,
        title: const Text(
          'Payments & Installments',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active, color: Colors.white),
            onPressed: _sendBulkReminders,
            tooltip: 'Send Bulk Reminders',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Unpaid'),
            Tab(text: 'Partial'),
            Tab(text: 'Paid'),
          ],
        ),
      ),
      drawer: const AdminDrawer(),
      body: Column(
        children: [
          _buildStatsBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPaymentsList('unpaid'),
                _buildPaymentsList('partial'),
                _buildPaymentsList('paid'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBar() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _paymentService.getPaymentStats(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(height: 80);
        }

        final stats = snapshot.data!;
        return Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            children: [
              _buildStatCard(
                'Total',
                _formatAmount(stats['totalAmount'] ?? 0),
                Colors.blue,
              ),
              _buildStatCard(
                'Received',
                _formatAmount(stats['paidAmount'] ?? 0),
                Colors.green,
              ),
              _buildStatCard(
                'Pending',
                _formatAmount(stats['remainingAmount'] ?? 0),
                Colors.orange,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentsList(String status) {
    return StreamBuilder<List<PaymentModel>>(
      stream: _paymentService.getPaymentsByStatus(status),
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
                  status == 'paid' ? Icons.check_circle_outline : Icons.payment,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'No $status payments',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: payments.length,
          itemBuilder: (context, index) => _buildPaymentCard(payments[index]),
        );
      },
    );
  }

  Widget _buildPaymentCard(PaymentModel payment) {
    final totalInstallments = payment.totalInstallments <= 0
        ? 1
        : payment.totalInstallments;
    final remainingInstallments = (totalInstallments - payment.paidInstallments)
        .clamp(0, totalInstallments);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppTheme.cardDecoration,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.royalBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: AppTheme.royalBlue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        payment.clientName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        payment.plotDetails,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(payment.status),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Amount:',
                        style: TextStyle(color: Colors.grey),
                      ),
                      Text(
                        _formatAmount(payment.totalAmount),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Paid:',
                        style: TextStyle(color: Colors.green),
                      ),
                      Text(
                        _formatAmount(payment.paidAmount),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Remaining:',
                        style: TextStyle(color: Colors.orange),
                      ),
                      Text(
                        _formatAmount(payment.remainingAmount),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '${payment.paidInstallments}/${payment.totalInstallments}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.royalBlue,
                        ),
                      ),
                      const Text(
                        'Installments',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
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
                      const SizedBox(height: 4),
                      Text(
                        '${payment.progressPercentage.toStringAsFixed(1)}% Complete',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInstallmentBreakdownStrip(payment),
            const SizedBox(height: 10),
            _buildAdminInstallmentStatusRow(payment),
            if (payment.paidInstallments >= 1 && remainingInstallments > 0) ...[
              const SizedBox(height: 10),
              _buildAdminPredictionCard(payment, remainingInstallments),
            ],
            if (payment.nextDueDate != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.event, size: 16, color: Colors.orange),
                    const SizedBox(width: 8),
                    Text(
                      'Next Due: ${_formatDate(payment.nextDueDate)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _formatAmount(payment.monthlyInstallment),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 10),
            _buildVerificationDocumentsSection(payment.clientId),
            const SizedBox(height: 12),
            if (payment.status != 'paid') _buildActionButtons(payment),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(PaymentModel payment) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 360;

        final remindButton = OutlinedButton.icon(
          style: AppTheme.outlineButtonStyle,
          onPressed: () => _sendReminder(payment),
          icon: const Icon(Icons.notifications_active),
          label: const Text('Remind Upcoming'),
        );

        final recordButton = ElevatedButton.icon(
          style: AppTheme.primaryButtonStyle,
          onPressed: () => _showRecordPaymentDialog(payment),
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text(
            'Record Payment',
            style: TextStyle(color: Colors.white),
          ),
        );

        if (isNarrow) {
          return Column(
            children: [
              SizedBox(width: double.infinity, child: remindButton),
              const SizedBox(height: 8),
              SizedBox(width: double.infinity, child: recordButton),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: remindButton),
            const SizedBox(width: 8),
            Expanded(child: recordButton),
          ],
        );
      },
    );
  }

  Widget _buildVerificationDocumentsSection(String clientId) {
    return FutureBuilder<DocumentModel?>(
      future: _documentService.getClientDocuments(clientId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LinearProgressIndicator(minHeight: 2);
        }

        final document = snapshot.data;
        if (document == null) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'Verification documents not submitted by this client yet.',
              style: TextStyle(fontSize: 12),
            ),
          );
        }

        final docs = <MapEntry<String, String>>[];
        void addDoc(String label, String? url) {
          if (url != null && url.trim().isNotEmpty) {
            docs.add(MapEntry(label, url.trim()));
          }
        }

        addDoc('CNIC Front', document.cnicFrontUrl);
        addDoc('CNIC Back', document.cnicBackUrl);
        addDoc('Filer Document', document.filerDocumentUrl);
        addDoc(
          document.otherDocumentName?.trim().isNotEmpty == true
              ? document.otherDocumentName!.trim()
              : 'Other Document',
          document.otherDocumentUrl,
        );

        for (var i = 0; i < document.additionalDocuments.length; i++) {
          final value = document.additionalDocuments[i].trim();
          if (value.isNotEmpty) {
            docs.add(MapEntry('Additional ${i + 1}', value));
          }
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Verification Documents',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _documentStatusColor(
                        document.status,
                      ).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      document.status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: _documentStatusColor(document.status),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (docs.isEmpty)
                const Text(
                  'No file URLs found in verification record.',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                )
              else
                ...docs.map((doc) => _buildDocumentRow(doc.key, doc.value)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInstallmentBreakdownStrip(PaymentModel payment) {
    final pendingInstallments = _pendingInstallments(payment);
    final upcomingInstallments = _upcomingInstallments(payment);

    Widget item({
      required String label,
      required String value,
      required Color color,
      required IconData icon,
    }) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: color,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
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
              label: 'Paid',
              value: '${payment.paidInstallments}',
              color: Colors.green,
              icon: Icons.check_circle,
            ),
            const SizedBox(width: 8),
            item(
              label: 'Pending',
              value: '$pendingInstallments',
              color: AppTheme.royalBlue,
              icon: Icons.schedule,
            ),
            const SizedBox(width: 8),
            item(
              label: 'Upcoming',
              value: '$upcomingInstallments',
              color: Colors.orange,
              icon: Icons.upcoming,
            ),
          ],
        ),
        const SizedBox(height: 10),
        _buildAdminInstallmentStepper(payment),
      ],
    );
  }

  Widget _buildAdminInstallmentStepper(PaymentModel payment) {
    final total = payment.totalInstallments <= 0
        ? 1
        : payment.totalInstallments;
    final pendingNumber = payment.status == 'paid'
        ? 0
        : (payment.paidInstallments + 1).clamp(1, total);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(total, (index) {
          final number = index + 1;
          final isPaid = number <= payment.paidInstallments;
          final isPending = pendingNumber > 0 && number == pendingNumber;
          final color = isPaid
              ? Colors.green
              : isPending
              ? AppTheme.royalBlue
              : Colors.grey;

          return Row(
            children: [
              Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 260),
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withValues(
                        alpha: isPaid || isPending ? 0.18 : 0.1,
                      ),
                      border: Border.all(color: color, width: 1.3),
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
                        : isPending
                        ? 'Pending'
                        : 'Upcoming',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ],
              ),
              if (number < total)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 260),
                  width: 18,
                  height: 2,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
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

  Widget _buildDocumentRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          TextButton.icon(
            onPressed: () => _openDocumentProof(label, value),
            icon: const Icon(Icons.visibility_outlined, size: 16),
            label: const Text('View'),
          ),
        ],
      ),
    );
  }

  Color _documentStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
      case 'verified':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  void _openDocumentProof(String title, String value) {
    final looksLikeUrl =
        value.startsWith('http://') || value.startsWith('https://');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: 320,
          child: looksLikeUrl
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        value,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) {
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Preview unavailable for this file type. Use Copy URL for proof reference.',
                              style: TextStyle(fontSize: 12),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    SelectableText(
                      value,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                )
              : SelectableText(value),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: value));
              if (!mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Document reference copied.')),
              );
            },
            child: const Text('Copy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;

    switch (status) {
      case 'paid':
        color = Colors.green;
        label = 'Paid';
        break;
      case 'partial':
        color = Colors.blue;
        label = 'Partial';
        break;
      default:
        color = Colors.orange;
        label = 'Unpaid';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildAdminInstallmentStatusRow(PaymentModel payment) {
    final now = DateTime.now();
    final total = payment.totalInstallments <= 0
        ? 1
        : payment.totalInstallments;
    final paid = payment.paidInstallments.clamp(0, total);
    final remaining = (total - paid).clamp(0, total);

    late final String label;
    late final Color color;

    if (paid == 0) {
      label = 'Not Started';
      color = Colors.red;
    } else if (remaining == 0 || payment.status == 'paid') {
      label = 'Completed';
      color = Colors.green;
    } else if (payment.nextDueDate != null &&
        payment.nextDueDate!.isAfter(now)) {
      label = 'Upcoming';
      color = Colors.orange;
    } else {
      label = 'In Progress';
      color = Colors.blue;
    }

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ),
        const Spacer(),
        Text(
          'Paid: $paid  Remaining: $remaining',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black54,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildAdminPredictionCard(
    PaymentModel payment,
    int remainingInstallments,
  ) {
    final nextDueDate =
        payment.nextDueDate ??
        (payment.installmentHistory.isNotEmpty
            ? DateTime(
                payment.installmentHistory.last.paidDate.year,
                payment.installmentHistory.last.paidDate.month + 1,
                payment.installmentHistory.last.paidDate.day,
              )
            : DateTime.now());

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Prediction',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Next due date: ${_formatDate(nextDueDate)}\n'
            'Remaining installments: $remainingInstallments',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
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
    } else {
      return 'PKR ${amount.toStringAsFixed(0)}';
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _sendReminder(PaymentModel payment) async {
    final pendingInstallments = _pendingInstallments(payment);
    final upcomingInstallments = _upcomingInstallments(payment);
    final message =
        'Dear ${payment.clientName}, this is a reminder for your pending installment ($pendingInstallments) and upcoming installments ($upcomingInstallments) for ${payment.plotDetails}. Next due amount is ${_formatAmount(payment.monthlyInstallment)} on ${_formatDate(payment.nextDueDate)}. Please pay on time.';

    final status = await _paymentService.sendPaymentReminderWithStatus(
      payment.id,
      message,
    );

    if (!mounted) return;

    final success = status == 'sent' || status == 'in_app';
    final isDuplicate = status == 'duplicate';
    final snackText = isDuplicate
        ? 'Reminder already sent today for this installment.'
        : success
        ? 'Reminder sent to ${payment.clientName}'
        : 'Could not send reminder. Please try again.';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(snackText),
        backgroundColor: (success || isDuplicate)
            ? AppTheme.successColor
            : AppTheme.errorColor,
      ),
    );
  }

  int _pendingInstallments(PaymentModel payment) {
    if (payment.status == 'paid') return 0;
    if (payment.paidInstallments >= payment.totalInstallments) return 0;
    return 1;
  }

  int _upcomingInstallments(PaymentModel payment) {
    final pending = _pendingInstallments(payment);
    return (payment.totalInstallments - payment.paidInstallments - pending)
        .clamp(0, payment.totalInstallments);
  }

  Future<void> _sendBulkReminders() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Send Bulk Reminders'),
        content: const Text(
          'This will send payment reminders to all clients with upcoming installment due dates. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: AppTheme.primaryButtonStyle,
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Send All',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final count = await _paymentService.sendBulkPaymentReminders();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sent $count payment reminders'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    }
  }

  void _showRecordPaymentDialog(PaymentModel payment) {
    final amountController = TextEditingController(
      text: payment.monthlyInstallment.toString(),
    );
    final receiptController = TextEditingController();
    String paymentMethod = 'Bank Transfer';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              20,
              20,
              MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Record Payment',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                Text(
                  'Client: ${payment.clientName}',
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: AppTheme.inputDecoration(
                    hint: 'Enter amount',
                    label: 'Amount (PKR)',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: paymentMethod,
                  decoration: AppTheme.inputDecoration(
                    hint: 'Select method',
                    label: 'Payment Method',
                  ),
                  items: ['Bank Transfer', 'Cash', 'Cheque', 'Online']
                      .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                      .toList(),
                  onChanged: (v) => setModalState(() => paymentMethod = v!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: receiptController,
                  decoration: AppTheme.inputDecoration(
                    hint: 'Enter receipt number',
                    label: 'Receipt Number (Optional)',
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: AppTheme.primaryButtonStyle,
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final amount =
                          double.tryParse(amountController.text) ?? 0;
                      if (amount <= 0) {
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('Please enter a valid amount'),
                          ),
                        );
                        return;
                      }

                      Navigator.pop(ctx);

                      final installment = InstallmentRecord(
                        installmentNumber: payment.paidInstallments + 1,
                        amount: amount,
                        paidDate: DateTime.now(),
                        paymentMethod: paymentMethod,
                        receiptNumber: receiptController.text.isNotEmpty
                            ? receiptController.text
                            : null,
                      );

                      await _paymentService.recordInstallment(
                        payment.id,
                        installment,
                      );

                      if (!mounted) return;
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('Payment recorded successfully'),
                          backgroundColor: AppTheme.successColor,
                        ),
                      );
                    },
                    child: const Text(
                      'Record Payment',
                      style: AppTheme.buttonText,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
