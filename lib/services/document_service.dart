import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

import '../models/document_model.dart';
import '../models/notification_model.dart';
import '../models/challan_model.dart';
import '../models/user_model.dart';
import '../models/plot_model.dart';
import '../models/installment_model.dart';
import '../core/constants/app_constants.dart';
import 'challan_pdf_service.dart';

/// Service for document verification management
class DocumentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final String _collection = 'documents';
  final String _notificationCollection = 'notifications';
  final String _usersCollection = 'users';

  /// Get all documents
  Stream<List<DocumentModel>> getAllDocuments() {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => DocumentModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  /// Get documents by status
  Stream<List<DocumentModel>> getDocumentsByStatus(String status) {
    if (status == AppConstants.documentApproved ||
        status == AppConstants.documentVerified) {
      return _firestore
          .collection(_collection)
          .where(
            'status',
            whereIn: [
              AppConstants.documentApproved,
              AppConstants.documentVerified,
            ],
          )
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => DocumentModel.fromMap(doc.data(), doc.id))
                .toList(),
          );
    }

    return _firestore
        .collection(_collection)
        .where('status', isEqualTo: status)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => DocumentModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  /// Get client's documents
  Future<DocumentModel?> getClientDocuments(String clientId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('clientId', isEqualTo: clientId)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return DocumentModel.fromMap(
          snapshot.docs.first.data(),
          snapshot.docs.first.id,
        );
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Alias for single client document stream
  Stream<DocumentModel?> getClientDocumentStream(String clientId) {
    return _firestore
        .collection(_collection)
        .where('clientId', isEqualTo: clientId)
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return null;
          final doc = snapshot.docs.first;
          return DocumentModel.fromMap(doc.data(), doc.id);
        });
  }

  /// Submit documents for verification
  Future<bool> submitDocuments(DocumentModel document) async {
    try {
      // Check if documents already exist for this client
      final existingDoc = await getClientDocuments(document.clientId);

      if (existingDoc != null) {
        // Update existing document
        await _firestore.collection(_collection).doc(existingDoc.id).update({
          ...document.toMap(),
          'status': AppConstants.documentPending,
          'timestamp': FieldValue.serverTimestamp(),
        });
      } else {
        // Add new document
        await _firestore.collection(_collection).add({
          ...document.toMap(),
          'status': AppConstants.documentPending,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Aliases for UI compatibility
  Stream<DocumentModel?> getClientDocument(String clientId) {
    return getClientDocumentStream(clientId);
  }

  Future<bool> submitDocument(DocumentModel document) {
    return submitDocuments(document);
  }

  Future<bool> updateDocument(
    String documentId, {
    String? cnic,
    bool? isFiler,
    String? filerStatus,
    String? ntnNumber,
  }) async {
    try {
      await _firestore.collection(_collection).doc(documentId).update({
        if (cnic != null) 'cnic': cnic,
        if (isFiler != null) 'isFiler': isFiler,
        if (filerStatus != null) 'filerStatus': filerStatus,
        if (ntnNumber != null) 'ntnNumber': ntnNumber,
        'status': AppConstants.documentPending,
        'submittedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> verifyDocument(String documentId, {String? verifiedBy}) {
    return verifyDocuments(documentId, verifiedBy ?? 'Admin');
  }

  Future<bool> rejectDocument(String documentId, String reason) {
    return rejectDocuments(documentId, reason);
  }

  /// Verify documents
  Future<bool> verifyDocuments(String documentId, String verifiedBy) async {
    try {
      await _firestore.collection(_collection).doc(documentId).update({
        'status': AppConstants.documentApproved,
        'verifiedBy': verifiedBy,
        'verifiedAt': FieldValue.serverTimestamp(),
      });

      // Get document details for notification
      final docSnapshot = await _firestore
          .collection(_collection)
          .doc(documentId)
          .get();
      if (docSnapshot.exists) {
        final document = DocumentModel.fromMap(
          docSnapshot.data()!,
          docSnapshot.id,
        );

        // Update user's isDocumentsVerified flag
        await _firestore
            .collection(_usersCollection)
            .doc(document.clientId)
            .update({'isDocumentsVerified': true});

        // Send notification to client
        await _sendVerificationNotification(
          document,
          'Documents Verified',
          'Congratulations! Your documents have been verified successfully. You can now proceed with plot booking.',
        );
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Reject documents
  Future<bool> rejectDocuments(String documentId, String reason) async {
    try {
      await _firestore.collection(_collection).doc(documentId).update({
        'status': AppConstants.documentRejected,
        'rejectionReason': reason,
      });

      // Get document details for notification
      final docSnapshot = await _firestore
          .collection(_collection)
          .doc(documentId)
          .get();
      if (docSnapshot.exists) {
        final document = DocumentModel.fromMap(
          docSnapshot.data()!,
          docSnapshot.id,
        );

        // Send notification to client
        await _sendVerificationNotification(
          document,
          'Documents Rejected',
          'Your documents have been rejected. Reason: $reason. Please re-upload the correct documents.',
        );
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Send verification notification
  Future<void> _sendVerificationNotification(
    DocumentModel document,
    String title,
    String message,
  ) async {
    final notification = NotificationModel(
      id: '',
      title: title,
      message: message,
      type: 'document',
      targetUserId: document.clientId,
      data: {'documentId': document.id},
    );

    await _firestore
        .collection(_notificationCollection)
        .add(notification.toMap());
  }

  /// Delete documents
  Future<bool> deleteDocuments(String documentId) async {
    try {
      await _firestore.collection(_collection).doc(documentId).delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get document counts by status
  Future<Map<String, int>> getDocumentCounts() async {
    final snapshot = await _firestore.collection(_collection).get();

    int pending = 0;
    int verified = 0;
    int rejected = 0;

    for (var doc in snapshot.docs) {
      final status = doc.data()['status'] ?? 'pending';
      switch (status) {
        case AppConstants.documentPending:
          pending++;
          break;
        case AppConstants.documentApproved:
          verified++;
          break;
        case AppConstants.documentVerified:
          verified++;
          break;
        case AppConstants.documentRejected:
          rejected++;
          break;
      }
    }

    return {
      'pending': pending,
      'verified': verified,
      'rejected': rejected,
      'total': snapshot.docs.length,
    };
  }

  /// Upload a verification document to Firebase Storage and return public URL.
  Future<String?> uploadDocumentFile({
    required String userId,
    required String documentType,
    required File file,
  }) async {
    try {
      if (!file.existsSync()) {
        return null;
      }

      final now = DateTime.now().millisecondsSinceEpoch;
      final ext = file.path.split('.').last.toLowerCase();
      final ref = _storage
          .ref()
          .child('verification_documents')
          .child(userId)
          .child('$documentType-$now.$ext');

      await ref.putFile(file);
      return ref.getDownloadURL();
    } catch (_) {
      return null;
    }
  }

  // ============= CHALLAN PDF METHODS =============

  /// Generate and download challan PDF
  Future<Map<String, dynamic>> generateAndDownloadChallan({
    required UserModel user,
    required PlotModel plot,
    required InstallmentModel installment,
    required double amount,
    String? accountNumber,
    String? bankName,
    String? accountTitle,
    String? bankId,
    String? iban,
  }) async {
    try {
      print('📦 generateAndDownloadChallan called');
      print('👤 User: ${user.username}');
      print('🏠 Plot: ${plot.society}');
      print('💰 Amount: $amount');

      // Generate PDF
      final pdfFile = await ChallanPdfService.generateChallanPdf(
        user: user,
        plot: plot,
        installment: installment,
        amount: amount,
        accountNumber: accountNumber,
        bankName: bankName ?? 'Royal Nest Bank',
        accountTitle: accountTitle ?? 'Royal Nest Properties (Pvt) Ltd',
        bankId: bankId ?? '',
        iban: iban ?? 'PK93ABCD0123456789012345',
      );

      if (pdfFile == null) {
        print('❌ PDF generation returned null');
        return {'success': false, 'message': 'Failed to generate PDF'};
      }

      print('✅ PDF file generated: ${pdfFile.path}');
      print('📊 File exists: ${await pdfFile.exists()}');
      print('📦 File size: ${await pdfFile.length()} bytes');

      // Generate challan ID
      final challanId = _generateChallanId(user.uid);
      print('🔑 Generated Challan ID: $challanId');

      // Store challan record in Firestore
      final challanRecord = ChallanModel(
        id: '',
        challanId: challanId,
        userId: user.uid,
        userName: user.username,
        userEmail: user.email,
        userCnic: user.cnic,
        userPhone: user.phone ?? '',
        propertyId: plot.id,
        propertyName: plot.society,
        plotNumber: plot.plotNumber,
        blockName: plot.blockName,
        installmentNumber:
            installment.totalInstallments - installment.upcomingInstallments,
        amount: amount,
        purpose: 'Installment Fee',
        bankName: bankName ?? 'Royal Nest Bank',
        accountNumber: accountNumber ?? '',
        bankId: bankId ?? '',
        iban: iban ?? 'PK93ABCD0123456789012345',
        status: 'downloaded',
        generatedAt: DateTime.now(),
        downloadedAt: DateTime.now(),
      );

      print('💾 Storing challan record in Firestore...');
      await _storeChallanRecord(challanRecord);
      print('✅ Challan record stored successfully');

      final result = {
        'success': true,
        'message': 'Challan downloaded successfully',
        'filePath': pdfFile.path,
        'fileName': pdfFile.path.split('/').last,
        'challanId': challanId,
      };

      print('📤 Returning success result: $result');
      return result;
    } catch (e, stackTrace) {
      print('❌ Error in generateAndDownloadChallan: $e');
      print('📍 Stack trace: $stackTrace');
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  /// Store challan record in Firestore
  Future<bool> _storeChallanRecord(ChallanModel challan) async {
    try {
      await _firestore.collection('challans').add(challan.toMap());
      return true;
    } catch (e) {
      print('Error storing challan record: $e');
      return false;
    }
  }

  /// Get challan history for user
  Stream<List<ChallanModel>> getUserChallanHistory(String userId) {
    return _firestore
        .collection('challans')
        .where('user_id', isEqualTo: userId)
        .orderBy('generated_at', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ChallanModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  /// Get latest challan for user and property
  Future<ChallanModel?> getLatestChallan(
    String userId,
    String propertyId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('challans')
          .where('user_id', isEqualTo: userId)
          .where('property_id', isEqualTo: propertyId)
          .orderBy('generated_at', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return ChallanModel.fromMap(
          snapshot.docs.first.data(),
          snapshot.docs.first.id,
        );
      }
      return null;
    } catch (e) {
      print('Error getting latest challan: $e');
      return null;
    }
  }

  /// Update challan status
  Future<bool> updateChallanStatus(
    String challanId,
    String newStatus, {
    DateTime? depositedAt,
  }) async {
    try {
      final updateData = {
        'status': newStatus,
        if (newStatus == 'deposited' && depositedAt != null)
          'deposited_at': Timestamp.fromDate(depositedAt),
      };

      await _firestore.collection('challans').doc(challanId).update(updateData);
      return true;
    } catch (e) {
      print('Error updating challan status: $e');
      return false;
    }
  }

  /// Generate unique challan ID
  String _generateChallanId(String userId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 10000).toString().padLeft(4, '0');
    final userCode = userId.length > 3
        ? userId.substring(0, 3).toUpperCase()
        : userId.toUpperCase();
    return 'CH-$userCode-$random';
  }

  /// Check if challan was generated for installment
  Future<bool> isChallanGenerated(
    String userId,
    String propertyId,
    int installmentNumber,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('challans')
          .where('user_id', isEqualTo: userId)
          .where('property_id', isEqualTo: propertyId)
          .where('installment_number', isEqualTo: installmentNumber)
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Get challan count for user
  Future<int> getUserChallanCount(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('challans')
          .where('user_id', isEqualTo: userId)
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e) {
      return 0;
    }
  }
}
