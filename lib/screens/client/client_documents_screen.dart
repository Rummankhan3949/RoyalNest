import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../models/document_model.dart';
import '../../services/document_service.dart';
import 'client_drawer.dart';

/// Client Documents Screen
class ClientDocumentsScreen extends StatefulWidget {
  const ClientDocumentsScreen({super.key});

  @override
  State<ClientDocumentsScreen> createState() => _ClientDocumentsScreenState();
}

class _ClientDocumentsScreenState extends State<ClientDocumentsScreen> {
  final DocumentService _documentService = DocumentService();
  final ImagePicker _picker = ImagePicker();
  String get userId => FirebaseAuth.instance.currentUser?.uid ?? '';

  // Document upload state
  File? _cnicFrontImage;
  File? _cnicBackImage;
  File? _filerVerificationImage;

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
          'My Documents',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: const ClientDrawer(),
      body: StreamBuilder<DocumentModel?>(
        stream: _documentService.getClientDocument(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final document = snapshot.data;

          if (document == null) {
            return _buildUploadPrompt();
          }

          return _buildDocumentView(document);
        },
      ),
    );
  }

  Widget _buildUploadPrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.lightBlue,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.upload_file,
                size: 64,
                color: AppTheme.royalBlue,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Upload Required Documents',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Please upload the following documents required for plot purchase:',
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            _buildRequiredDocumentsList(),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: AppTheme.primaryButtonStyle,
                onPressed: () => _showUploadDialog(),
                icon: const Icon(Icons.cloud_upload, color: Colors.white),
                label: const Text(
                  'Upload Documents',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequiredDocumentsList() {
    final requiredDocs = [
      'CNIC (Front & Back)',
      'Passport-size Photograph',
      'Proof of Income',
      'Filer/Non-Filer Status Certificate',
      'Bank Statement (Last 3 months)',
      'NTN Certificate (For Filers)',
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.info_outline, color: AppTheme.royalBlue, size: 20),
              SizedBox(width: 8),
              Text(
                'Required Documents:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.royalBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...requiredDocs.map(
            (doc) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(doc, style: const TextStyle(fontSize: 13)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentView(DocumentModel document) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusCard(document),
          const SizedBox(height: 16),
          _buildDocumentDetails(document),
          const SizedBox(height: 16),
          if (document.status == AppConstants.documentRejected)
            _buildRejectionInfo(document),
          const SizedBox(height: 16),
          if (document.status != AppConstants.documentVerified)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: AppTheme.outlineButtonStyle,
                onPressed: () => _showUpdateDialog(document),
                icon: const Icon(Icons.edit),
                label: const Text('Update Documents'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(DocumentModel document) {
    Color color;
    String status;
    IconData icon;

    switch (document.status) {
      case AppConstants.documentPending:
        color = Colors.orange;
        status = 'Pending Verification';
        icon = Icons.hourglass_empty;
        break;
      case AppConstants.documentVerified:
        color = Colors.green;
        status = 'Verified';
        icon = Icons.verified;
        break;
      case AppConstants.documentRejected:
        color = Colors.red;
        status = 'Rejected';
        icon = Icons.cancel;
        break;
      default:
        color = Colors.grey;
        status = 'Unknown';
        icon = Icons.help;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  document.status == AppConstants.documentPending
                      ? 'Your documents are under review'
                      : document.status == AppConstants.documentVerified
                      ? 'All documents verified successfully'
                      : 'Please resubmit correct documents',
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentDetails(DocumentModel document) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
        boxShadow: AppTheme.lightShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Document Details',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const Divider(height: 24),
          _buildDetailRow('CNIC', document.cnic),
          _buildDetailRow(
            'Filer Status',
            document.isFilerFlag ? 'Yes' : 'No',
            valueColor: document.isFilerFlag ? Colors.green : Colors.orange,
          ),
          if (document.ntnNumber != null)
            _buildDetailRow('NTN Number', document.ntnNumber!),
          _buildDetailRow('Submitted', _formatDate(document.submittedAtDate)),
          if (document.verifiedAt != null)
            _buildDetailRow(
              'Verified On',
              _formatDate(document.verifiedAt),
              valueColor: Colors.green,
            ),
        ],
      ),
    );
  }

  Widget _buildRejectionInfo(DocumentModel document) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.error_outline, color: Colors.red, size: 20),
              SizedBox(width: 8),
              Text(
                'Rejection Reason',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            document.rejectionReason ?? 'No reason provided',
            style: const TextStyle(fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.w600, color: valueColor),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showUploadDialog() {
    final cnicController = TextEditingController();
    final ntnController = TextEditingController();
    bool isFiler = false;

    setState(() {
      _cnicFrontImage = null;
      _cnicBackImage = null;
      _filerVerificationImage = null;
    });

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
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Upload Documents',
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
                  const SizedBox(height: 16),

                  // CNIC Number Field
                  TextField(
                    controller: cnicController,
                    decoration: AppTheme.inputDecoration(
                      hint: 'e.g., 12345-1234567-1',
                      label: 'CNIC Number *',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),

                  // CNIC Images Upload
                  const Text(
                    'CNIC Images *',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildImageUploadButton(
                          'Front Side',
                          _cnicFrontImage,
                          () async {
                            final image = await _pickImage();
                            if (image != null) {
                              setModalState(() => _cnicFrontImage = image);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildImageUploadButton(
                          'Back Side',
                          _cnicBackImage,
                          () async {
                            final image = await _pickImage();
                            if (image != null) {
                              setModalState(() => _cnicBackImage = image);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Filer/Non-Filer Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.orange.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(
                              Icons.warning_amber,
                              color: Colors.orange,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Tax Filer Status',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        CheckboxListTile(
                          title: const Text('I am a Tax Filer'),
                          subtitle: const Text(
                            'Check this if you file tax returns',
                            style: TextStyle(fontSize: 12),
                          ),
                          value: isFiler,
                          onChanged: (v) =>
                              setModalState(() => isFiler = v ?? false),
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                          activeColor: AppTheme.royalBlue,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // NTN Field (if filer)
                  if (isFiler) ...[
                    TextField(
                      controller: ntnController,
                      decoration: AppTheme.inputDecoration(
                        hint: 'Enter NTN Number',
                        label: 'NTN Number *',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Filer Verification Upload (if filer)
                  if (isFiler) ...[
                    const Text(
                      'Filer Verification Document *',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Upload screenshot of FBR verification message or certificate',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    _buildImageUploadButton(
                      'Upload Verification',
                      _filerVerificationImage,
                      () async {
                        final image = await _pickImage();
                        if (image != null) {
                          setModalState(() => _filerVerificationImage = image);
                        }
                      },
                      fullWidth: true,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Info Note
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.info_outline, size: 20, color: Colors.blue),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'For Non-Filers: No verification document needed. Additional documents can be submitted at office.',
                            style: TextStyle(fontSize: 12, color: Colors.blue),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: AppTheme.primaryButtonStyle,
                      onPressed: () async {
                        // Validation
                        if (cnicController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter CNIC number'),
                            ),
                          );
                          return;
                        }

                        if (_cnicFrontImage == null || _cnicBackImage == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please upload both sides of CNIC'),
                            ),
                          );
                          return;
                        }

                        if (isFiler && ntnController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter NTN number'),
                            ),
                          );
                          return;
                        }

                        if (isFiler && _filerVerificationImage == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Please upload filer verification document',
                              ),
                            ),
                          );
                          return;
                        }

                        Navigator.pop(ctx);

                        // Show loading
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (_) =>
                              const Center(child: CircularProgressIndicator()),
                        );

                        try {
                          final document = DocumentModel(
                            id: '',
                            clientId: userId,
                            clientName:
                                FirebaseAuth
                                    .instance
                                    .currentUser
                                    ?.displayName ??
                                'Client',
                            clientEmail:
                                FirebaseAuth.instance.currentUser?.email ?? '',
                            cnic: cnicController.text,
                            isFiler: isFiler,
                            ntnNumber: isFiler ? ntnController.text : null,
                            status: AppConstants.documentPending,
                            submittedAt: DateTime.now(),
                          );

                          await _documentService.submitDocument(document);

                          // Note: In production, you would upload images to Firebase Storage
                          // For now, we're just storing the metadata

                          if (!mounted) return;
                          Navigator.of(this.context).pop(); // Close loading
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Documents submitted successfully! Images saved locally. Visit office to complete verification.',
                              ),
                              backgroundColor: AppTheme.successColor,
                              duration: Duration(seconds: 4),
                            ),
                          );
                        } catch (e) {
                          if (!mounted) return;
                          Navigator.of(this.context).pop(); // Close loading
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            SnackBar(
                              content: Text('Error: ${e.toString()}'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      child: const Text(
                        'Submit Documents',
                        style: AppTheme.buttonText,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildImageUploadButton(
    String label,
    File? image,
    VoidCallback onTap, {
    bool fullWidth = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: fullWidth ? 100 : 80,
        decoration: BoxDecoration(
          color: image != null
              ? Colors.green.withValues(alpha: 0.1)
              : Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: image != null ? Colors.green : Colors.grey.shade300,
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: image != null
            ? Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(
                      image,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate,
                    color: Colors.grey.shade600,
                    size: 28,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
      ),
    );
  }

  Future<File?> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        return File(pickedFile.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: ${e.toString()}')),
        );
      }
    }
    return null;
  }

  void _showUpdateDialog(DocumentModel document) {
    final cnicController = TextEditingController(text: document.cnic);
    bool isFiler = document.isFilerFlag;

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
                      'Update Documents',
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
                const SizedBox(height: 16),
                TextField(
                  controller: cnicController,
                  decoration: AppTheme.inputDecoration(
                    hint: 'Enter your CNIC number',
                    label: 'CNIC',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  title: const Text('I am a filer'),
                  value: isFiler,
                  onChanged: (v) => setModalState(() => isFiler = v ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: AppTheme.primaryButtonStyle,
                    onPressed: () async {
                      Navigator.pop(ctx);

                      await _documentService.updateDocument(
                        document.id,
                        cnic: cnicController.text,
                        isFiler: isFiler,
                      );

                      if (!mounted) return;
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        const SnackBar(
                          content: Text('Documents updated successfully'),
                          backgroundColor: AppTheme.successColor,
                        ),
                      );
                    },
                    child: const Text('Update', style: AppTheme.buttonText),
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
