import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/lost_found_model.dart';

/// Service for lost and found items management
class LostFoundService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'lost_found';

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
      await _firestore.collection(_collection).add(item.toMap());
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Update item status
  Future<bool> updateItemStatus(String itemId, String status) async {
    try {
      final updateData = <String, dynamic>{'status': status};

      if (status == 'claimed') {
        updateData['claimedAt'] = FieldValue.serverTimestamp();
      } else if (status == 'returned') {
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
        'status': 'claimed',
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
        'status': 'returned',
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

  /// Get item counts
  Future<Map<String, int>> getItemCounts() async {
    final snapshot = await _firestore.collection(_collection).get();

    int lost = 0;
    int found = 0;
    int claimed = 0;
    int returned = 0;

    for (var doc in snapshot.docs) {
      final status = doc.data()['status'] ?? 'lost';
      switch (status) {
        case 'lost':
          lost++;
          break;
        case 'found':
          found++;
          break;
        case 'claimed':
          claimed++;
          break;
        case 'returned':
          returned++;
          break;
      }
    }

    return {
      'lost': lost,
      'found': found,
      'claimed': claimed,
      'returned': returned,
      'total': snapshot.docs.length,
    };
  }
}
