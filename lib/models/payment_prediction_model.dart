enum PaymentRiskLabel { onTimePayer, mediumRisk, highRisk }

class ClientPaymentPrediction {
  const ClientPaymentPrediction({
    required this.clientId,
    required this.clientName,
    required this.latePayments,
    required this.delayDays,
    required this.remainingBalance,
    required this.label,
    required this.confidence,
    required this.totalPayments,
    required this.unpaidPayments,
    required this.partialPayments,
    required this.paidPayments,
  });

  final String clientId;
  final String clientName;
  final int latePayments;
  final int delayDays;
  final double remainingBalance;
  final PaymentRiskLabel label;
  final int confidence;
  final int totalPayments;
  final int unpaidPayments;
  final int partialPayments;
  final int paidPayments;

  String get labelText {
    switch (label) {
      case PaymentRiskLabel.onTimePayer:
        return 'On-Time Payer';
      case PaymentRiskLabel.mediumRisk:
        return 'Medium Risk';
      case PaymentRiskLabel.highRisk:
        return 'High Risk';
    }
  }
}
