import 'package:cloud_firestore/cloud_firestore.dart';

class InstallmentStatus {
  static const String paid = 'paid';
  static const String pending = 'pending';
  static const String upcoming = 'upcoming';
}

class InstallmentDetail {
  final int number;
  final String status;
  final double amount;
  final DateTime? dueDate;

  const InstallmentDetail({
    required this.number,
    required this.status,
    required this.amount,
    this.dueDate,
  });

  factory InstallmentDetail.fromMap(Map<String, dynamic> map) {
    return InstallmentDetail(
      number: map['number'] ?? 0,
      status: map['status'] ?? InstallmentStatus.upcoming,
      amount: (map['amount'] ?? 0).toDouble(),
      dueDate: (map['dueDate'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'number': number,
      'status': status,
      'amount': amount,
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
    };
  }
}

class InstallmentModel {
  final String id;
  final String paymentId;
  final String userId;
  final String userName;
  final String propertyId;
  final String propertyName;
  final int totalInstallments;
  final int paidInstallments;
  final double currentInstallmentAmount;
  final DateTime? dueDate;
  final List<InstallmentDetail> installmentDetails;
  final DateTime? updatedAt;

  const InstallmentModel({
    required this.id,
    required this.paymentId,
    required this.userId,
    required this.userName,
    required this.propertyId,
    required this.propertyName,
    required this.totalInstallments,
    required this.paidInstallments,
    required this.currentInstallmentAmount,
    this.dueDate,
    this.installmentDetails = const [],
    this.updatedAt,
  });

  int get pendingInstallments {
    if (paidInstallments >= totalInstallments) return 0;
    return 1;
  }

  int get upcomingInstallments {
    return (totalInstallments - paidInstallments - pendingInstallments).clamp(
      0,
      totalInstallments,
    );
  }

  double get progressPercent {
    if (totalInstallments <= 0) return 0;
    return (paidInstallments / totalInstallments) * 100;
  }

  factory InstallmentModel.fromMap(Map<String, dynamic> map, String id) {
    final details = (map['installmentDetails'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(InstallmentDetail.fromMap)
        .toList();

    return InstallmentModel(
      id: id,
      paymentId: map['paymentId'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      propertyId: map['propertyId'] ?? '',
      propertyName: map['propertyName'] ?? '',
      totalInstallments: map['totalInstallments'] ?? 0,
      paidInstallments: map['paidInstallments'] ?? 0,
      currentInstallmentAmount: (map['currentInstallmentAmount'] ?? 0)
          .toDouble(),
      dueDate: (map['dueDate'] as Timestamp?)?.toDate(),
      installmentDetails: details,
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'paymentId': paymentId,
      'userId': userId,
      'userName': userName,
      'propertyId': propertyId,
      'propertyName': propertyName,
      'totalInstallments': totalInstallments,
      'paidInstallments': paidInstallments,
      'currentInstallmentAmount': currentInstallmentAmount,
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'installmentDetails': installmentDetails.map((e) => e.toMap()).toList(),
      'updatedAt': updatedAt != null
          ? Timestamp.fromDate(updatedAt!)
          : FieldValue.serverTimestamp(),
    };
  }
}
