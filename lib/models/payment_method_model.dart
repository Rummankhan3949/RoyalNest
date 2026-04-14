import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentMethodModel {
  final String id;
  final String methodName;
  final String accountTitle;
  final String accountNumber;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const PaymentMethodModel({
    required this.id,
    required this.methodName,
    required this.accountTitle,
    required this.accountNumber,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory PaymentMethodModel.fromMap(Map<String, dynamic> map, String id) {
    return PaymentMethodModel(
      id: id,
      methodName: (map['method_name'] ?? map['methodName'] ?? '').toString(),
      accountTitle: (map['account_title'] ?? map['accountTitle'] ?? '')
          .toString(),
      accountNumber: (map['account_number'] ?? map['accountNumber'] ?? '')
          .toString(),
      isActive: (map['is_active'] ?? map['isActive'] ?? true) == true,
      createdAt: ((map['created_at'] ?? map['createdAt']) as Timestamp?)
          ?.toDate(),
      updatedAt: ((map['updated_at'] ?? map['updatedAt']) as Timestamp?)
          ?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'method_name': methodName,
      'account_title': accountTitle,
      'account_number': accountNumber,
      'is_active': isActive,
      'created_at': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updated_at': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  PaymentMethodModel copyWith({
    String? id,
    String? methodName,
    String? accountTitle,
    String? accountNumber,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PaymentMethodModel(
      id: id ?? this.id,
      methodName: methodName ?? this.methodName,
      accountTitle: accountTitle ?? this.accountTitle,
      accountNumber: accountNumber ?? this.accountNumber,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
