import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:http/http.dart' as http;

import '../core/constants/app_constants.dart';
import '../models/claim_model.dart';
import '../models/lost_found_model.dart';
import '../models/notification_model.dart';
import 'notification_service.dart';

/// Service for lost and found items management
class LostFoundService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final String _collection = 'lost_found';
  final String _claimsCollection = 'claims';

  /// Get all items
  Stream<List<LostFoundModel>> getAllItems() {
    return _firestore
        .collection(_collection)
        .orderBy('reportedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => LostFoundModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Stream<List<ClaimModel>> getClaimRequestsForOwner(String ownerUserId) {
    return _firestore
        .collection(_claimsCollection)
        .where('ownerUserId', isEqualTo: ownerUserId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ClaimModel.fromMap(doc.data(), doc.id))
              .where((claim) => claim.status == AppConstants.claimPending)
              .toList(),
        );
  }

  Stream<List<ClaimModel>> getAllClaimRequests({bool pendingOnly = true}) {
    return _firestore
        .collection(_claimsCollection)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ClaimModel.fromMap(doc.data(), doc.id))
              .where(
                (claim) =>
                    !pendingOnly || claim.status == AppConstants.claimPending,
              )
              .toList(),
        );
  }

  /// Get items by type (lost/found)
  Stream<List<LostFoundModel>> getItemsByType(String type) {
    return _firestore
        .collection(_collection)
        .where('type', isEqualTo: type)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => LostFoundModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  /// Get items by status
  Stream<List<LostFoundModel>> getItemsByStatus(String status) {
    return _firestore
        .collection(_collection)
        .where('status', isEqualTo: status)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => LostFoundModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Stream<List<LostFoundModel>> getItemsByLifecycleStatus(String status) {
    return _firestore
        .collection(_collection)
        .where('status', isEqualTo: status)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => LostFoundModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  /// Get items by society
  Stream<List<LostFoundModel>> getItemsBySociety(String society) {
    return _firestore
        .collection(_collection)
        .where('society', isEqualTo: society)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => LostFoundModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  /// Get items reported by specific user
  Stream<List<LostFoundModel>> getMyReports(String userId) {
    return _firestore
        .collection(_collection)
        .where('reportedById', isEqualTo: userId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => LostFoundModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  /// Report new item
  Future<bool> reportItem(LostFoundModel item) async {
    try {
      await _firestore.collection(_collection).add({
        ...item.toMap(),
        'status': AppConstants.itemActive,
        'hasClaimRequest': false,
        'claimedBy': null,
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Update item status
  Future<bool> updateItemStatus(String itemId, String status) async {
    try {
      final updateData = <String, dynamic>{'status': status};

      if (status == AppConstants.itemClaimed) {
        updateData['claimedAt'] = FieldValue.serverTimestamp();
      } else if (status == AppConstants.itemResolved ||
          status == AppConstants.itemReturned) {
        updateData['returnedAt'] = FieldValue.serverTimestamp();
      }

      await _firestore.collection(_collection).doc(itemId).update(updateData);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Mark item as claimed
  Future<bool> markAsClaimed(
    String itemId,
    String claimedBy,
    String contact,
  ) async {
    try {
      await _firestore.collection(_collection).doc(itemId).update({
        'status': AppConstants.itemClaimed,
        'claimedBy': claimedBy,
        'claimerContact': contact,
        'claimedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Mark item as returned
  Future<bool> markAsReturned(String itemId) async {
    try {
      await _firestore.collection(_collection).doc(itemId).update({
        'status': AppConstants.itemResolved,
        'returnedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Update item
  Future<bool> updateItem(LostFoundModel item) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(item.id)
          .update(item.toMap());
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Delete item
  Future<bool> deleteItem(String itemId) async {
    try {
      await _firestore.collection(_collection).doc(itemId).delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<String?> uploadClaimProofImage({
    required File file,
    required String userId,
    required String itemId,
  }) async {
    if (!file.existsSync()) return null;

    final cloudName = AppConstants.cloudinaryCloudName.trim();
    final uploadPreset = AppConstants.cloudinaryUploadPreset.trim();
    if (cloudName.isEmpty || uploadPreset.isEmpty) return null;

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
    );
    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = uploadPreset
      ..fields['folder'] = 'lost_found_claims/$userId/$itemId'
      ..fields['public_id'] = '${userId}_${itemId}_$timestamp'
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final response = await request.send();
    final body = await response.stream.bytesToString();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return null;
    }
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      return json['secure_url']?.toString();
    } catch (_) {
      return null;
    }
  }

  Future<String?> createClaim({
    required LostFoundModel item,
    required String claimantUserId,
    required String claimantName,
    required String proofText,
    String? proofImageUrl,
    bool allowMultipleClaims = true,
  }) async {
    if (item.reportedById == claimantUserId) {
      throw StateError('You cannot claim your own item.');
    }
    if (item.lifecycleStatus != AppConstants.itemActive) {
      throw StateError('This item is no longer available for claiming.');
    }

    bool hasDuplicate = false;
    try {
      final duplicateClaimQuery = await _firestore
          .collection(_claimsCollection)
          .where('itemId', isEqualTo: item.id)
          .get();
      hasDuplicate = duplicateClaimQuery.docs.any(
        (doc) => (doc.data()['claimantUserId'] ?? '') == claimantUserId,
      );
    } on FirebaseException catch (e) {
      if (e.code != 'permission-denied') {
        rethrow;
      }
    }
    if (hasDuplicate) {
      throw StateError('You have already submitted a claim for this item.');
    }

    if (!allowMultipleClaims) {
      try {
        final anyClaimQuery = await _firestore
            .collection(_claimsCollection)
            .where('itemId', isEqualTo: item.id)
            .get();
        final hasPending = anyClaimQuery.docs.any(
          (doc) => (doc.data()['status'] ?? '') == AppConstants.claimPending,
        );
        if (hasPending) {
          throw StateError('An active claim already exists for this item.');
        }
      } on FirebaseException catch (e) {
        if (e.code != 'permission-denied') {
          rethrow;
        }
      }
    }

    final claimRef = _firestore.collection(_claimsCollection).doc();
    final itemRef = _firestore.collection(_collection).doc(item.id);
    final claim = ClaimModel(
      id: claimRef.id,
      itemId: item.id,
      claimantUserId: claimantUserId,
      claimantName: claimantName,
      ownerUserId: item.reportedById,
      proofText: proofText,
      proofImageUrl: proofImageUrl,
      status: AppConstants.claimPending,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await claimRef.set(claim.toMap());

    try {
      await itemRef.update({'hasClaimRequest': true});
    } on FirebaseException catch (e) {
      if (e.code != 'permission-denied') {
        rethrow;
      }
    }

    await _notificationService.sendNotification(
      NotificationModel(
        id: '',
        title: 'New Claim Request',
        message: 'Someone wants to claim your item',
        type: 'lost_found_claim',
        targetUserId: item.reportedById,
        data: {'itemId': item.id, 'claimId': claimRef.id},
      ),
    );
    await _sendPushNotification(
      targetUserId: item.reportedById,
      title: 'New Claim Request',
      body: 'Someone wants to claim your item',
      data: {'itemId': item.id, 'claimId': claimRef.id},
    );

    return claimRef.id;
  }

  Future<bool> approveClaim({
    required String claimId,
    required String itemId,
    required String claimantUserId,
    bool rejectOtherPendingClaims = true,
  }) async {
    try {
      final claimRef = _firestore.collection(_claimsCollection).doc(claimId);
      final itemRef = _firestore.collection(_collection).doc(itemId);
      await _firestore.runTransaction((tx) async {
        tx.update(claimRef, {
          'status': AppConstants.claimApproved,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        tx.update(itemRef, {
          'status': AppConstants.itemClaimed,
          'claimedBy': claimantUserId,
          'hasClaimRequest': false,
          'claimedAt': FieldValue.serverTimestamp(),
        });
      });

      if (rejectOtherPendingClaims) {
        final otherPendingClaims = await _firestore
            .collection(_claimsCollection)
            .where('itemId', isEqualTo: itemId)
            .get();
        final batch = _firestore.batch();
        for (final doc in otherPendingClaims.docs) {
          if (doc.id == claimId) continue;
          if ((doc.data()['status'] ?? '') != AppConstants.claimPending) {
            continue;
          }
          batch.update(doc.reference, {
            'status': AppConstants.claimRejected,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
        await batch.commit();
      }

      await _notificationService.sendNotification(
        NotificationModel(
          id: '',
          title: 'Claim Approved',
          message: 'Your claim has been approved',
          type: 'lost_found_claim',
          targetUserId: claimantUserId,
          data: {'itemId': itemId, 'claimId': claimId},
        ),
      );
      await _sendPushNotification(
        targetUserId: claimantUserId,
        title: 'Claim Approved',
        body: 'Your claim has been approved',
        data: {'itemId': itemId, 'claimId': claimId},
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> rejectClaim({
    required String claimId,
    required String claimantUserId,
    required String itemId,
  }) async {
    try {
      await _firestore.collection(_claimsCollection).doc(claimId).update({
        'status': AppConstants.claimRejected,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final stillPending = await _firestore
          .collection(_claimsCollection)
          .where('itemId', isEqualTo: itemId)
          .get();
      final hasPending = stillPending.docs.any(
        (doc) => (doc.data()['status'] ?? '') == AppConstants.claimPending,
      );
      if (!hasPending) {
        await _firestore.collection(_collection).doc(itemId).update({
          'hasClaimRequest': false,
        });
      }

      await _notificationService.sendNotification(
        NotificationModel(
          id: '',
          title: 'Claim Rejected',
          message: 'Your claim request was not approved by the owner.',
          type: 'lost_found_claim',
          targetUserId: claimantUserId,
          data: {'itemId': itemId, 'claimId': claimId},
        ),
      );
      await _sendPushNotification(
        targetUserId: claimantUserId,
        title: 'Claim Rejected',
        body: 'Your claim request was not approved by the owner.',
        data: {'itemId': itemId, 'claimId': claimId},
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> _sendPushNotification({
    required String targetUserId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      await _functions.httpsCallable('sendPushNotification').call({
        'targetUserId': targetUserId,
        'title': title,
        'body': body,
        'data': data ?? <String, dynamic>{},
      });
    } catch (_) {
      // Keep claims flow operational even when cloud push function is unavailable.
    }
  }

  /// Get item counts
  Future<Map<String, int>> getItemCounts() async {
    final snapshot = await _firestore.collection(_collection).get();

    int active = 0;
    int claimed = 0;
    int resolved = 0;

    for (var doc in snapshot.docs) {
      final status = doc.data()['status'] ?? AppConstants.itemActive;
      switch (status) {
        case 'active':
        case 'lost':
        case 'found':
          active++;
          break;
        case 'claimed':
          claimed++;
          break;
        case 'resolved':
        case 'returned':
          resolved++;
          break;
      }
    }

    return {
      'active': active,
      'claimed': claimed,
      'resolved': resolved,
      'total': snapshot.docs.length,
    };
  }
}
