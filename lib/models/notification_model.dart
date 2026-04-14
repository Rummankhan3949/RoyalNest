import 'package:cloud_firestore/cloud_firestore.dart';

/// Notification model for admin-client communication
class NotificationModel {
  final String id;
  final String title;
  final String message;
  final String type; // payment_reminder, appointment, document, query, general
  final String targetUserId; // Client ID or 'all' for broadcast
  final bool isRead;
  final Map<String, dynamic>? data; // Additional data for navigation
  final DateTime? createdAt;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.targetUserId,
    this.isRead = false,
    this.data,
    this.createdAt,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map, String docId) {
    return NotificationModel(
      id: docId,
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      type: map['type'] ?? 'general',
      targetUserId: map['targetUserId'] ?? '',
      isRead: map['isRead'] ?? false,
      data: map['data'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'message': message,
      'type': type,
      'targetUserId': targetUserId,
      'isRead': isRead,
      'data': data,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  NotificationModel copyWith({
    String? id,
    String? title,
    String? message,
    String? type,
    String? targetUserId,
    bool? isRead,
    Map<String, dynamic>? data,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      targetUserId: targetUserId ?? this.targetUserId,
      isRead: isRead ?? this.isRead,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
