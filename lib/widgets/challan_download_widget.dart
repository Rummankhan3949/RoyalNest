import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/plot_model.dart';
import '../models/installment_model.dart';
import '../services/document_service.dart';
import 'package:open_file/open_file.dart';

/// Widget for downloading bank challan PDF
class ChallanDownloadWidget extends StatefulWidget {
  final UserModel user;
  final PlotModel plot;
  final InstallmentModel installment;
  final double amount;
  final String? accountNumber;
  final String? bankName;
  final String? accountTitle;
  final String? bankId;
  final String? iban;
  final VoidCallback? onSuccess;
  final Function(String)? onError;

  const ChallanDownloadWidget({
    Key? key,
    required this.user,
    required this.plot,
    required this.installment,
    required this.amount,
    this.accountNumber,
    this.bankName,
    this.accountTitle,
    this.bankId,
    this.iban,
    this.onSuccess,
    this.onError,
  }) : super(key: key);

  @override
  State<ChallanDownloadWidget> createState() => _ChallanDownloadWidgetState();
}

class _ChallanDownloadWidgetState extends State<ChallanDownloadWidget> {
  final DocumentService _documentService = DocumentService();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _resetMessages();
    super.dispose();
  }

  void _resetMessages() {
    _errorMessage = null;
  }

  Future<void> _downloadChallan() async {
    setState(() {
      _isLoading = true;
      _resetMessages();
    });

    try {
      print('🔄 Starting challan download...');

      final result = await _documentService.generateAndDownloadChallan(
        user: widget.user,
        plot: widget.plot,
        installment: widget.installment,
        amount: widget.amount,
        accountNumber: widget.accountNumber,
        bankName: widget.bankName,
        accountTitle: widget.accountTitle,
        bankId: widget.bankId,
        iban: widget.iban,
      );

      print('📋 Result: $result');

      if (!mounted) return;

      if (result['success']) {
        final filePath = result['filePath'] as String;
        final fileName = result['fileName'] as String;

        print('✅ PDF generated: $fileName');
        print('📁 File path: $filePath');

        // Try to open the PDF file
        try {
          print('📂 Attempting to open file...');
          final openResult = await OpenFile.open(filePath);
          print('📖 Open result: ${openResult.message}');
        } catch (e) {
          print('⚠️ Could not open file: $e');
        }

        setState(() => _isLoading = false);

        widget.onSuccess?.call();

        // Show success snackbar with longer duration
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '✅ Challan Downloaded Successfully!',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '📥 Location: Downloads/$fileName',
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Check your gallery or file manager to view',
                    style: TextStyle(fontSize: 11),
                  ),
                ],
              ),
              backgroundColor: Colors.green.shade700,
              duration: const Duration(seconds: 6),
            ),
          );
        }
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Failed to download challan';
          _isLoading = false;
        });

        print('❌ Error: $_errorMessage');
        widget.onError?.call(_errorMessage!);

        // Show error snackbar
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_errorMessage!),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
        _isLoading = false;
      });

      print('❌ Exception: $e');
      print('📍 Stack trace: $stackTrace');

      widget.onError?.call(_errorMessage!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage!),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Info Box
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            border: Border.all(color: Colors.blue.shade200),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bank Challan Details',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
              const SizedBox(height: 8),
              _buildChallanInfoRow(
                'Installment',
                '${widget.installment.totalInstallments - widget.installment.upcomingInstallments} of ${widget.installment.totalInstallments}',
              ),
              _buildChallanInfoRow(
                'Amount',
                'PKR ${widget.amount.toStringAsFixed(0)}',
              ),
              _buildChallanInfoRow('Purpose', 'Installment Fee'),
              _buildChallanInfoRow(
                'Bank',
                widget.bankName ?? 'Royal Nest Bank',
              ),
              _buildChallanInfoRow('Bank ID', widget.bankId ?? 'N/A'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Download Button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _downloadChallan,
            icon: _isLoading
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).primaryColor,
                      ),
                    ),
                  )
                : const Icon(Icons.download),
            label: Text(
              _isLoading ? 'Generating Challan...' : 'Download Challan PDF',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        // Instructions
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.amber.shade50,
            border: Border.all(color: Colors.amber.shade200),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '📋 How to Use',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.amber.shade700,
                ),
              ),
              const SizedBox(height: 8),
              _buildInstructionItem('1. Download the challan PDF'),
              _buildInstructionItem('2. Print the challan (triple copy)'),
              _buildInstructionItem('3. Deposit at any bank branch'),
              _buildInstructionItem('4. Keep receipt for your records'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChallanInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: Colors.black54),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          color: Colors.black87,
          height: 1.5,
        ),
      ),
    );
  }
}

/// Widget for displaying challan history
class ChallanHistoryWidget extends StatelessWidget {
  final String userId;
  final DocumentService documentService;

  const ChallanHistoryWidget({
    Key? key,
    required this.userId,
    required this.documentService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: documentService.getUserChallanHistory(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final challans = snapshot.data ?? [];

        if (challans.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No Challans Generated',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Download your first challan to get started',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: challans.length,
          itemBuilder: (context, index) {
            final challan = challans[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                leading: Icon(
                  Icons.receipt,
                  color: _getStatusColor(challan.status),
                ),
                title: Text('Challan #${challan.challanId}'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Amount: PKR ${challan.amount.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    Text(
                      'Status: ${challan.status.toUpperCase()}',
                      style: TextStyle(
                        fontSize: 12,
                        color: _getStatusColor(challan.status),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                trailing: _buildStatusBadge(challan.status),
              ),
            );
          },
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'downloaded':
        return Colors.blue;
      case 'deposited':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Widget _buildStatusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: _getStatusColor(status),
        ),
      ),
    );
  }
}
