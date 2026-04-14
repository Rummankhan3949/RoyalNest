import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/notification_model.dart';

/// Service for notification management
class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'notifications';

  /// Get all notifications
  Stream<List<NotificationModel>> getAllNotifications() {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => NotificationModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  /// Get user's notifications
  Stream<List<NotificationModel>> getUserNotifications(String userId) {
    return _firestore
        .collection(_collection)
        .where('targetUserId', isEqualTo: userId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => NotificationModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  /// Alias for getUserNotifications (for convenience)
  Stream<List<NotificationModel>> getNotifications(
    String userId, {
    int? limit,
  }) {
    Query<Map<String, dynamic>> query = _firestore
        .collection(_collection)
        .where('targetUserId', isEqualTo: userId);

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map(
      (snapshot) => snapshot.docs
          .map((doc) => NotificationModel.fromMap(doc.data(), doc.id))
          .toList(),
    );
  }

  /// Get unread notifications count
  Stream<int> getUnreadCount(String userId) {
    return _firestore
        .collection(_collection)
        .where('targetUserId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Send notification
  Future<bool> sendNotification(NotificationModel notification) async {
    try {
      await _firestore.collection(_collection).add(notification.toMap());
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Send broadcast notification to all clients
  Future<bool> sendBroadcastNotification(
    String title,
    String message,
    String type,
  ) async {
    try {
      final notification = NotificationModel(
        id: '',
        title: title,
        message: message,
        type: type,
        targetUserId: 'all',
      );
      await _firestore.collection(_collection).add(notification.toMap());
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Mark notification as read
  Future<bool> markAsRead(String notificationId) async {
    try {
      await _firestore.collection(_collection).doc(notificationId).update({
        'isRead': true,
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Mark all notifications as read
  Future<bool> markAllAsRead(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('targetUserId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Delete notification
  Future<bool> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection(_collection).doc(notificationId).delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Clear all user notifications
  Future<bool> clearAllNotifications(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('targetUserId', isEqualTo: userId)
          .get();

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      return true;
    } catch (e) {
      return false;
    }
  }
}
