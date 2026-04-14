import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/appointment_model.dart';
import '../models/notification_model.dart';
import '../core/constants/app_constants.dart';

/// Service for appointment management
class AppointmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'appointments';
  final String _notificationCollection = 'notifications';

  /// Get all appointments
  Stream<List<AppointmentModel>> getAllAppointments() {
    return _firestore
        .collection(_collection)
        .orderBy('appointmentDate', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => AppointmentModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  /// Get appointments by status
  Stream<List<AppointmentModel>> getAppointmentsByStatus(String status) {
    return _firestore
        .collection(_collection)
        .where('status', isEqualTo: status)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => AppointmentModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  /// Get client's appointments
  Stream<List<AppointmentModel>> getClientAppointments(
    String clientId, [
    String? status,
  ]) {
    Query<Map<String, dynamic>> query = _firestore
        .collection(_collection)
        .where('clientId', isEqualTo: clientId);

    if (status != null && status != 'all') {
      query = query.where('status', isEqualTo: status);
    }

    return query.snapshots().map(
      (snapshot) => snapshot.docs
          .map((doc) => AppointmentModel.fromMap(doc.data(), doc.id))
          .toList(),
    );
  }

  /// Get upcoming appointments
  Stream<List<AppointmentModel>> getUpcomingAppointments() {
    return _firestore
        .collection(_collection)
        .where('appointmentDate', isGreaterThanOrEqualTo: Timestamp.now())
        .where('status', isEqualTo: AppConstants.appointmentConfirmed)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => AppointmentModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  /// Get pending appointments
  Stream<List<AppointmentModel>> getPendingAppointments() {
    return _firestore
        .collection(_collection)
        .where('status', isEqualTo: AppConstants.appointmentPending)
        .orderBy('appointmentDate')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => AppointmentModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  /// Book new appointment
  Future<bool> bookAppointment(AppointmentModel appointment) async {
    try {
      await _firestore.collection(_collection).add(appointment.toMap());
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Confirm appointment
  Future<bool> confirmAppointment(
    String appointmentId, {
    String? adminNote,
  }) async {
    try {
      await _firestore.collection(_collection).doc(appointmentId).update({
        'status': AppConstants.appointmentConfirmed,
        'adminNote': adminNote,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Send notification to client
      final appointmentDoc = await _firestore
          .collection(_collection)
          .doc(appointmentId)
          .get();
      if (appointmentDoc.exists) {
        final appointment = AppointmentModel.fromMap(
          appointmentDoc.data()!,
          appointmentDoc.id,
        );
        await _sendAppointmentNotification(
          appointment,
          'Appointment Confirmed',
          'Your appointment on ${appointment.formattedDate} at ${appointment.timeSlot} has been confirmed.',
        );
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Reject appointment
  Future<bool> rejectAppointment(String appointmentId, String reason) async {
    try {
      await _firestore.collection(_collection).doc(appointmentId).update({
        'status': AppConstants.appointmentRejected,
        'rejectionReason': reason,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Send notification to client
      final appointmentDoc = await _firestore
          .collection(_collection)
          .doc(appointmentId)
          .get();
      if (appointmentDoc.exists) {
        final appointment = AppointmentModel.fromMap(
          appointmentDoc.data()!,
          appointmentDoc.id,
        );
        await _sendAppointmentNotification(
          appointment,
          'Appointment Rejected',
          'Your appointment on ${appointment.formattedDate} has been rejected. Reason: $reason',
        );
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Mark appointment as completed
  Future<bool> completeAppointment(String appointmentId) async {
    try {
      await _firestore.collection(_collection).doc(appointmentId).update({
        'status': AppConstants.appointmentCompleted,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Send notification to client
  Future<void> _sendAppointmentNotification(
    AppointmentModel appointment,
    String title,
    String message,
  ) async {
    final notification = NotificationModel(
      id: '',
      title: title,
      message: message,
      type: 'appointment',
      targetUserId: appointment.clientId,
      data: {'appointmentId': appointment.id},
    );

    await _firestore
        .collection(_notificationCollection)
        .add(notification.toMap());
  }

  /// Delete appointment
  Future<bool> deleteAppointment(String appointmentId) async {
    try {
      await _firestore.collection(_collection).doc(appointmentId).delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Cancel appointment (client side)
  Future<bool> cancelAppointment(String appointmentId) async {
    try {
      await _firestore.collection(_collection).doc(appointmentId).update({
        'status': AppConstants.appointmentCancelled,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Upcoming appointments count for dashboard
  Future<int> getUpcomingAppointmentsCount(String clientId) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('clientId', isEqualTo: clientId)
        .where('status', isEqualTo: AppConstants.appointmentConfirmed)
        .get();
    return snapshot.docs.length;
  }

  /// Get appointment counts
  Future<Map<String, int>> getAppointmentCounts() async {
    final snapshot = await _firestore.collection(_collection).get();

    int pending = 0;
    int confirmed = 0;
    int rejected = 0;
    int completed = 0;

    for (var doc in snapshot.docs) {
      final status = doc.data()['status'] ?? 'pending';
      switch (status) {
        case AppConstants.appointmentPending:
          pending++;
          break;
        case AppConstants.appointmentConfirmed:
          confirmed++;
          break;
        case AppConstants.appointmentRejected:
          rejected++;
          break;
        case AppConstants.appointmentCompleted:
          completed++;
          break;
      }
    }

    return {
      'pending': pending,
      'confirmed': confirmed,
      'rejected': rejected,
      'completed': completed,
      'total': snapshot.docs.length,
    };
  }
}
