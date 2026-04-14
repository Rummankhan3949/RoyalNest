import 'package:cloud_firestore/cloud_firestore.dart';

/// Appointment model for client-admin meetings
class AppointmentModel {
  final String id;
  final String clientId;
  final String clientName;
  final String clientEmail;
  final String clientPhone;
  final String
  purpose; // Plot Visit, Payment Discussion, Document Submission, Other
  final String? plotId;
  final String? plotDetails;
  final DateTime appointmentDate;
  final String timeSlot; // e.g., "10:00 AM - 11:00 AM"
  final String status; // pending, confirmed, rejected, completed
  final String? adminNote;
  final String? rejectionReason;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AppointmentModel({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.clientEmail,
    required this.clientPhone,
    required this.purpose,
    this.plotId,
    this.plotDetails,
    required this.appointmentDate,
    required this.timeSlot,
    this.status = 'pending',
    this.adminNote,
    this.rejectionReason,
    this.createdAt,
    this.updatedAt,
  });

  String get dayName {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return days[appointmentDate.weekday - 1];
  }

  String get formattedDate {
    return '${appointmentDate.day}/${appointmentDate.month}/${appointmentDate.year}';
  }

  factory AppointmentModel.fromMap(Map<String, dynamic> map, String docId) {
    return AppointmentModel(
      id: docId,
      clientId: map['clientId'] ?? '',
      clientName: map['clientName'] ?? '',
      clientEmail: map['clientEmail'] ?? '',
      clientPhone: map['clientPhone'] ?? '',
      purpose: map['purpose'] ?? '',
      plotId: map['plotId'],
      plotDetails: map['plotDetails'],
      appointmentDate: (map['appointmentDate'] as Timestamp).toDate(),
      timeSlot: map['timeSlot'] ?? '',
      status: map['status'] ?? 'pending',
      adminNote: map['adminNote'],
      rejectionReason: map['rejectionReason'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'clientId': clientId,
      'clientName': clientName,
      'clientEmail': clientEmail,
      'clientPhone': clientPhone,
      'purpose': purpose,
      'plotId': plotId,
      'plotDetails': plotDetails,
      'appointmentDate': Timestamp.fromDate(appointmentDate),
      'timeSlot': timeSlot,
      'status': status,
      'adminNote': adminNote,
      'rejectionReason': rejectionReason,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  AppointmentModel copyWith({
    String? id,
    String? clientId,
    String? clientName,
    String? clientEmail,
    String? clientPhone,
    String? purpose,
    String? plotId,
    String? plotDetails,
    DateTime? appointmentDate,
    String? timeSlot,
    String? status,
    String? adminNote,
    String? rejectionReason,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppointmentModel(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      clientEmail: clientEmail ?? this.clientEmail,
      clientPhone: clientPhone ?? this.clientPhone,
      purpose: purpose ?? this.purpose,
      plotId: plotId ?? this.plotId,
      plotDetails: plotDetails ?? this.plotDetails,
      appointmentDate: appointmentDate ?? this.appointmentDate,
      timeSlot: timeSlot ?? this.timeSlot,
      status: status ?? this.status,
      adminNote: adminNote ?? this.adminNote,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
