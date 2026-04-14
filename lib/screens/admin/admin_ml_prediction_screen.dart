import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/payment_model.dart';
import '../../models/payment_prediction_model.dart';
import '../../models/user_model.dart';
import '../../services/client_service.dart';
import '../../services/payment_prediction_service.dart';
import '../../services/payment_service.dart';
import 'admin_drawer.dart';

/// Admin-only ML prediction module for client payment behavior.
class AdminMLPredictionScreen extends StatefulWidget {
  const AdminMLPredictionScreen({super.key});

  @override
  State<AdminMLPredictionScreen> createState() =>
      _AdminMLPredictionScreenState();
}

class _AdminMLPredictionScreenState extends State<AdminMLPredictionScreen> {
  final PaymentService _paymentService = PaymentService();
  final ClientService _clientService = ClientService();
  final PaymentPredictionService _predictionService =
      PaymentPredictionService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Client Risk Insights',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: const AdminDrawer(),
      body: StreamBuilder<List<UserModel>>(
        stream: _clientService.getAllClients(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _MessageState(
              icon: Icons.error_outline,
              title: 'Unable to load registered clients',
              description: '${snapshot.error}',
            );
          }

          final registeredClients = snapshot.data ?? <UserModel>[];
          if (registeredClients.isEmpty) {
            return const _MessageState(
              icon: Icons.group_off_outlined,
              title: 'No registered clients',
              description:
                  'Client records will appear here after registration.',
            );
          }

          final registeredIds = registeredClients
              .map((e) => e.uid.trim())
              .where((e) => e.isNotEmpty)
              .toSet();
          final nameById = {
            for (final c in registeredClients) c.uid: c.username,
          };

          return StreamBuilder<List<PaymentModel>>(
            stream: _paymentService.getAllPayments(),
            builder: (context, paymentSnapshot) {
              if (paymentSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (paymentSnapshot.hasError) {
                return _MessageState(
                  icon: Icons.error_outline,
                  title: 'Unable to load payment records',
                  description: '${paymentSnapshot.error}',
                );
              }

              final payments = paymentSnapshot.data ?? <PaymentModel>[];
              final allPredictions = _predictionService.buildPredictions(
                payments,
              );
              final predictions = allPredictions
                  .where((p) => registeredIds.contains(p.clientId))
                  .map((p) {
                    final mappedName = nameById[p.clientId]?.trim() ?? '';
                    if (mappedName.isEmpty) {
                      return p;
                    }
                    return ClientPaymentPrediction(
                      clientId: p.clientId,
                      clientName: mappedName,
                      latePayments: p.latePayments,
                      delayDays: p.delayDays,
                      remainingBalance: p.remainingBalance,
                      label: p.label,
                      confidence: p.confidence,
                      totalPayments: p.totalPayments,
                      unpaidPayments: p.unpaidPayments,
                      partialPayments: p.partialPayments,
                      paidPayments: p.paidPayments,
                    );
                  })
                  .toList();

              if (predictions.isEmpty) {
                return const _MessageState(
                  icon: Icons.analytics_outlined,
                  title: 'No prediction data yet',
                  description:
                      'Registered clients have no payment history to evaluate.',
                );
              }

              final onTime = predictions
                  .where((e) => e.label == PaymentRiskLabel.onTimePayer)
                  .length;
              final medium = predictions
                  .where((e) => e.label == PaymentRiskLabel.mediumRisk)
                  .length;
              final high = predictions
                  .where((e) => e.label == PaymentRiskLabel.highRisk)
                  .length;

              return RefreshIndicator(
                onRefresh: () async {
                  setState(() {});
                },
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  children: [
                    _buildHeaderCard(),
                    const SizedBox(height: 14),
                    _SummaryGrid(
                      onTimeCount: onTime,
                      mediumCount: medium,
                      highCount: high,
                    ),
                    const SizedBox(height: 16),
                    ...predictions.map(_buildPredictionCard),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F3DAD), Color(0xFF0050FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppTheme.royalBlue.withValues(alpha: 0.24),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Align(
            alignment: Alignment.centerRight,
            child: Icon(Icons.admin_panel_settings, color: Colors.white),
          ),
          const SizedBox(height: 10),
          const Text(
            'Payment Risk Overview',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'A professional summary of client payment health for internal admin use.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 12,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPredictionCard(ClientPaymentPrediction prediction) {
    final labelColor = _labelColor(prediction.label);
    final lightColor = labelColor.withValues(alpha: 0.12);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppTheme.lightShadow,
        border: Border(left: BorderSide(color: labelColor, width: 5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: lightColor,
                child: Text(
                  _avatarText(prediction.clientName),
                  style: TextStyle(
                    color: labelColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      prediction.clientName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Payments: ${prediction.totalPayments}  '
                      'Paid: ${prediction.paidPayments}  '
                      'Partial: ${prediction.partialPayments}  '
                      'Unpaid: ${prediction.unpaidPayments}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: lightColor,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'ML Prediction',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MetricBadge(
                title: 'Late Payments',
                value: '${prediction.latePayments}',
              ),
              _MetricBadge(
                title: 'Delay Days',
                value: '${prediction.delayDays} days',
              ),
              _MetricBadge(
                title: 'Remaining',
                value: _formatAmount(prediction.remainingBalance),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: lightColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _labelIcon(prediction.label),
                        color: labelColor,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          prediction.labelText,
                          style: TextStyle(
                            color: labelColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Confidence ${prediction.confidence}%',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _labelColor(PaymentRiskLabel label) {
    switch (label) {
      case PaymentRiskLabel.onTimePayer:
        return AppTheme.successColor;
      case PaymentRiskLabel.mediumRisk:
        return AppTheme.warningColor;
      case PaymentRiskLabel.highRisk:
        return AppTheme.errorColor;
    }
  }

  IconData _labelIcon(PaymentRiskLabel label) {
    switch (label) {
      case PaymentRiskLabel.onTimePayer:
        return Icons.verified;
      case PaymentRiskLabel.mediumRisk:
        return Icons.warning_amber_rounded;
      case PaymentRiskLabel.highRisk:
        return Icons.gpp_bad;
    }
  }

  String _avatarText(String name) {
    final chunks = name.trim().split(RegExp(r'\s+'));
    if (chunks.isEmpty || chunks.first.isEmpty) {
      return 'C';
    }
    if (chunks.length == 1) {
      return chunks.first.substring(0, 1).toUpperCase();
    }
    return (chunks.first.substring(0, 1) + chunks[1].substring(0, 1))
        .toUpperCase();
  }

  String _formatAmount(double amount) {
    return 'PKR ${amount.toStringAsFixed(0)}';
  }
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({
    required this.onTimeCount,
    required this.mediumCount,
    required this.highCount,
  });

  final int onTimeCount;
  final int mediumCount;
  final int highCount;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 700;

        if (wide) {
          return Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  title: 'On-Time Payer',
                  count: onTimeCount,
                  color: AppTheme.successColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SummaryCard(
                  title: 'Medium Risk',
                  count: mediumCount,
                  color: AppTheme.warningColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SummaryCard(
                  title: 'High Risk',
                  count: highCount,
                  color: AppTheme.errorColor,
                ),
              ),
            ],
          );
        }

        return Column(
          children: [
            _SummaryCard(
              title: 'On-Time Payer',
              count: onTimeCount,
              color: AppTheme.successColor,
            ),
            const SizedBox(height: 8),
            _SummaryCard(
              title: 'Medium Risk',
              count: mediumCount,
              color: AppTheme.warningColor,
            ),
            const SizedBox(height: 8),
            _SummaryCard(
              title: 'High Risk',
              count: highCount,
              color: AppTheme.errorColor,
            ),
          ],
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.count,
    required this.color,
  });

  final String title;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppTheme.lightShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 42,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
          Text(
            '$count',
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricBadge extends StatelessWidget {
  const _MetricBadge({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.secondaryTextColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 58, color: Colors.grey.shade400),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.secondaryTextColor),
            ),
          ],
        ),
      ),
    );
  }
}
