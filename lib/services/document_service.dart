import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/document_model.dart';
import '../models/notification_model.dart';
import '../core/constants/app_constants.dart';

/// Service for document verification management
class DocumentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
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
        await _firestore
            .collection(_collection)
            .doc(existingDoc.id)
            .update(document.toMap());
      } else {
        // Add new document
        await _firestore.collection(_collection).add(document.toMap());
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
        'status': AppConstants.documentVerified,
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
}
