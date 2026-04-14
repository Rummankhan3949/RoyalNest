import 'package:cloud_firestore/cloud_firestore.dart';

/// Query/Complaint model for client support
class QueryModel {
  final String id;
  final String clientId;
  final String clientName;
  final String clientEmail;
  final String subject;
  final String description;
  final String category; // General, Payment, Plot, Documents, Other
  final String status; // pending, in_progress, completed
  final String? adminResponse;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? resolvedAt;

  const QueryModel({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.clientEmail,
    required this.subject,
    required this.description,
    this.category = 'General',
    this.status = 'pending',
    this.adminResponse,
    this.createdAt,
    this.updatedAt,
    this.resolvedAt,
  });

  factory QueryModel.fromMap(Map<String, dynamic> map, String docId) {
    return QueryModel(
      id: docId,
      clientId: map['clientId'] ?? '',
      clientName: map['clientName'] ?? '',
      clientEmail: map['clientEmail'] ?? '',
      subject: map['subject'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? 'General',
      status: map['status'] ?? 'pending',
      adminResponse: map['adminResponse'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
      resolvedAt: (map['resolvedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'clientId': clientId,
      'clientName': clientName,
      'clientEmail': clientEmail,
      'subject': subject,
      'description': description,
      'category': category,
      'status': status,
      'adminResponse': adminResponse,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'resolvedAt': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
    };
  }

  QueryModel copyWith({
    String? id,
    String? clientId,
    String? clientName,
    String? clientEmail,
    String? subject,
    String? description,
    String? category,
    String? status,
    String? adminResponse,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? resolvedAt,
  }) {
    return QueryModel(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      clientEmail: clientEmail ?? this.clientEmail,
      subject: subject ?? this.subject,
      description: description ?? this.description,
      category: category ?? this.category,
      status: status ?? this.status,
      adminResponse: adminResponse ?? this.adminResponse,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
    );
  }
}
