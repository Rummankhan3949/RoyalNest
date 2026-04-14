import 'package:cloud_firestore/cloud_firestore.dart';

/// Receipt model for payment receipts
class ReceiptModel {
  final String id;
  final String receiptNumber;
  final String paymentId;
  final String clientId;
  final String clientName;
  final String clientEmail;
  final String plotDetails;
  final double amount;
  final String paymentMethod;
  final String? stripePaymentIntentId;
  final int installmentNumber;
  final int totalInstallments;
  final double totalPaidSoFar;
  final double totalAmount;
  final String status; // completed, refunded
  final DateTime paidDate;
  final DateTime? createdAt;

  const ReceiptModel({
    required this.id,
    required this.receiptNumber,
    required this.paymentId,
    required this.clientId,
    required this.clientName,
    required this.clientEmail,
    required this.plotDetails,
    required this.amount,
    required this.paymentMethod,
    this.stripePaymentIntentId,
    required this.installmentNumber,
    required this.totalInstallments,
    required this.totalPaidSoFar,
    required this.totalAmount,
    this.status = 'completed',
    required this.paidDate,
    this.createdAt,
  });

  /// Generate a unique receipt number: RN-YYYYMMDD-XXXX
  static String generateReceiptNumber() {
    final now = DateTime.now();
    final datePart =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final randomPart =
        (now.millisecondsSinceEpoch % 10000).toString().padLeft(4, '0');
    return 'RN-$datePart-$randomPart';
  }

  factory ReceiptModel.fromMap(Map<String, dynamic> map, String docId) {
    return ReceiptModel(
      id: docId,
      receiptNumber: map['receiptNumber'] ?? '',
      paymentId: map['paymentId'] ?? '',
      clientId: map['clientId'] ?? '',
      clientName: map['clientName'] ?? '',
      clientEmail: map['clientEmail'] ?? '',
      plotDetails: map['plotDetails'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      paymentMethod: map['paymentMethod'] ?? '',
      stripePaymentIntentId: map['stripePaymentIntentId'],
      installmentNumber: map['installmentNumber'] ?? 0,
      totalInstallments: map['totalInstallments'] ?? 0,
      totalPaidSoFar: (map['totalPaidSoFar'] ?? 0).toDouble(),
      totalAmount: (map['totalAmount'] ?? 0).toDouble(),
      status: map['status'] ?? 'completed',
      paidDate: (map['paidDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'receiptNumber': receiptNumber,
      'paymentId': paymentId,
      'clientId': clientId,
      'clientName': clientName,
      'clientEmail': clientEmail,
      'plotDetails': plotDetails,
      'amount': amount,
      'paymentMethod': paymentMethod,
      'stripePaymentIntentId': stripePaymentIntentId,
      'installmentNumber': installmentNumber,
      'totalInstallments': totalInstallments,
      'totalPaidSoFar': totalPaidSoFar,
      'totalAmount': totalAmount,
      'status': status,
      'paidDate': Timestamp.fromDate(paidDate),
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  ReceiptModel copyWith({
    String? id,
    String? receiptNumber,
    String? paymentId,
    String? clientId,
    String? clientName,
    String? clientEmail,
    String? plotDetails,
    double? amount,
    String? paymentMethod,
    String? stripePaymentIntentId,
    int? installmentNumber,
    int? totalInstallments,
    double? totalPaidSoFar,
    double? totalAmount,
    String? status,
    DateTime? paidDate,
    DateTime? createdAt,
  }) {
    return ReceiptModel(
      id: id ?? this.id,
      receiptNumber: receiptNumber ?? this.receiptNumber,
      paymentId: paymentId ?? this.paymentId,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      clientEmail: clientEmail ?? this.clientEmail,
      plotDetails: plotDetails ?? this.plotDetails,
      amount: amount ?? this.amount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      stripePaymentIntentId:
          stripePaymentIntentId ?? this.stripePaymentIntentId,
      installmentNumber: installmentNumber ?? this.installmentNumber,
      totalInstallments: totalInstallments ?? this.totalInstallments,
      totalPaidSoFar: totalPaidSoFar ?? this.totalPaidSoFar,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      paidDate: paidDate ?? this.paidDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
