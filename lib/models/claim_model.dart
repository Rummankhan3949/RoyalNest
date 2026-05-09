import 'package:cloud_firestore/cloud_firestore.dart';

/// Claim request model for Lost & Found verification flow.
class ClaimModel {
  final String id;
  final String itemId;
  final String claimantUserId;
  final String claimantName;
  final String ownerUserId;
  final String proofText;
  final String? proofImageUrl;
  final String status; // pending | approved | rejected
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ClaimModel({
    required this.id,
    required this.itemId,
    required this.claimantUserId,
    required this.claimantName,
    required this.ownerUserId,
    required this.proofText,
    this.proofImageUrl,
    this.status = 'pending',
    this.createdAt,
    this.updatedAt,
  });

  factory ClaimModel.fromMap(Map<String, dynamic> map, String docId) {
    return ClaimModel(
      id: docId,
      itemId: map['itemId'] ?? '',
      claimantUserId: map['claimantUserId'] ?? '',
      claimantName: map['claimantName'] ?? '',
      ownerUserId: map['ownerUserId'] ?? '',
      proofText: map['proofText'] ?? '',
      proofImageUrl: map['proofImageUrl'],
      status: map['status'] ?? 'pending',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'claimantUserId': claimantUserId,
      'claimantName': claimantName,
      'ownerUserId': ownerUserId,
      'proofText': proofText,
      'proofImageUrl': proofImageUrl,
      'status': status,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': updatedAt != null
          ? Timestamp.fromDate(updatedAt!)
          : FieldValue.serverTimestamp(),
    };
  }
}
