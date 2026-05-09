import 'dart:io';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

import '../core/constants/app_constants.dart';
import '../models/manual_payment_model.dart';
import '../models/payment_method_model.dart';
import '../services/payment_service.dart';

class ManualPaymentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final PaymentService _paymentService = PaymentService();
  String? lastError;

  static const String paymentsCollection = 'payments';
  static const String paymentMethodsCollection = 'payment_methods';
  static const String plotsCollection = 'plots';

  Stream<Map<String, dynamic>> getManualPaymentsSummary() {
    return getAllManualPayments(status: 'all').map((payments) {
      final pending = payments
          .where((p) => p.status == ManualPaymentStatus.pending)
          .length;
      final approved = payments
          .where((p) => p.status == ManualPaymentStatus.approved)
          .length;
      final rejected = payments
          .where((p) => p.status == ManualPaymentStatus.rejected)
          .length;

      final totalAmount = payments.fold<double>(
        0,
        (runningTotal, item) => runningTotal + item.amount,
      );
      final approvedAmount = payments
          .where((p) => p.status == ManualPaymentStatus.approved)
          .fold<double>(0, (runningTotal, item) => runningTotal + item.amount);

      return {
        'totalCount': payments.length,
        'pendingCount': pending,
        'approvedCount': approved,
        'rejectedCount': rejected,
        'totalAmount': totalAmount,
        'approvedAmount': approvedAmount,
      };
    });
  }

  Stream<List<PaymentMethodModel>> getActivePaymentMethods() {
    return _firestore.collection(paymentMethodsCollection).snapshots().map((
      snapshot,
    ) {
      final items = snapshot.docs
          .map((doc) => PaymentMethodModel.fromMap(doc.data(), doc.id))
          .where((m) => m.isActive)
          .toList();
      items.sort((a, b) {
        final at = a.createdAt?.millisecondsSinceEpoch ?? 0;
        final bt = b.createdAt?.millisecondsSinceEpoch ?? 0;
        return bt.compareTo(at);
      });
      return items;
    });
  }

  Future<List<PaymentMethodModel>> getActivePaymentMethodsOnce() async {
    final snapshot = await _firestore
        .collection(paymentMethodsCollection)
        .get();
    final items = snapshot.docs
        .map((doc) => PaymentMethodModel.fromMap(doc.data(), doc.id))
        .where((m) => m.isActive)
        .toList();

    items.sort((a, b) {
      final at = a.createdAt?.millisecondsSinceEpoch ?? 0;
      final bt = b.createdAt?.millisecondsSinceEpoch ?? 0;
      return bt.compareTo(at);
    });
    return items;
  }

  Stream<List<PaymentMethodModel>> getAllPaymentMethods() {
    return _firestore.collection(paymentMethodsCollection).snapshots().map((
      snapshot,
    ) {
      final items = snapshot.docs
          .map((doc) => PaymentMethodModel.fromMap(doc.data(), doc.id))
          .toList();
      items.sort((a, b) {
        final at = a.createdAt?.millisecondsSinceEpoch ?? 0;
        final bt = b.createdAt?.millisecondsSinceEpoch ?? 0;
        return bt.compareTo(at);
      });
      return items;
    });
  }

  Future<bool> addPaymentMethod(PaymentMethodModel model) async {
    try {
      lastError = null;
      final now = FieldValue.serverTimestamp();
      await _firestore.collection(paymentMethodsCollection).add({
        ...model.toMap(),
        // Keep both naming styles for backward compatibility.
        'methodName': model.methodName,
        'accountTitle': model.accountTitle,
        'accountNumber': model.accountNumber,
        'isActive': model.isActive,
        'createdAt': now,
        'updatedAt': now,
      });
      return true;
    } catch (e) {
      lastError = e.toString();
      return false;
    }
  }

  Future<bool> updatePaymentMethod(PaymentMethodModel model) async {
    try {
      lastError = null;
      await _firestore
          .collection(paymentMethodsCollection)
          .doc(model.id)
          .update({
            'method_name': model.methodName,
            'account_title': model.accountTitle,
            'account_number': model.accountNumber,
            'is_active': model.isActive,
            'methodName': model.methodName,
            'accountTitle': model.accountTitle,
            'accountNumber': model.accountNumber,
            'isActive': model.isActive,
            'updated_at': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
      return true;
    } catch (e) {
      lastError = e.toString();
      return false;
    }
  }

  Future<bool> togglePaymentMethod(String methodId, bool isActive) async {
    try {
      lastError = null;
      await _firestore
          .collection(paymentMethodsCollection)
          .doc(methodId)
          .update({
            'is_active': isActive,
            'isActive': isActive,
            'updated_at': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
      return true;
    } catch (e) {
      lastError = e.toString();
      return false;
    }
  }

  Future<bool> seedDefaultPaymentMethodsIfEmpty() async {
    try {
      lastError = null;
      final existing = await _firestore
          .collection(paymentMethodsCollection)
          .limit(1)
          .get();
      if (existing.docs.isNotEmpty) return true;

      final batch = _firestore.batch();
      final defaults = [
        const {
          'method_name': 'JazzCash',
          'account_title': 'Royal Nest Pvt Ltd',
          'account_number': '03001234567',
          'bank_id': 'RN-JAZZ-001',
          'society_name': 'Royal Nest',
          'is_active': true,
        },
        const {
          'method_name': 'EasyPaisa',
          'account_title': 'Royal Nest Pvt Ltd',
          'account_number': '03111234567',
          'bank_id': 'RN-EASY-002',
          'society_name': 'Royal Nest',
          'is_active': true,
        },
        const {
          'method_name': 'Bank Transfer',
          'account_title': 'Royal Nest Pvt Ltd',
          'account_number': 'PK36SCBL0000001123456702',
          'bank_id': 'RN-BANK-003',
          'society_name': 'Royal Nest',
          'is_active': true,
        },
      ];

      for (final item in defaults) {
        final doc = _firestore.collection(paymentMethodsCollection).doc();
        batch.set(doc, {
          ...item,
          'methodName': item['method_name'],
          'accountTitle': item['account_title'],
          'accountNumber': item['account_number'],
          'bankId': item['bank_id'],
          'societyName': item['society_name'],
          'isActive': item['is_active'],
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      return true;
    } catch (e) {
      lastError = e.toString();
      return false;
    }
  }

  Future<String?> uploadPaymentProof({
    required File file,
    required String userId,
    required String propertyId,
    void Function(double progress)? onProgress,
  }) async {
    try {
      lastError = null;
      if (!file.existsSync()) {
        lastError = 'Selected proof image was not found on device.';
        return null;
      }

      final timestampMs = DateTime.now().millisecondsSinceEpoch;
      final publicId = '${userId}_${propertyId}_$timestampMs';
      final folder = 'payment_proofs/$userId/$propertyId';

      final cloudName = AppConstants.cloudinaryCloudName.trim();
      final uploadPreset = AppConstants.cloudinaryUploadPreset.trim();
      if (cloudName.isEmpty ||
          uploadPreset.isEmpty ||
          cloudName == 'YOUR_CLOUD_NAME' ||
          uploadPreset == 'YOUR_UNSIGNED_UPLOAD_PRESET') {
        lastError =
            'Cloudinary is not configured. Set cloudName and uploadPreset in AppConstants.';
        return null;
      }

      onProgress?.call(0.1);
      onProgress?.call(0.35);
      final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
      );
      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = uploadPreset
        ..fields['folder'] = folder
        ..fields['public_id'] = publicId
        ..files.add(await http.MultipartFile.fromPath('file', file.path));

      final response = await request.send();
      final body = await response.stream.bytesToString();

      if (response.statusCode < 200 || response.statusCode >= 300) {
        String message = 'Cloudinary upload failed (${response.statusCode}).';
        try {
          final json = jsonDecode(body) as Map<String, dynamic>;
          final error = json['error'];
          if (error is Map && error['message'] != null) {
            message = error['message'].toString();
          }
        } catch (_) {
          // Keep fallback message when response body is not valid JSON.
        }
        lastError = message;
        return null;
      }

      final decoded = jsonDecode(body) as Map<String, dynamic>;
      final url = decoded['secure_url']?.toString();
      if (url == null || url.isEmpty) {
        lastError = 'Cloudinary upload succeeded but URL was missing.';
        return null;
      }

      onProgress?.call(1);
      return url;
    } catch (e) {
      lastError = 'Upload failed: $e';
      return null;
    }
  }

  Future<bool> createManualPayment(ManualPaymentModel payment) async {
    try {
      final data = payment.toMap();
      data['method'] = payment.paymentMethod;
      data['proofUrl'] = payment.screenshotUrl;
      data['status'] = payment.status;
      data['timestamp'] = FieldValue.serverTimestamp();

      await _firestore.collection(paymentsCollection).add(data);
      return true;
    } catch (_) {
      return false;
    }
  }

  Stream<List<ManualPaymentModel>> getMyPayments(String userId) {
    return _firestore
        .collection(paymentsCollection)
        .where('user_id', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final items = snapshot.docs
              .map((doc) => ManualPaymentModel.fromMap(doc.data(), doc.id))
              .where((p) => p.paymentMethod.trim().isNotEmpty)
              .toList();
          items.sort((a, b) {
            final at = a.createdAt?.millisecondsSinceEpoch ?? 0;
            final bt = b.createdAt?.millisecondsSinceEpoch ?? 0;
            return bt.compareTo(at);
          });
          return items;
        });
  }

  Stream<List<ManualPaymentModel>> getAllManualPayments({String? status}) {
    return _firestore.collection(paymentsCollection).snapshots().map((
      snapshot,
    ) {
      var items = snapshot.docs
          .map((doc) => ManualPaymentModel.fromMap(doc.data(), doc.id))
          .where((p) => p.paymentMethod.trim().isNotEmpty)
          .toList();

      if (status != null && status != 'all') {
        items = items.where((p) => p.status == status).toList();
      }

      items.sort((a, b) {
        final at = a.createdAt?.millisecondsSinceEpoch ?? 0;
        final bt = b.createdAt?.millisecondsSinceEpoch ?? 0;
        return bt.compareTo(at);
      });

      return items;
    });
  }

  Stream<ManualPaymentModel?> getPaymentById(String paymentId) {
    return _firestore
        .collection(paymentsCollection)
        .doc(paymentId)
        .snapshots()
        .map((doc) {
          if (!doc.exists || doc.data() == null) return null;
          return ManualPaymentModel.fromMap(doc.data()!, doc.id);
        });
  }

  Future<bool> approvePayment(String paymentId) async {
    try {
      ManualPaymentModel? approvedPayment;
      final approved = await _firestore.runTransaction<bool>((
        transaction,
      ) async {
        final paymentRef = _firestore
            .collection(paymentsCollection)
            .doc(paymentId);
        final paymentSnap = await transaction.get(paymentRef);

        if (!paymentSnap.exists || paymentSnap.data() == null) {
          return false;
        }

        final payment = ManualPaymentModel.fromMap(
          paymentSnap.data()!,
          paymentId,
        );
        approvedPayment = payment;
        final plotRef = _firestore
            .collection(plotsCollection)
            .doc(payment.propertyId);
        final plotSnap = await transaction.get(plotRef);

        if (!plotSnap.exists || plotSnap.data() == null) {
          return false;
        }

        final plotData = plotSnap.data()!;
        final currentStatus = (plotData['status'] ?? '').toString();
        final currentOwner = (plotData['ownerId'] ?? '').toString();

        if (currentStatus == 'sold' &&
            currentOwner.isNotEmpty &&
            currentOwner != payment.userId) {
          return false;
        }

        transaction.update(paymentRef, {
          'status': ManualPaymentStatus.approved,
          'rejection_reason': null,
          'updated_at': FieldValue.serverTimestamp(),
        });

        transaction.update(plotRef, {
          'status': 'sold',
          'ownerId': payment.userId,
          'ownerName': payment.userName,
          'soldAt': FieldValue.serverTimestamp(),
        });

        return true;
      });

      if (approved && approvedPayment != null) {
        final installmentNote = approvedPayment!.installmentType != null
            ? 'Approved manual ${approvedPayment!.installmentType} payment proof.'
            : 'Approved manual installment payment proof.';

        await _paymentService.recordInstallmentForClientPlot(
          clientId: approvedPayment!.userId,
          plotId: approvedPayment!.propertyId,
          amount: approvedPayment!.amount,
          paymentMethod: 'Manual Payment (Verified)',
          note: installmentNote,
        );

        await _firestore.collection('notifications').add({
          'title': 'Manual Payment Approved',
          'message':
              'Your manual payment for ${approvedPayment!.propertyName} has been verified. Installment record is updated.',
          'type': 'payment',
          'targetUserId': approvedPayment!.userId,
          'isRead': false,
          'data': {
            'propertyId': approvedPayment!.propertyId,
            'linkedPaymentId': approvedPayment!.linkedPaymentId,
          },
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      return approved;
    } catch (_) {
      return false;
    }
  }

  Future<bool> rejectPayment(String paymentId, String reason) async {
    try {
      await _firestore.collection(paymentsCollection).doc(paymentId).update({
        'status': ManualPaymentStatus.rejected,
        'rejection_reason': reason,
        'updated_at': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (_) {
      return false;
    }
  }
}
