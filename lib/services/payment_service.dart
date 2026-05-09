import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'dart:developer' as developer;

import '../models/payment_model.dart';
import '../models/notification_model.dart';
import '../models/receipt_model.dart';
import 'installment_service.dart';

/// Service for payment and installment management
class PaymentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'payments';
  final String _notificationCollection = 'notifications';
  final String _receiptCollection = 'payment_receipts';
  final String _jobsCollection = 'system_jobs';
  final String _reminderLogCollection = 'installment_reminder_logs';
  final InstallmentService _installmentService = InstallmentService();
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  bool isInstallmentDue(PaymentModel payment, {DateTime? now}) {
    if (payment.status == 'paid') return false;

    final due = payment.nextDueDate;
    if (due == null) return true;

    final currentDate = now ?? DateTime.now();
    final currentDay = DateTime(
      currentDate.year,
      currentDate.month,
      currentDate.day,
    );
    final dueDay = DateTime(due.year, due.month, due.day);

    return !currentDay.isBefore(dueDay);
  }

  /// Get all payments
  Stream<List<PaymentModel>> getAllPayments() {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => PaymentModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Future<PaymentModel?> getPaymentByClientAndPlot({
    required String clientId,
    required String plotId,
  }) async {
    try {
      var snapshot = await _firestore
          .collection(_collection)
          .where('clientId', isEqualTo: clientId)
          .where('plotId', isEqualTo: plotId)
          .limit(1)
          .get();

      // Backward-compatible fallback for documents that only store user_id.
      if (snapshot.docs.isEmpty) {
        snapshot = await _firestore
            .collection(_collection)
            .where('user_id', isEqualTo: clientId)
            .where('plotId', isEqualTo: plotId)
            .limit(1)
            .get();
      }

      if (snapshot.docs.isEmpty) return null;
      return PaymentModel.fromMap(
        snapshot.docs.first.data(),
        snapshot.docs.first.id,
      );
    } catch (e) {
      developer.log(
        'Error fetching payment by client and plot: $e',
        name: 'PaymentService',
      );
      return null;
    }
  }

  Future<PaymentModel?> getPaymentById(String paymentId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(paymentId).get();
      if (!doc.exists || doc.data() == null) return null;
      return PaymentModel.fromMap(doc.data()!, doc.id);
    } catch (e) {
      developer.log('Error fetching payment by id: $e', name: 'PaymentService');
      return null;
    }
  }

  /// Get payments by status
  Stream<List<PaymentModel>> getPaymentsByStatus(String status) {
    return _firestore
        .collection(_collection)
        .where('status', isEqualTo: status)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => PaymentModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  /// Get client's payments
  Stream<List<PaymentModel>> getClientPayments(String clientId) {
    return _firestore
        .collection(_collection)
        .where('clientId', isEqualTo: clientId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => PaymentModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  /// Get payments with upcoming due dates
  Stream<List<PaymentModel>> getUpcomingDuePayments() {
    final now = DateTime.now();
    final nextMonth = DateTime(now.year, now.month + 1, now.day);

    return _firestore.collection(_collection).snapshots().map((snapshot) {
      final duePayments = snapshot.docs
          .map((doc) => PaymentModel.fromMap(doc.data(), doc.id))
          .where(
            (payment) =>
                payment.status != 'paid' &&
                payment.nextDueDate != null &&
                !payment.nextDueDate!.isAfter(nextMonth),
          )
          .toList();

      duePayments.sort((left, right) {
        final leftDate = left.nextDueDate;
        final rightDate = right.nextDueDate;
        if (leftDate == null && rightDate == null) return 0;
        if (leftDate == null) return 1;
        if (rightDate == null) return -1;
        return leftDate.compareTo(rightDate);
      });

      return duePayments;
    });
  }

  /// Create new payment record
  Future<bool> createPayment(PaymentModel payment) async {
    try {
      final data = payment.toMap();

      // Keep both naming styles to satisfy rules and older queries.
      data['clientId'] = payment.clientId;
      data['user_id'] = payment.clientId;

      final docRef = await _firestore.collection(_collection).add(data);
      final createdDoc = await docRef.get();
      if (createdDoc.exists && createdDoc.data() != null) {
        final created = PaymentModel.fromMap(createdDoc.data()!, createdDoc.id);
        await _installmentService.syncInstallmentFromPayment(created);
      }

      return true;
    } catch (e) {
      developer.log('Error creating payment: $e', name: 'PaymentService');
      return false;
    }
  }

  /// Record installment payment and return the generated receipt number
  Future<String?> recordInstallment(
    String paymentId,
    InstallmentRecord installment, {
    String? stripePaymentIntentId,
  }) async {
    try {
      final paymentDoc = await _firestore
          .collection(_collection)
          .doc(paymentId)
          .get();
      if (!paymentDoc.exists) return null;

      final payment = PaymentModel.fromMap(paymentDoc.data()!, paymentDoc.id);

      if (!isInstallmentDue(payment)) {
        return null;
      }

      final newPaidInstallments = payment.paidInstallments + 1;
      final newPaidAmount = payment.paidAmount + installment.amount;
      final newRemainingAmount = payment.totalAmount - newPaidAmount;

      String newStatus = 'partial';
      if (newPaidInstallments >= payment.totalInstallments) {
        newStatus = 'paid';
      }

      // Calculate next due date
      DateTime? nextDueDate;
      if (newStatus != 'paid') {
        final now = DateTime.now();
        nextDueDate = DateTime(
          now.year,
          now.month + 1,
          5,
        ); // Due on 5th of next month
      }

      final updatedHistory = [...payment.installmentHistory, installment];

      await _firestore.collection(_collection).doc(paymentId).update({
        'paidInstallments': newPaidInstallments,
        'paidAmount': newPaidAmount,
        'remainingAmount': newRemainingAmount,
        'status': newStatus,
        'nextDueDate': nextDueDate != null
            ? Timestamp.fromDate(nextDueDate)
            : null,
        'installmentHistory': updatedHistory.map((e) => e.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final refreshedDoc = await _firestore
          .collection(_collection)
          .doc(paymentId)
          .get();
      if (refreshedDoc.exists && refreshedDoc.data() != null) {
        final refreshedPayment = PaymentModel.fromMap(
          refreshedDoc.data()!,
          refreshedDoc.id,
        );
        await _installmentService.syncInstallmentFromPayment(refreshedPayment);
      }

      // Generate and save receipt
      final receiptNumber =
          installment.receiptNumber ?? ReceiptModel.generateReceiptNumber();

      final receipt = ReceiptModel(
        id: '',
        receiptNumber: receiptNumber,
        paymentId: paymentId,
        clientId: payment.clientId,
        clientName: payment.clientName,
        clientEmail: '',
        plotDetails: payment.plotDetails,
        amount: installment.amount,
        paymentMethod: installment.paymentMethod,
        stripePaymentIntentId: stripePaymentIntentId,
        installmentNumber: newPaidInstallments,
        totalInstallments: payment.totalInstallments,
        totalPaidSoFar: newPaidAmount,
        totalAmount: payment.totalAmount,
        status: 'completed',
        paidDate: installment.paidDate,
      );

      await savePaymentReceipt(receipt);

      return receiptNumber;
    } catch (e) {
      return null;
    }
  }

  Future<String?> recordInstallmentForClientPlot({
    required String clientId,
    required String plotId,
    required double amount,
    required String paymentMethod,
    String? note,
    String? stripePaymentIntentId,
  }) async {
    final payment = await getPaymentByClientAndPlot(
      clientId: clientId,
      plotId: plotId,
    );
    if (payment == null) return null;

    final nextInstallmentNumber = payment.paidInstallments + 1;
    final installment = InstallmentRecord(
      installmentNumber: nextInstallmentNumber,
      amount: amount,
      paidDate: DateTime.now(),
      paymentMethod: paymentMethod,
      note: note,
    );

    return recordInstallment(
      payment.id,
      installment,
      stripePaymentIntentId: stripePaymentIntentId,
    );
  }

  /// Save a payment receipt to Firestore
  Future<String?> savePaymentReceipt(ReceiptModel receipt) async {
    try {
      final docRef = await _firestore
          .collection(_receiptCollection)
          .add(receipt.toMap());
      return docRef.id;
    } catch (e) {
      return null;
    }
  }

  /// Get receipt by receipt number
  Future<ReceiptModel?> getReceiptByNumber(String receiptNumber) async {
    try {
      final snapshot = await _firestore
          .collection(_receiptCollection)
          .where('receiptNumber', isEqualTo: receiptNumber)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;
      return ReceiptModel.fromMap(
        snapshot.docs.first.data(),
        snapshot.docs.first.id,
      );
    } catch (e) {
      return null;
    }
  }

  /// Get all receipts for a client
  Stream<List<ReceiptModel>> getClientReceipts(String clientId) {
    return _firestore
        .collection(_receiptCollection)
        .where('clientId', isEqualTo: clientId)
        .orderBy('paidDate', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ReceiptModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  /// Get receipts for a specific payment
  Future<List<ReceiptModel>> getPaymentReceipts(String paymentId) async {
    try {
      final snapshot = await _firestore
          .collection(_receiptCollection)
          .where('paymentId', isEqualTo: paymentId)
          .orderBy('installmentNumber')
          .get();

      return snapshot.docs
          .map((doc) => ReceiptModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Send payment reminder notification and return detailed status
  /// Status values: sent, in_app, duplicate, failed
  Future<String> sendPaymentReminderWithStatus(
    String paymentId,
    String message,
  ) async {
    try {
      final paymentDoc = await _firestore
          .collection(_collection)
          .doc(paymentId)
          .get();
      if (!paymentDoc.exists) return 'failed';

      final payment = PaymentModel.fromMap(paymentDoc.data()!, paymentDoc.id);
      final reminderKey = '${payment.id}_${_dateKey(DateTime.now())}';
      final reminderRef = _firestore
          .collection(_reminderLogCollection)
          .doc(reminderKey);

      var canWriteReminderLog = true;
      try {
        final reminderSnapshot = await reminderRef.get();
        if (reminderSnapshot.exists) {
          return 'duplicate';
        }
      } catch (e) {
        // Continue with in-app notification if reminder log access is blocked.
        canWriteReminderLog = false;
        developer.log(
          'Reminder log read failed, continuing without duplicate check: $e',
          name: 'PaymentService',
        );
      }

      bool pushSent = false;
      try {
        final callable = _functions.httpsCallable('sendInstallmentReminder');
        final response = await callable.call({
          'paymentId': payment.id,
          'userId': payment.clientId,
          'message': message,
        });
        final data = Map<String, dynamic>.from(response.data as Map);
        pushSent = data['success'] == true;
      } catch (e) {
        developer.log(
          'Cloud Function reminder failed, falling back to Firestore log: $e',
          name: 'PaymentService',
        );
      }

      final notification = NotificationModel(
        id: '',
        title: 'Installment Reminder',
        message: message,
        type: 'payment_reminder',
        targetUserId: payment.clientId,
        data: {
          'paymentId': paymentId,
          'delivery': pushSent ? 'push' : 'in_app',
        },
      );

      await _firestore
          .collection(_notificationCollection)
          .add(notification.toMap());

      if (canWriteReminderLog) {
        try {
          await reminderRef.set({
            'paymentId': payment.id,
            'userId': payment.clientId,
            'sentAt': FieldValue.serverTimestamp(),
            'message': message,
            'status': pushSent ? 'sent' : 'fallback',
          });
        } catch (e) {
          developer.log(
            'Reminder log write failed after notification send: $e',
            name: 'PaymentService',
          );
        }
      }

      return pushSent ? 'sent' : 'in_app';
    } catch (e) {
      developer.log(
        'sendPaymentReminderWithStatus failed: $e',
        name: 'PaymentService',
      );
      return 'failed';
    }
  }

  /// Backward-compatible boolean wrapper
  Future<bool> sendPaymentReminder(String paymentId, String message) async {
    final status = await sendPaymentReminderWithStatus(paymentId, message);
    return status == 'sent' || status == 'in_app';
  }

  /// Send bulk payment reminders for upcoming installments
  Future<int> sendBulkPaymentReminders() async {
    try {
      final now = DateTime.now();
      final reminderDate = DateTime(now.year, now.month + 1, 1);

      final snapshot = await _firestore.collection(_collection).get();

      int remindersSent = 0;

      for (var doc in snapshot.docs) {
        final payment = PaymentModel.fromMap(doc.data(), doc.id);

        if (payment.status != 'paid' &&
            payment.nextDueDate != null &&
            payment.nextDueDate!.isBefore(reminderDate)) {
          final message =
              'Dear ${payment.clientName}, your next installment of PKR ${payment.monthlyInstallment.toStringAsFixed(0)} for ${payment.plotDetails} is due on ${payment.nextDueDate!.day}/${payment.nextDueDate!.month}/${payment.nextDueDate!.year}. Please ensure timely payment.';

          final sent = await sendPaymentReminder(payment.id, message);
          if (sent) {
            remindersSent++;
          }
        }
      }

      return remindersSent;
    } catch (e) {
      return 0;
    }
  }

  Future<int> runReminderSweepIfDue() async {
    try {
      final jobRef = _firestore
          .collection(_jobsCollection)
          .doc('payment_reminders');
      final snapshot = await jobRef.get();
      final lastRun = (snapshot.data()?['lastRunAt'] as Timestamp?)?.toDate();
      final now = DateTime.now();

      final alreadyRanToday =
          lastRun != null &&
          lastRun.year == now.year &&
          lastRun.month == now.month &&
          lastRun.day == now.day;

      if (alreadyRanToday) return 0;

      final reminders = await sendBulkPaymentReminders();
      await jobRef.set({
        'lastRunAt': FieldValue.serverTimestamp(),
        'remindersSent': reminders,
      }, SetOptions(merge: true));

      return reminders;
    } catch (e) {
      developer.log(
        'Payment reminder sweep skipped: $e',
        name: 'PaymentService',
      );
      return 0;
    }
  }

  /// Update payment
  Future<bool> updatePayment(PaymentModel payment) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(payment.id)
          .update(payment.toMap());
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Delete payment
  Future<bool> deletePayment(String paymentId) async {
    try {
      await _firestore.collection(_collection).doc(paymentId).delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get payment statistics
  Future<Map<String, dynamic>> getPaymentStats() async {
    final snapshot = await _firestore.collection(_collection).get();

    double totalAmount = 0;
    double paidAmount = 0;
    double remainingAmount = 0;
    int paidCount = 0;
    int partialCount = 0;
    int unpaidCount = 0;

    for (var doc in snapshot.docs) {
      final data = doc.data();
      totalAmount += (data['totalAmount'] ?? 0).toDouble();
      paidAmount += (data['paidAmount'] ?? 0).toDouble();
      remainingAmount += (data['remainingAmount'] ?? 0).toDouble();

      final status = data['status'] ?? 'unpaid';
      switch (status) {
        case 'paid':
          paidCount++;
          break;
        case 'partial':
          partialCount++;
          break;
        default:
          unpaidCount++;
      }
    }

    return {
      'totalAmount': totalAmount,
      'paidAmount': paidAmount,
      'remainingAmount': remainingAmount,
      'paidCount': paidCount,
      'partialCount': partialCount,
      'unpaidCount': unpaidCount,
      'total': snapshot.docs.length,
    };
  }

  /// Get next upcoming payment for a client
  Future<Map<String, dynamic>?> getNextPaymentDue(String clientId) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('clientId', isEqualTo: clientId)
        .get();

    final eligiblePayments =
        snapshot.docs
            .map((doc) => doc.data())
            .where((data) => (data['status'] ?? 'unpaid').toString() != 'paid')
            .toList()
          ..sort((left, right) {
            final leftDate = (left['nextDueDate'] as Timestamp?)?.toDate();
            final rightDate = (right['nextDueDate'] as Timestamp?)?.toDate();

            if (leftDate == null && rightDate == null) return 0;
            if (leftDate == null) return 1;
            if (rightDate == null) return -1;
            return leftDate.compareTo(rightDate);
          });

    if (eligiblePayments.isEmpty) return null;

    final data = eligiblePayments.first;
    final nextDueDate = (data['nextDueDate'] as Timestamp?)?.toDate();
    return {
      'plotDetails': data['plotDetails'] ?? 'Plot Payment',
      'amount': (data['monthlyInstallment'] ?? 0).toDouble(),
      'dueDate': nextDueDate,
    };
  }

  /// Payment summary for a client
  Future<Map<String, double>> getClientPaymentSummary(String clientId) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('clientId', isEqualTo: clientId)
        .get();

    double total = 0;
    double paid = 0;
    double remaining = 0;

    for (var doc in snapshot.docs) {
      final data = doc.data();
      total += (data['totalAmount'] ?? 0).toDouble();
      paid += (data['paidAmount'] ?? 0).toDouble();
      remaining += (data['remainingAmount'] ?? 0).toDouble();
    }

    return {'total': total, 'paid': paid, 'remaining': remaining};
  }

  String _dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}$month$day';
  }
}
