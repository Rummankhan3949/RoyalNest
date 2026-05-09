import '../models/payment_model.dart';
import '../models/payment_prediction_model.dart';

/// Deterministic Decision Tree simulation for client payment behavior.
class PaymentPredictionService {
  List<ClientPaymentPrediction> buildPredictions(List<PaymentModel> payments) {
    final now = DateTime.now();
    final grouped = <String, List<PaymentModel>>{};

    for (final payment in payments) {
      grouped
          .putIfAbsent(payment.clientId, () => <PaymentModel>[])
          .add(payment);
    }

    final predictions = <ClientPaymentPrediction>[];

    for (final entry in grouped.entries) {
      final clientPayments = entry.value;
      if (clientPayments.isEmpty) {
        continue;
      }

      final clientName = clientPayments.first.clientName.trim().isEmpty
          ? 'Client ${entry.key.substring(0, entry.key.length > 6 ? 6 : entry.key.length)}'
          : clientPayments.first.clientName;

      int latePayments = 0;
      final delays = <int>[];
      double remainingBalance = 0;
      int unpaid = 0;
      int partial = 0;
      int paid = 0;
      int totalPaidInstallments = 0;

      for (final payment in clientPayments) {
        remainingBalance += payment.remainingAmount;

        if (payment.status == 'paid') {
          paid++;
        } else if (payment.status == 'partial') {
          partial++;
        } else {
          unpaid++;
        }

        totalPaidInstallments += payment.paidInstallments;

        latePayments += _estimateLatePayments(payment, now);

        final delay = _estimateDelayDays(payment, now);
        if (delay > 0) {
          delays.add(delay);
        }
      }

      // Critical guard: no prediction before first paid installment.
      if (totalPaidInstallments < 1) {
        continue;
      }

      final delayDays = delays.isEmpty
          ? _fallbackDelayDays(unpaidCount: unpaid, partialCount: partial)
          : (delays.reduce((a, b) => a + b) / delays.length).round();

      final normalizedLatePayments = latePayments.clamp(0, 20);
      final prediction = _classify(
        latePayments: normalizedLatePayments,
        delayDays: delayDays,
      );

      predictions.add(
        ClientPaymentPrediction(
          clientId: entry.key,
          clientName: clientName,
          latePayments: normalizedLatePayments,
          delayDays: delayDays,
          remainingBalance: remainingBalance,
          label: prediction.$1,
          confidence: prediction.$2,
          totalPayments: clientPayments.length,
          unpaidPayments: unpaid,
          partialPayments: partial,
          paidPayments: paid,
        ),
      );
    }

    predictions.sort((a, b) {
      final scoreDiff = _riskScore(b.label) - _riskScore(a.label);
      if (scoreDiff != 0) {
        return scoreDiff;
      }
      return b.remainingBalance.compareTo(a.remainingBalance);
    });

    return predictions;
  }

  (PaymentRiskLabel, int) _classify({
    required int latePayments,
    required int delayDays,
  }) {
    // Decision Tree rules defined by project requirement.
    if (latePayments <= 1 && delayDays < 5) {
      return (PaymentRiskLabel.onTimePayer, 90);
    }

    if (latePayments <= 3 && delayDays < 10) {
      return (PaymentRiskLabel.mediumRisk, 65);
    }

    return (PaymentRiskLabel.highRisk, 85);
  }

  int _estimateLatePayments(PaymentModel payment, DateTime now) {
    var late = 0;

    if (payment.status == 'partial') {
      late += 1;
    } else if (payment.status == 'unpaid') {
      late += 2;
    }

    final dueDate = payment.nextDueDate;
    if (dueDate != null && dueDate.isBefore(now) && payment.status != 'paid') {
      final overdue = now.difference(dueDate).inDays;
      if (overdue >= 5) {
        late += 1;
      }
      if (overdue >= 15) {
        late += 1;
      }
    }

    return late;
  }

  int _estimateDelayDays(PaymentModel payment, DateTime now) {
    final dueDate = payment.nextDueDate;
    if (dueDate == null || payment.status == 'paid') {
      return 0;
    }

    if (!dueDate.isBefore(now)) {
      return 0;
    }

    return now.difference(dueDate).inDays;
  }

  int _fallbackDelayDays({
    required int unpaidCount,
    required int partialCount,
  }) {
    if (unpaidCount == 0 && partialCount == 0) {
      return 2;
    }
    if (unpaidCount == 0 && partialCount > 0) {
      return 6;
    }
    return 12;
  }

  int _riskScore(PaymentRiskLabel label) {
    switch (label) {
      case PaymentRiskLabel.highRisk:
        return 3;
      case PaymentRiskLabel.mediumRisk:
        return 2;
      case PaymentRiskLabel.onTimePayer:
        return 1;
    }
  }
}
