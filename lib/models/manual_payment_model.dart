import 'package:cloud_firestore/cloud_firestore.dart';

class ManualPaymentStatus {
  static const String pending = 'pending';
  static const String approved = 'approved';
  static const String rejected = 'rejected';
}

class ManualPaymentModel {
  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  final String propertyId;
  final String propertyName;
  final double amount;
  final String paymentMethod;
  final String accountNumberUsed;
  final String screenshotUrl;
  final String? linkedPaymentId;
  final int? installmentNumber;
  final String? installmentType;
  final String status;
  final String? rejectionReason;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ManualPaymentModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.propertyId,
    required this.propertyName,
    required this.amount,
    required this.paymentMethod,
    required this.accountNumberUsed,
    required this.screenshotUrl,
    this.linkedPaymentId,
    this.installmentNumber,
    this.installmentType,
    this.status = ManualPaymentStatus.pending,
    this.rejectionReason,
    this.createdAt,
    this.updatedAt,
  });

  factory ManualPaymentModel.fromMap(Map<String, dynamic> map, String id) {
    return ManualPaymentModel(
      id: id,
      userId: map['user_id'] ?? '',
      userName: map['user_name'] ?? '',
      userEmail: map['user_email'] ?? '',
      propertyId: map['property_id'] ?? '',
      propertyName: map['property_name'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      paymentMethod: map['payment_method'] ?? '',
      accountNumberUsed: map['account_number_used'] ?? '',
      screenshotUrl: map['screenshot_url'] ?? '',
      linkedPaymentId: map['linked_payment_id'],
      installmentNumber: map['installment_number'],
      installmentType: map['installment_type'],
      status: map['status'] ?? ManualPaymentStatus.pending,
      rejectionReason: map['rejection_reason'],
      createdAt: (map['created_at'] as Timestamp?)?.toDate(),
      updatedAt: (map['updated_at'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'user_name': userName,
      'user_email': userEmail,
      'property_id': propertyId,
      'property_name': propertyName,
      'amount': amount,
      'payment_method': paymentMethod,
      'account_number_used': accountNumberUsed,
      'screenshot_url': screenshotUrl,
      'linked_payment_id': linkedPaymentId,
      'installment_number': installmentNumber,
      'installment_type': installmentType,
      'status': status,
      'rejection_reason': rejectionReason,
      'created_at': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updated_at': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  ManualPaymentModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userEmail,
    String? propertyId,
    String? propertyName,
    double? amount,
    String? paymentMethod,
    String? accountNumberUsed,
    String? screenshotUrl,
    String? linkedPaymentId,
    int? installmentNumber,
    String? installmentType,
    String? status,
    String? rejectionReason,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ManualPaymentModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      propertyId: propertyId ?? this.propertyId,
      propertyName: propertyName ?? this.propertyName,
      amount: amount ?? this.amount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      accountNumberUsed: accountNumberUsed ?? this.accountNumberUsed,
      screenshotUrl: screenshotUrl ?? this.screenshotUrl,
      linkedPaymentId: linkedPaymentId ?? this.linkedPaymentId,
      installmentNumber: installmentNumber ?? this.installmentNumber,
      installmentType: installmentType ?? this.installmentType,
      status: status ?? this.status,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
