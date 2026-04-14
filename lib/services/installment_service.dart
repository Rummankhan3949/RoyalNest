import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/installment_model.dart';
import '../models/payment_model.dart';

class InstallmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'installments';

  Stream<List<InstallmentModel>> getClientInstallments(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => InstallmentModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Stream<List<InstallmentModel>> getAllInstallments() {
    return _firestore
        .collection(_collection)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => InstallmentModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Future<void> syncInstallmentFromPayment(PaymentModel payment) async {
    final details = _buildInstallmentDetails(payment);
    final model = InstallmentModel(
      id: payment.id,
      paymentId: payment.id,
      userId: payment.clientId,
      userName: payment.clientName,
      propertyId: payment.plotId,
      propertyName: payment.plotDetails,
      totalInstallments: payment.totalInstallments,
      paidInstallments: payment.paidInstallments,
      currentInstallmentAmount: payment.monthlyInstallment,
      dueDate: payment.nextDueDate,
      installmentDetails: details,
      updatedAt: DateTime.now(),
    );

    await _firestore
        .collection(_collection)
        .doc(payment.id)
        .set(model.toMap(), SetOptions(merge: true));
  }

  List<InstallmentDetail> _buildInstallmentDetails(PaymentModel payment) {
    final total = payment.totalInstallments <= 0
        ? 1
        : payment.totalInstallments;
    final hasPending =
        payment.status != 'paid' && payment.paidInstallments < total;

    return List.generate(total, (index) {
      final number = index + 1;
      final status = number <= payment.paidInstallments
          ? InstallmentStatus.paid
          : (hasPending && number == payment.paidInstallments + 1)
          ? InstallmentStatus.pending
          : InstallmentStatus.upcoming;

      return InstallmentDetail(
        number: number,
        status: status,
        amount: payment.monthlyInstallment,
        dueDate: status == InstallmentStatus.pending
            ? payment.nextDueDate
            : null,
      );
    });
  }
}
