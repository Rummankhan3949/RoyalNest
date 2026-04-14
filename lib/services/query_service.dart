import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/query_model.dart';
import '../models/notification_model.dart';
import '../core/constants/app_constants.dart';

/// Service for query and complaints management
class QueryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'queries';
  final String _notificationCollection = 'notifications';

  /// Get all queries
  Stream<List<QueryModel>> getAllQueries() {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => QueryModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  /// Get queries by status
  Stream<List<QueryModel>> getQueriesByStatus(String status) {
    return _firestore
        .collection(_collection)
        .where('status', isEqualTo: status)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => QueryModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  /// Get client's queries
  Stream<List<QueryModel>> getClientQueries(String clientId, [String? status]) {
    Query<Map<String, dynamic>> query = _firestore
        .collection(_collection)
        .where('clientId', isEqualTo: clientId);

    if (status != null && status != 'all') {
      query = query.where('status', isEqualTo: status);
    }

    return query.snapshots().map(
      (snapshot) => snapshot.docs
          .map((doc) => QueryModel.fromMap(doc.data(), doc.id))
          .toList(),
    );
  }

  /// Add new query
  Future<bool> addQuery(QueryModel query) async {
    try {
      await _firestore.collection(_collection).add(query.toMap());
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Alias used by UI
  Future<bool> submitQuery(QueryModel query) => addQuery(query);

  /// Update query status
  Future<bool> updateQueryStatus(
    String queryId,
    String status, {
    String? adminResponse,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (adminResponse != null) {
        updateData['adminResponse'] = adminResponse;
      }

      if (status == AppConstants.queryCompleted) {
        updateData['resolvedAt'] = FieldValue.serverTimestamp();
      }

      await _firestore.collection(_collection).doc(queryId).update(updateData);

      // Get query details to send notification
      final queryDoc = await _firestore
          .collection(_collection)
          .doc(queryId)
          .get();
      if (queryDoc.exists) {
        final query = QueryModel.fromMap(queryDoc.data()!, queryDoc.id);
        await _sendQueryNotification(query, status, adminResponse);
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Send notification to client about query update
  Future<void> _sendQueryNotification(
    QueryModel query,
    String status,
    String? response,
  ) async {
    String title;
    String message;

    switch (status) {
      case AppConstants.queryInProgress:
        title = 'Query In Progress';
        message = 'Your query "${query.subject}" is now being reviewed.';
        break;
      case AppConstants.queryCompleted:
        title = 'Query Resolved';
        message = response != null
            ? 'Your query "${query.subject}" has been resolved. Response: $response'
            : 'Your query "${query.subject}" has been resolved.';
        break;
      default:
        return;
    }

    final notification = NotificationModel(
      id: '',
      title: title,
      message: message,
      type: 'query',
      targetUserId: query.clientId,
      data: {'queryId': query.id},
    );

    await _firestore
        .collection(_notificationCollection)
        .add(notification.toMap());
  }

  /// Delete query
  Future<bool> deleteQuery(String queryId) async {
    try {
      await _firestore.collection(_collection).doc(queryId).delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get query counts by status
  Future<Map<String, int>> getQueryCounts() async {
    final snapshot = await _firestore.collection(_collection).get();

    int pending = 0;
    int inProgress = 0;
    int completed = 0;

    for (var doc in snapshot.docs) {
      final status = doc.data()['status'] ?? 'pending';
      switch (status) {
        case AppConstants.queryPending:
          pending++;
          break;
        case AppConstants.queryInProgress:
          inProgress++;
          break;
        case AppConstants.queryCompleted:
          completed++;
          break;
      }
    }

    return {
      'pending': pending,
      'inProgress': inProgress,
      'completed': completed,
      'total': snapshot.docs.length,
    };
  }

  /// Pending queries count for a client
  Future<int> getPendingQueriesCount(String clientId) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('clientId', isEqualTo: clientId)
        .where('status', isEqualTo: AppConstants.queryPending)
        .get();
    return snapshot.docs.length;
  }
}
