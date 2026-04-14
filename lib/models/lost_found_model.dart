import 'package:cloud_firestore/cloud_firestore.dart';

/// Lost and Found item model
class LostFoundModel {
  final String id;
  final String title;
  final String description;
  final String category; // Keys, Wallet, Phone, Documents, Other
  final String type; // lost, found
  final String reportedById;
  final String? imageUrl;
  final String location; // Where it was lost/found
  final String society;
  final String reportedBy;
  final String reporterContact;
  final String status; // lost, found, claimed, returned
  final String? claimedBy;
  final String? claimerContact;
  final DateTime? reportedAt;
  final DateTime? claimedAt;
  final DateTime? returnedAt;

  const LostFoundModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    this.type = 'lost',
    this.reportedById = '',
    this.imageUrl,
    required this.location,
    required this.society,
    required this.reportedBy,
    required this.reporterContact,
    this.status = 'lost',
    this.claimedBy,
    this.claimerContact,
    this.reportedAt,
    this.claimedAt,
    this.returnedAt,
  });

  factory LostFoundModel.fromMap(Map<String, dynamic> map, String docId) {
    return LostFoundModel(
      id: docId,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? 'Other',
      type: map['type'] ?? 'lost',
      reportedById: map['reportedById'] ?? '',
      imageUrl: map['imageUrl'],
      location: map['location'] ?? '',
      society: map['society'] ?? '',
      reportedBy: map['reportedBy'] ?? '',
      reporterContact: map['reporterContact'] ?? '',
      status: map['status'] ?? 'lost',
      claimedBy: map['claimedBy'],
      claimerContact: map['claimerContact'],
      reportedAt: (map['reportedAt'] as Timestamp?)?.toDate(),
      claimedAt: (map['claimedAt'] as Timestamp?)?.toDate(),
      returnedAt: (map['returnedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'type': type,
      'reportedById': reportedById,
      'imageUrl': imageUrl,
      'location': location,
      'society': society,
      'reportedBy': reportedBy,
      'reporterContact': reporterContact,
      'status': status,
      'claimedBy': claimedBy,
      'claimerContact': claimerContact,
      'reportedAt': reportedAt != null
          ? Timestamp.fromDate(reportedAt!)
          : FieldValue.serverTimestamp(),
      'claimedAt': claimedAt != null ? Timestamp.fromDate(claimedAt!) : null,
      'returnedAt': returnedAt != null ? Timestamp.fromDate(returnedAt!) : null,
    };
  }

  LostFoundModel copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    String? type,
    String? imageUrl,
    String? location,
    String? society,
    String? reportedBy,
    String? reporterContact,
    String? status,
    String? claimedBy,
    String? claimerContact,
    DateTime? reportedAt,
    DateTime? claimedAt,
    DateTime? returnedAt,
  }) {
    return LostFoundModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      type: type ?? this.type,
      imageUrl: imageUrl ?? this.imageUrl,
      location: location ?? this.location,
      society: society ?? this.society,
      reportedBy: reportedBy ?? this.reportedBy,
      reporterContact: reporterContact ?? this.reporterContact,
      status: status ?? this.status,
      claimedBy: claimedBy ?? this.claimedBy,
      claimerContact: claimerContact ?? this.claimerContact,
      reportedAt: reportedAt ?? this.reportedAt,
      claimedAt: claimedAt ?? this.claimedAt,
      returnedAt: returnedAt ?? this.returnedAt,
    );
  }
}
