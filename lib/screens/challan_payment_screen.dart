import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../models/user_model.dart';
import '../models/plot_model.dart';
import '../models/installment_model.dart';
import '../models/payment_method_model.dart';
import '../services/document_service.dart';
import '../services/manual_payment_service.dart';
import '../widgets/challan_download_widget.dart';

/// Example payment screen with challan functionality
class ChallanPaymentScreen extends StatefulWidget {
  final UserModel user;
  final PlotModel plot;
  final InstallmentModel installment;
  final double amount;

  const ChallanPaymentScreen({
    Key? key,
    required this.user,
    required this.plot,
    required this.installment,
    required this.amount,
  }) : super(key: key);

  @override
  State<ChallanPaymentScreen> createState() => _ChallanPaymentScreenState();
}

class _ChallanPaymentScreenState extends State<ChallanPaymentScreen>
    with SingleTickerProviderStateMixin {
  final DocumentService _documentService = DocumentService();
  final ManualPaymentService _manualPaymentService = ManualPaymentService();
  late TabController _tabController;
  bool _challanGenerated = false;
  PaymentMethodModel? _bankMethod;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkChallanStatus();
    _loadBankMethod();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _checkChallanStatus() async {
    final isChallanGenerated = await _documentService.isChallanGenerated(
      widget.user.uid,
      widget.plot.id,
      widget.installment.totalInstallments -
          widget.installment.upcomingInstallments,
    );

    setState(() {
      _challanGenerated = isChallanGenerated;
    });
  }

  Future<void> _loadBankMethod() async {
    try {
      final methods = await _manualPaymentService.getActivePaymentMethodsOnce();
      if (!mounted) return;
      setState(() {
        _bankMethod = methods.isNotEmpty ? methods.first : null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _bankMethod = null);
    }
  }

  void _handleChallanSuccess() {
    setState(() {
      _challanGenerated = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✓ Challan generated successfully'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _handleChallanError(String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✗ Error: $error'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Options'),
        elevation: 0,
        backgroundColor: AppTheme.royalBlue,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Summary Card
            _buildSummaryCard(),
            const SizedBox(height: 16),
            // Tab Bar
            Container(
              color: Colors.grey.shade100,
              child: TabBar(
                controller: _tabController,
                labelColor: Colors.blue.shade700,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Colors.blue.shade700,
                tabs: const [
                  Tab(text: 'Manual Payment (Challan)'),
                  Tab(text: 'History'),
                ],
              ),
            ),
            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Manual Payment Tab
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: ChallanDownloadWidget(
                      user: widget.user,
                      plot: widget.plot,
                      installment: widget.installment,
                      amount: widget.amount,
                      bankName: _bankMethod?.methodName ?? 'Royal Nest Bank',
                      accountTitle:
                          _bankMethod?.accountTitle ??
                          'Royal Nest Properties (Pvt) Ltd',
                      accountNumber:
                          _bankMethod?.accountNumber ?? '12345-67890-1',
                      bankId: _bankMethod?.bankId,
                      iban: 'PK93ABCD0123456789012345',
                      onSuccess: _handleChallanSuccess,
                      onError: _handleChallanError,
                    ),
                  ),
                  // History Tab
                  ChallanHistoryWidget(
                    userId: widget.user.uid,
                    documentService: _documentService,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.royalBlue, Color(0xFF0A6BFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade200,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Installment #${widget.installment.totalInstallments - widget.installment.upcomingInstallments}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'PKR ${widget.amount.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _challanGenerated ? Icons.check_circle : Icons.receipt,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Divider
          Container(height: 1, color: Colors.white.withOpacity(0.2)),
          const SizedBox(height: 12),
          // Property Info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildPropertyInfoColumn('Project', widget.plot.society),
              _buildPropertyInfoColumn('Plot No', widget.plot.plotNumber),
              _buildPropertyInfoColumn('Size', widget.plot.size),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyInfoColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// Quick integration example - use in your existing payment screen
class ChallanQuickIntegrationExample extends StatelessWidget {
  final UserModel user;
  final PlotModel plot;
  final InstallmentModel installment;

  const ChallanQuickIntegrationExample({
    Key? key,
    required this.user,
    required this.plot,
    required this.installment,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChallanDownloadWidget(
      user: user,
      plot: plot,
      installment: installment,
      amount: installment.currentInstallmentAmount,
      onSuccess: () {
        print('Challan downloaded successfully');
      },
      onError: (error) {
        print('Error downloading challan: $error');
      },
    );
  }
}
