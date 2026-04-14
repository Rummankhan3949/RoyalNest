import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';
import '../../models/document_model.dart';
import '../../models/manual_payment_model.dart';
import '../../models/payment_model.dart';
import '../../services/document_service.dart';
import '../../services/manual_payment_service.dart';
import '../../services/payment_service.dart';
import 'admin_drawer.dart';

class AdminManualPaymentsScreen extends StatefulWidget {
  const AdminManualPaymentsScreen({super.key});

  @override
  State<AdminManualPaymentsScreen> createState() =>
      _AdminManualPaymentsScreenState();
}

class _AdminManualPaymentsScreenState extends State<AdminManualPaymentsScreen>
    with SingleTickerProviderStateMixin {
  final ManualPaymentService _service = ManualPaymentService();
  final PaymentService _paymentService = PaymentService();
  final DocumentService _documentService = DocumentService();
  late final TabController _tabController;

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

  Future<void> _handleReject(ManualPaymentModel payment) async {
    final reasonController = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Payment'),
        content: TextField(
          controller: reasonController,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'Enter rejection reason'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, reasonController.text.trim()),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (reason == null || reason.isEmpty) return;

    final ok = await _service.rejectPayment(payment.id, reason);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Payment rejected.' : 'Could not reject payment.'),
      ),
    );
  }

  String _formatAmount(double amount) {
    return 'PKR ${amount.toStringAsFixed(0)}';
  }

  Widget _buildStatsBar() {
    return StreamBuilder<Map<String, dynamic>>(
      stream: _service.getManualPaymentsSummary(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(height: 86);
        }

        final stats = snapshot.data!;
        return Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Column(
            children: [
              Row(
                children: [
                  _statCard(
                    'Total',
                    '${stats['totalCount'] ?? 0}',
                    Colors.blue,
                  ),
                  _statCard(
                    'Pending',
                    '${stats['pendingCount'] ?? 0}',
                    Colors.orange,
                  ),
                  _statCard(
                    'Approved',
                    '${stats['approvedCount'] ?? 0}',
                    Colors.green,
                  ),
                  _statCard(
                    'Rejected',
                    '${stats['rejectedCount'] ?? 0}',
                    Colors.red,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _amountCard(
                      'Total Requested',
                      _formatAmount((stats['totalAmount'] ?? 0).toDouble()),
                      Colors.blue.shade50,
                      Colors.blue.shade700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _amountCard(
                      'Total Approved',
                      _formatAmount((stats['approvedAmount'] ?? 0).toDouble()),
                      Colors.green.shade50,
                      Colors.green.shade700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _amountCard(String label, String value, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: fg,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: fg,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentList(String status) {
    return StreamBuilder<List<ManualPaymentModel>>(
      stream: _service.getAllManualPayments(status: status),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final list = snapshot.data ?? [];
        if (list.isEmpty) {
          return Center(child: Text('No $status requests.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(14),
          itemCount: list.length,
          itemBuilder: (context, index) {
            final payment = list[index];
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
                    Text(
                      payment.propertyName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('User: ${payment.userName} (${payment.userEmail})'),
                    Text('Amount: PKR ${payment.amount.toStringAsFixed(0)}'),
                    Text('Method: ${payment.paymentMethod}'),
                    Text('Account Used: ${payment.accountNumberUsed}'),
                    const SizedBox(height: 10),
                    _buildInstallmentSnapshot(payment),
                    const SizedBox(height: 10),
                    InkWell(
                      onTap: () => _openScreenshot(payment.screenshotUrl),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          payment.screenshotUrl,
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildVerificationDocumentsSection(payment.userId),
                    const SizedBox(height: 12),
                    if (payment.status == ManualPaymentStatus.pending)
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final ok = await _service.approvePayment(
                                  payment.id,
                                );
                                if (!mounted) return;
                                ScaffoldMessenger.of(this.context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      ok
                                          ? 'Payment approved.'
                                          : 'Could not approve payment.',
                                    ),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                              ),
                              icon: const Icon(
                                Icons.check,
                                color: Colors.white,
                              ),
                              label: const Text(
                                'Approve',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _handleReject(payment),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white,
                              ),
                              label: const Text(
                                'Reject',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      )
                    else if (payment.status == ManualPaymentStatus.rejected &&
                        payment.rejectionReason != null)
                      Text(
                        'Reason: ${payment.rejectionReason}',
                        style: const TextStyle(color: Colors.red),
                      ),
                  ],
                ),
              ),
            );
          },
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
                      color: _statusColor(
                        document.status,
                      ).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      document.status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: _statusColor(document.status),
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

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
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

  Widget _buildInstallmentSnapshot(ManualPaymentModel manualPayment) {
    final linkedId = manualPayment.linkedPaymentId;
    if (linkedId == null || linkedId.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          manualPayment.installmentNumber != null
              ? 'Installment #${manualPayment.installmentNumber} (${manualPayment.installmentType ?? 'manual'})'
              : 'Installment plan details unavailable',
          style: const TextStyle(fontSize: 12),
        ),
      );
    }

    return FutureBuilder<PaymentModel?>(
      future: _paymentService.getPaymentById(linkedId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LinearProgressIndicator(minHeight: 2);
        }

        final payment = snapshot.data;
        if (payment == null) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'Linked installment plan not found',
              style: TextStyle(fontSize: 12),
            ),
          );
        }

        return _buildInstallmentPreviewStrip(payment);
      },
    );
  }

  Widget _buildInstallmentPreviewStrip(PaymentModel payment) {
    final current = payment.status == 'paid'
        ? payment.totalInstallments
        : (payment.paidInstallments + 1).clamp(1, payment.totalInstallments);
    final upcoming = (payment.totalInstallments - payment.paidInstallments)
        .clamp(0, payment.totalInstallments);

    Widget pill(String label, String value, Color color) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
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
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      );
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
          const Text(
            'Installment Snapshot',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              pill('Paid', '${payment.paidInstallments}', Colors.green),
              const SizedBox(width: 8),
              pill('Current', '$current', AppTheme.royalBlue),
              const SizedBox(width: 8),
              pill('Upcoming', '$upcoming', Colors.grey),
            ],
          ),
        ],
      ),
    );
  }

  void _openScreenshot(String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: InteractiveViewer(
          child: Image.network(url, fit: BoxFit.contain),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.royalBlue,
        title: const Text(
          'Manual Payment Requests',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Approved'),
            Tab(text: 'Rejected'),
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
                _buildPaymentList(ManualPaymentStatus.pending),
                _buildPaymentList(ManualPaymentStatus.approved),
                _buildPaymentList(ManualPaymentStatus.rejected),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
