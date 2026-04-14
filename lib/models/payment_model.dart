import 'package:cloud_firestore/cloud_firestore.dart';

/// Payment/Installment model for tracking client payments
class PaymentModel {
  final String id;
  final String clientId;
  final String clientName;
  final String plotId;
  final String plotDetails; // e.g., "5 Marla - Block A - Royal City"
  final double totalAmount;
  final double bookingAmount;
  final double confirmationAmount;
  final double monthlyInstallment;
  final int totalInstallments;
  final int paidInstallments;
  final double paidAmount;
  final double remainingAmount;
  final String status; // paid, unpaid, partial
  final List<InstallmentRecord> installmentHistory;
  final DateTime? nextDueDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const PaymentModel({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.plotId,
    required this.plotDetails,
    required this.totalAmount,
    required this.bookingAmount,
    required this.confirmationAmount,
    required this.monthlyInstallment,
    required this.totalInstallments,
    this.paidInstallments = 0,
    this.paidAmount = 0,
    required this.remainingAmount,
    this.status = 'unpaid',
    this.installmentHistory = const [],
    this.nextDueDate,
    this.createdAt,
    this.updatedAt,
  });

  double get progressPercentage => (paidAmount / totalAmount) * 100;

  factory PaymentModel.fromMap(Map<String, dynamic> map, String docId) {
    List<InstallmentRecord> history = [];
    if (map['installmentHistory'] != null) {
      history = (map['installmentHistory'] as List)
          .map((e) => InstallmentRecord.fromMap(e))
          .toList();
    }

    return PaymentModel(
      id: docId,
      clientId: map['clientId'] ?? '',
      clientName: map['clientName'] ?? '',
      plotId: map['plotId'] ?? '',
      plotDetails: map['plotDetails'] ?? '',
      totalAmount: (map['totalAmount'] ?? 0).toDouble(),
      bookingAmount: (map['bookingAmount'] ?? 0).toDouble(),
      confirmationAmount: (map['confirmationAmount'] ?? 0).toDouble(),
      monthlyInstallment: (map['monthlyInstallment'] ?? 0).toDouble(),
      totalInstallments: map['totalInstallments'] ?? 0,
      paidInstallments: map['paidInstallments'] ?? 0,
      paidAmount: (map['paidAmount'] ?? 0).toDouble(),
      remainingAmount: (map['remainingAmount'] ?? 0).toDouble(),
      status: map['status'] ?? 'unpaid',
      installmentHistory: history,
      nextDueDate: (map['nextDueDate'] as Timestamp?)?.toDate(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'clientId': clientId,
      'clientName': clientName,
      'plotId': plotId,
      'plotDetails': plotDetails,
      'totalAmount': totalAmount,
      'bookingAmount': bookingAmount,
      'confirmationAmount': confirmationAmount,
      'monthlyInstallment': monthlyInstallment,
      'totalInstallments': totalInstallments,
      'paidInstallments': paidInstallments,
      'paidAmount': paidAmount,
      'remainingAmount': remainingAmount,
      'status': status,
      'installmentHistory': installmentHistory.map((e) => e.toMap()).toList(),
      'nextDueDate': nextDueDate != null
          ? Timestamp.fromDate(nextDueDate!)
          : null,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  PaymentModel copyWith({
    String? id,
    String? clientId,
    String? clientName,
    String? plotId,
    String? plotDetails,
    double? totalAmount,
    double? bookingAmount,
    double? confirmationAmount,
    double? monthlyInstallment,
    int? totalInstallments,
    int? paidInstallments,
    double? paidAmount,
    double? remainingAmount,
    String? status,
    List<InstallmentRecord>? installmentHistory,
    DateTime? nextDueDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PaymentModel(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      plotId: plotId ?? this.plotId,
      plotDetails: plotDetails ?? this.plotDetails,
      totalAmount: totalAmount ?? this.totalAmount,
      bookingAmount: bookingAmount ?? this.bookingAmount,
      confirmationAmount: confirmationAmount ?? this.confirmationAmount,
      monthlyInstallment: monthlyInstallment ?? this.monthlyInstallment,
      totalInstallments: totalInstallments ?? this.totalInstallments,
      paidInstallments: paidInstallments ?? this.paidInstallments,
      paidAmount: paidAmount ?? this.paidAmount,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      status: status ?? this.status,
      installmentHistory: installmentHistory ?? this.installmentHistory,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Individual installment record
class InstallmentRecord {
  final int installmentNumber;
  final double amount;
  final DateTime paidDate;
  final String paymentMethod;
  final String? receiptNumber;
  final String? note;

  const InstallmentRecord({
    required this.installmentNumber,
    required this.amount,
    required this.paidDate,
    required this.paymentMethod,
    this.receiptNumber,
    this.note,
  });

  factory InstallmentRecord.fromMap(Map<String, dynamic> map) {
    return InstallmentRecord(
      installmentNumber: map['installmentNumber'] ?? 0,
      amount: (map['amount'] ?? 0).toDouble(),
      paidDate: (map['paidDate'] as Timestamp).toDate(),
      paymentMethod: map['paymentMethod'] ?? '',
      receiptNumber: map['receiptNumber'],
      note: map['note'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'installmentNumber': installmentNumber,
      'amount': amount,
      'paidDate': Timestamp.fromDate(paidDate),
      'paymentMethod': paymentMethod,
      'receiptNumber': receiptNumber,
      'note': note,
    };
  }
}
