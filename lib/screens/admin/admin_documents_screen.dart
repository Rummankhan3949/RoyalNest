import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../models/document_model.dart';
import '../../services/document_service.dart';
import 'admin_drawer.dart';

/// Admin Document Verification Screen
class AdminDocumentsScreen extends StatefulWidget {
  const AdminDocumentsScreen({super.key});

  @override
  State<AdminDocumentsScreen> createState() => _AdminDocumentsScreenState();
}

class _AdminDocumentsScreenState extends State<AdminDocumentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
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
          'Document Verification',
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
            Tab(text: 'Verified'),
            Tab(text: 'Rejected'),
          ],
        ),
      ),
      drawer: const AdminDrawer(),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDocumentsList(AppConstants.documentPending),
          _buildDocumentsList(AppConstants.documentVerified),
          _buildDocumentsList(AppConstants.documentRejected),
        ],
      ),
    );
  }

  Widget _buildDocumentsList(String status) {
    return StreamBuilder<List<DocumentModel>>(
      stream: _documentService.getDocumentsByStatus(status),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final documents = snapshot.data ?? [];

        if (documents.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  status == AppConstants.documentVerified
                      ? Icons.verified_outlined
                      : Icons.description_outlined,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  status == AppConstants.documentPending
                      ? 'No pending documents'
                      : status == AppConstants.documentVerified
                      ? 'No verified documents'
                      : 'No rejected documents',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: documents.length,
          itemBuilder: (context, index) => _buildDocumentCard(documents[index]),
        );
      },
    );
  }

  Widget _buildDocumentCard(DocumentModel document) {
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
                        document.clientName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        document.email,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(document.status),
              ],
            ),
            const SizedBox(height: 16),
            _buildDocumentInfo('CNIC', document.cnic, Icons.credit_card),
            if (document.cnicFrontUrl != null ||
                document.cnicBackUrl != null) ...[
              const SizedBox(height: 12),
              const Text(
                'CNIC Images:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (document.cnicFrontUrl != null)
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _showImageDialog(
                          'CNIC Front',
                          document.cnicFrontUrl!,
                        ),
                        child: Container(
                          height: 80,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              document.cnicFrontUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Center(
                                child: Icon(Icons.image_not_supported),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (document.cnicBackUrl != null)
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _showImageDialog(
                          'CNIC Back',
                          document.cnicBackUrl!,
                        ),
                        child: Container(
                          height: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              document.cnicBackUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Center(
                                child: Icon(Icons.image_not_supported),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: document.isFilerFlag
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    document.isFilerFlag
                        ? Icons.verified
                        : Icons.info_outline,
                    size: 20,
                    color:
                        document.isFilerFlag ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    document.isFilerFlag ? 'Filer' : 'Non-Filer',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: document.isFilerFlag
                          ? Colors.green
                          : Colors.orange,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    document.filerStatus,
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          document.isFilerFlag ? Colors.green : Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
            if (document.ntnNumber != null) ...[
              const SizedBox(height: 12),
              _buildDocumentInfo(
                'NTN Number',
                document.ntnNumber!,
                Icons.numbers,
              ),
            ],
            if (document.additionalDocuments.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Additional Documents:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: document.additionalDocuments.map((doc) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.attach_file, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          doc,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
            if (document.rejectionReason != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 16,
                      color: Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        document.rejectionReason!,
                        style: const TextStyle(fontSize: 12, color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  'Submitted: ${_formatDate(document.submittedAt)}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
                const Spacer(),
                if (document.verifiedAt != null)
                  Text(
                    'Verified: ${_formatDate(document.verifiedAt)}',
                    style: const TextStyle(fontSize: 11, color: Colors.green),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (document.status == AppConstants.documentPending)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                      onPressed: () => _showRejectDialog(document),
                      child: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: AppTheme.primaryButtonStyle,
                      onPressed: () => _verifyDocument(document),
                      child: const Text(
                        'Verify',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentInfo(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;

    switch (status) {
      case AppConstants.documentPending:
        color = Colors.orange;
        label = 'Pending';
        break;
      case AppConstants.documentVerified:
        color = Colors.green;
        label = 'Verified';
        break;
      case AppConstants.documentRejected:
        color = Colors.red;
        label = 'Rejected';
        break;
      default:
        color = Colors.grey;
        label = status;
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

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showImageDialog(String title, String imageUrl) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppTheme.royalBlue,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(16),
              ),
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Container(
                  height: 200,
                  color: Colors.grey.shade200,
                  child: const Center(
                    child: Icon(Icons.image_not_supported, size: 48),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _verifyDocument(DocumentModel document) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Verify Documents'),
        content: Text(
          'Verify documents for ${document.clientName}? This will notify the client about the verification.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: AppTheme.primaryButtonStyle,
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Verify', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _documentService.verifyDocument(document.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Documents verified and client notified'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    }
  }

  void _showRejectDialog(DocumentModel document) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Reject Documents'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Reject documents for ${document.clientName}?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: AppTheme.inputDecoration(
                hint: 'Reason for rejection (required)',
                label: 'Reason',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              if (reasonController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please provide a reason')),
                );
                return;
              }
              Navigator.pop(ctx);
              await _documentService.rejectDocument(
                document.id,
                reasonController.text,
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Documents rejected and client notified'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Reject', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
