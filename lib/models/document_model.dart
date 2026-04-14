import 'package:cloud_firestore/cloud_firestore.dart';

/// Document model for client document verification
class DocumentModel {
  final String id;
  final String clientId;
  final String clientName;
  final String clientEmail;
  final String cnic;
  final String? cnicFrontUrl;
  final String? cnicBackUrl;
  final String filerStatus; // filer, non_filer
  final bool? isFiler;
  final String? ntnNumber;
  final String? filerDocumentUrl;
  final String? otherDocumentUrl;
  final String? otherDocumentName;
  final String status; // pending, verified, rejected
  final String? rejectionReason;
  final String? verifiedBy;
  final DateTime? createdAt;
  final DateTime? submittedAt;
  final DateTime? verifiedAt;
  final List<String> additionalDocuments;

  const DocumentModel({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.clientEmail,
    required this.cnic,
    this.cnicFrontUrl,
    this.cnicBackUrl,
    this.filerStatus = 'filer',
    this.isFiler,
    this.ntnNumber,
    this.filerDocumentUrl,
    this.otherDocumentUrl,
    this.otherDocumentName,
    this.status = 'pending',
    this.rejectionReason,
    this.verifiedBy,
    this.createdAt,
    this.submittedAt,
    this.verifiedAt,
    this.additionalDocuments = const [],
  });

  bool get hasAllRequiredDocuments =>
      cnicFrontUrl != null && cnicBackUrl != null;

  factory DocumentModel.fromMap(Map<String, dynamic> map, String docId) {
    return DocumentModel(
      id: docId,
      clientId: map['clientId'] ?? '',
      clientName: map['clientName'] ?? '',
      clientEmail: map['clientEmail'] ?? '',
      cnic: map['cnic'] ?? '',
      cnicFrontUrl: map['cnicFrontUrl'],
      cnicBackUrl: map['cnicBackUrl'],
      filerStatus: map['filerStatus'] ?? 'filer',
      isFiler: map['isFiler'],
      ntnNumber: map['ntnNumber'],
      filerDocumentUrl: map['filerDocumentUrl'],
      otherDocumentUrl: map['otherDocumentUrl'],
      otherDocumentName: map['otherDocumentName'],
      status: map['status'] ?? 'pending',
      rejectionReason: map['rejectionReason'],
      verifiedBy: map['verifiedBy'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      submittedAt: (map['submittedAt'] as Timestamp?)?.toDate(),
      verifiedAt: (map['verifiedAt'] as Timestamp?)?.toDate(),
      additionalDocuments: (map['additionalDocuments'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'clientId': clientId,
      'clientName': clientName,
      'clientEmail': clientEmail,
      'cnic': cnic,
      'cnicFrontUrl': cnicFrontUrl,
      'cnicBackUrl': cnicBackUrl,
      'filerStatus': filerStatus,
      'isFiler': isFiler ?? (filerStatus.toLowerCase() == 'filer'),
      'ntnNumber': ntnNumber,
      'filerDocumentUrl': filerDocumentUrl,
      'otherDocumentUrl': otherDocumentUrl,
      'otherDocumentName': otherDocumentName,
      'status': status,
      'rejectionReason': rejectionReason,
      'verifiedBy': verifiedBy,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'submittedAt': submittedAt != null
          ? Timestamp.fromDate(submittedAt!)
          : FieldValue.serverTimestamp(),
      'verifiedAt': verifiedAt != null ? Timestamp.fromDate(verifiedAt!) : null,
      'additionalDocuments': additionalDocuments,
    };
  }

  DocumentModel copyWith({
    String? id,
    String? clientId,
    String? clientName,
    String? clientEmail,
    String? cnic,
    String? cnicFrontUrl,
    String? cnicBackUrl,
    String? filerStatus,
    bool? isFiler,
    String? ntnNumber,
    String? filerDocumentUrl,
    String? otherDocumentUrl,
    String? otherDocumentName,
    String? status,
    String? rejectionReason,
    String? verifiedBy,
    DateTime? createdAt,
    DateTime? submittedAt,
    DateTime? verifiedAt,
    List<String>? additionalDocuments,
  }) {
    return DocumentModel(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      clientEmail: clientEmail ?? this.clientEmail,
      cnic: cnic ?? this.cnic,
      cnicFrontUrl: cnicFrontUrl ?? this.cnicFrontUrl,
      cnicBackUrl: cnicBackUrl ?? this.cnicBackUrl,
      filerStatus: filerStatus ?? this.filerStatus,
      isFiler: isFiler ?? this.isFiler,
      ntnNumber: ntnNumber ?? this.ntnNumber,
      filerDocumentUrl: filerDocumentUrl ?? this.filerDocumentUrl,
      otherDocumentUrl: otherDocumentUrl ?? this.otherDocumentUrl,
      otherDocumentName: otherDocumentName ?? this.otherDocumentName,
      status: status ?? this.status,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      verifiedBy: verifiedBy ?? this.verifiedBy,
      createdAt: createdAt ?? this.createdAt,
      submittedAt: submittedAt ?? this.submittedAt,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      additionalDocuments: additionalDocuments ?? this.additionalDocuments,
    );
  }

  // Convenience getters for UI compatibility
  bool get isFilerFlag => isFiler ?? filerStatus.toLowerCase() == 'filer';
  DateTime? get submittedAtDate => submittedAt ?? createdAt;
  String get email => clientEmail;
}
