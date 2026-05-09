import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for payment challan records
class ChallanModel {
  final String id;
  final String challanId;
  final String userId;
  final String userName;
  final String userEmail;
  final String userCnic;
  final String userPhone;
  final String propertyId;
  final String propertyName;
  final String plotNumber;
  final String blockName;
  final int installmentNumber;
  final double amount;
  final String purpose;
  final String bankName;
  final String accountNumber;
  final String bankId;
  final String iban;
  final String status; // pending, downloaded, deposited
  final DateTime generatedAt;
  final DateTime? downloadedAt;
  final DateTime? depositedAt;

  const ChallanModel({
    required this.id,
    required this.challanId,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.userCnic,
    required this.userPhone,
    required this.propertyId,
    required this.propertyName,
    required this.plotNumber,
    required this.blockName,
    required this.installmentNumber,
    required this.amount,
    required this.purpose,
    required this.bankName,
    required this.accountNumber,
    this.bankId = '',
    required this.iban,
    this.status = 'pending',
    required this.generatedAt,
    this.downloadedAt,
    this.depositedAt,
  });

  factory ChallanModel.fromMap(Map<String, dynamic> map, String id) {
    return ChallanModel(
      id: id,
      challanId: map['challan_id'] ?? '',
      userId: map['user_id'] ?? '',
      userName: map['user_name'] ?? '',
      userEmail: map['user_email'] ?? '',
      userCnic: map['user_cnic'] ?? '',
      userPhone: map['user_phone'] ?? '',
      propertyId: map['property_id'] ?? '',
      propertyName: map['property_name'] ?? '',
      plotNumber: map['plot_number'] ?? '',
      blockName: map['block_name'] ?? '',
      installmentNumber: map['installment_number'] ?? 0,
      amount: (map['amount'] ?? 0).toDouble(),
      purpose: map['purpose'] ?? 'Installment Fee',
      bankName: map['bank_name'] ?? 'Royal Nest Bank',
      accountNumber: map['account_number'] ?? '',
      bankId: map['bank_id'] ?? '',
      iban: map['iban'] ?? '',
      status: map['status'] ?? 'pending',
      generatedAt:
          (map['generated_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      downloadedAt: (map['downloaded_at'] as Timestamp?)?.toDate(),
      depositedAt: (map['deposited_at'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'challan_id': challanId,
      'user_id': userId,
      'user_name': userName,
      'user_email': userEmail,
      'user_cnic': userCnic,
      'user_phone': userPhone,
      'property_id': propertyId,
      'property_name': propertyName,
      'plot_number': plotNumber,
      'block_name': blockName,
      'installment_number': installmentNumber,
      'amount': amount,
      'purpose': purpose,
      'bank_name': bankName,
      'account_number': accountNumber,
      'bank_id': bankId,
      'iban': iban,
      'status': status,
      'generated_at': Timestamp.fromDate(generatedAt),
      'downloaded_at': downloadedAt != null
          ? Timestamp.fromDate(downloadedAt!)
          : null,
      'deposited_at': depositedAt != null
          ? Timestamp.fromDate(depositedAt!)
          : null,
    };
  }

  ChallanModel copyWith({
    String? id,
    String? challanId,
    String? userId,
    String? userName,
    String? userEmail,
    String? userCnic,
    String? userPhone,
    String? propertyId,
    String? propertyName,
    String? plotNumber,
    String? blockName,
    int? installmentNumber,
    double? amount,
    String? purpose,
    String? bankName,
    String? accountNumber,
    String? bankId,
    String? iban,
    String? status,
    DateTime? generatedAt,
    DateTime? downloadedAt,
    DateTime? depositedAt,
  }) {
    return ChallanModel(
      id: id ?? this.id,
      challanId: challanId ?? this.challanId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      userCnic: userCnic ?? this.userCnic,
      userPhone: userPhone ?? this.userPhone,
      propertyId: propertyId ?? this.propertyId,
      propertyName: propertyName ?? this.propertyName,
      plotNumber: plotNumber ?? this.plotNumber,
      blockName: blockName ?? this.blockName,
      installmentNumber: installmentNumber ?? this.installmentNumber,
      amount: amount ?? this.amount,
      purpose: purpose ?? this.purpose,
      bankName: bankName ?? this.bankName,
      accountNumber: accountNumber ?? this.accountNumber,
      bankId: bankId ?? this.bankId,
      iban: iban ?? this.iban,
      status: status ?? this.status,
      generatedAt: generatedAt ?? this.generatedAt,
      downloadedAt: downloadedAt ?? this.downloadedAt,
      depositedAt: depositedAt ?? this.depositedAt,
    );
  }
}
