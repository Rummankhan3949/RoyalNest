import 'package:cloud_firestore/cloud_firestore.dart';

/// User model representing both admin and client users
class UserModel {
  final String uid;
  final String username;
  final String email;
  final String cnic;
  final String role; // 'admin' or 'client'
  final String? phone;
  final String? address;
  final bool isFiler;
  final bool isDocumentsVerified;
  final DateTime? createdAt;

  const UserModel({
    required this.uid,
    required this.username,
    required this.email,
    required this.cnic,
    required this.role,
    this.phone,
    this.address,
    this.isFiler = true,
    this.isDocumentsVerified = false,
    this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      username: map['username'] ?? '',
      email: map['email'] ?? '',
      cnic: map['cnic'] ?? '',
      role: map['role'] ?? 'client',
      phone: map['phone'],
      address: map['address'],
      isFiler: map['isFiler'] ?? true,
      isDocumentsVerified: map['isDocumentsVerified'] ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'username': username,
      'email': email,
      'cnic': cnic,
      'role': role,
      'phone': phone,
      'address': address,
      'isFiler': isFiler,
      'isDocumentsVerified': isDocumentsVerified,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  UserModel copyWith({
    String? uid,
    String? username,
    String? email,
    String? cnic,
    String? role,
    String? phone,
    String? address,
    bool? isFiler,
    bool? isDocumentsVerified,
    DateTime? createdAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      username: username ?? this.username,
      email: email ?? this.email,
      cnic: cnic ?? this.cnic,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      isFiler: isFiler ?? this.isFiler,
      isDocumentsVerified: isDocumentsVerified ?? this.isDocumentsVerified,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
