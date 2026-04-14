
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../core/theme/app_theme.dart';
import '../../models/manual_payment_model.dart';
import '../../services/manual_payment_service.dart';

class ClientManualPaymentReceiptScreen extends StatelessWidget {
  final String paymentId;

  const ClientManualPaymentReceiptScreen({super.key, required this.paymentId});

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<Uint8List> _buildReceiptPdf(ManualPaymentModel payment) async {
    final doc = pw.Document();

    pw.MemoryImage? logoImage;
    try {
      final logo = await rootBundle.load('assets/royalnest_logo.png');
      logoImage = pw.MemoryImage(logo.buffer.asUint8List());
    } catch (_) {
      logoImage = null;
    }

    pw.Widget row(String label, String value) {
      return pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 8),
        child: pw.Row(
          children: [
            pw.Expanded(
              flex: 3,
              child: pw.Text(
                label,
                style: const pw.TextStyle(color: PdfColors.grey700),
              ),
            ),
            pw.Expanded(
              flex: 5,
              child: pw.Text(
                value,
                textAlign: pw.TextAlign.right,
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            ),
          ],
        ),
      );
    }

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  children: [
                    if (logoImage != null)
                      pw.Container(
                        width: 48,
                        height: 48,
                        child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                      ),
                    pw.SizedBox(width: 10),
                    pw.Expanded(
                      child: pw.Text(
                        'ROYAL NEST PAYMENT RECEIPT',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.green100,
                        borderRadius: pw.BorderRadius.circular(14),
                      ),
                      child: pw.Text(
                        'APPROVED',
                        style: pw.TextStyle(
                          color: PdfColors.green700,
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 18),
                pw.Divider(),
                pw.SizedBox(height: 12),
                row('Client Name', payment.userName),
                row('Client Email', payment.userEmail),
                row('Property', payment.propertyName),
                row('Property ID', payment.propertyId),
                row('Payment Method', payment.paymentMethod),
                row('Amount', 'PKR ${payment.amount.toStringAsFixed(0)}'),
                row('Date', _formatDate(payment.createdAt)),
                row('Receipt Ref', payment.id),
                pw.Spacer(),
                pw.Center(
                  child: pw.Text(
                    'Royal Nest - Premium Real Estate',
                    style: const pw.TextStyle(color: PdfColors.grey700),
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

  Future<void> _shareReceipt(ManualPaymentModel payment) async {
    final bytes = await _buildReceiptPdf(payment);
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'royalnest_receipt_${payment.id}.pdf',
    );
  }

  Future<void> _printReceipt(ManualPaymentModel payment) async {
    final bytes = await _buildReceiptPdf(payment);
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  @override
  Widget build(BuildContext context) {
    final service = ManualPaymentService();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        backgroundColor: AppTheme.royalBlue,
        title: const Text(
          'Approved Receipt',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<ManualPaymentModel?>(
        stream: service.getPaymentById(paymentId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final payment = snapshot.data;
          if (payment == null) {
            return const Center(child: Text('Receipt not found.'));
          }

          if (payment.status != ManualPaymentStatus.approved) {
            return const Center(
              child: Text('Receipt is available after approval only.'),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.lightBlue,
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/royalnest_logo.png',
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.home_work,
                                color: AppTheme.royalBlue,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'ROYAL NEST\nPAYMENT RECEIPT',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'APPROVED',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 14),
                    _row('Client Name', payment.userName),
                    _row('Client Email', payment.userEmail),
                    _row('Property', payment.propertyName),
                    _row('Property ID', payment.propertyId),
                    _row('Payment Method', payment.paymentMethod),
                    _row('Amount', 'PKR ${payment.amount.toStringAsFixed(0)}'),
                    _row('Date', _formatDate(payment.createdAt)),
                    _row('Receipt Ref', payment.id),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _printReceipt(payment),
                            icon: const Icon(Icons.download_outlined),
                            label: const Text('Download / Print'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _shareReceipt(payment),
                            style: AppTheme.primaryButtonStyle,
                            icon: const Icon(
                              Icons.share_outlined,
                              color: Colors.white,
                            ),
                            label: const Text(
                              'Share Receipt',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
