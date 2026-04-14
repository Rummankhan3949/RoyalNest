import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/app_state_provider.dart';
import '../../models/plot_model.dart';
import '../../models/user_model.dart';
import '../../models/payment_model.dart';
import '../../models/payment_method_model.dart';
import '../../services/plot_service.dart';
import '../../services/payment_service.dart';
import '../../services/manual_payment_service.dart';
import 'client_manual_payment_screen.dart';
import 'client_drawer.dart';

/// Client Plots Screen - View and browse available plots by society
class ClientPlotsScreen extends StatefulWidget {
  const ClientPlotsScreen({super.key});

  @override
  State<ClientPlotsScreen> createState() => _ClientPlotsScreenState();
}

class _ClientPlotsScreenState extends State<ClientPlotsScreen> {
  final PlotService _plotService = PlotService();
  final PaymentService _paymentService = PaymentService();
  final ManualPaymentService _manualPaymentService = ManualPaymentService();
  String get userId => FirebaseAuth.instance.currentUser?.uid ?? '';
  late String? _selectedSociety;
  bool _showOwnedOnly = false;
  final bool _isProcessing = false;
  UserModel? _currentUser;
  bool _isLoadingUser = true;

  @override
  void initState() {
    super.initState();
    _selectedSociety = AppStateProvider.getSelectedSociety();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    if (userId.isEmpty) {
      if (!mounted) return;
      setState(() {
        _currentUser = null;
        _isLoadingUser = false;
      });
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      if (!mounted) return;
      setState(() {
        _currentUser = doc.exists && doc.data() != null
            ? UserModel.fromMap(doc.data()!)
            : null;
        _isLoadingUser = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingUser = false);
    }
  }

  bool get _isDocumentVerified => _currentUser?.isDocumentsVerified == true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.royalBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Available Plots',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: const ClientDrawer(),
      body: Column(
        children: [
          // Society Filter and Toggle
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Society Filter
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: AppStateProvider.getSocietyOptions()
                        .map(
                          (society) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(society),
                              selected: _selectedSociety == society,
                              onSelected: (selected) {
                                setState(() {
                                  _selectedSociety = selected ? society : null;
                                  AppStateProvider.setSelectedSociety(
                                    _selectedSociety,
                                  );
                                });
                              },
                              backgroundColor: Colors.grey[200],
                              selectedColor: AppTheme.lightBlue,
                              labelStyle: TextStyle(
                                color: _selectedSociety == society
                                    ? AppTheme.royalBlue
                                    : Colors.black87,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: 8),
                // Toggle for owned plots
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'My Plots Only',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  value: _showOwnedOnly,
                  onChanged: (value) {
                    setState(() => _showOwnedOnly = value);
                  },
                  activeThumbColor: AppTheme.royalBlue,
                ),
              ],
            ),
          ),
          // Plots List
          Expanded(child: _buildPlotsList()),
        ],
      ),
    );
  }

  Widget _buildPlotsList() {
    return FutureBuilder<List<PlotModel>>(
      future: _selectedSociety != null
          ? _plotService.getPlotsBySociety(_selectedSociety!).first
          : _plotService.getAvailablePlots().first,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
                const SizedBox(height: 12),
                Text(
                  'Error loading plots',
                  style: TextStyle(color: Colors.red[600]),
                ),
              ],
            ),
          );
        }

        List<PlotModel> plots = snapshot.data ?? [];

        // Filter by owner if needed
        if (_showOwnedOnly) {
          plots = plots.where((p) => p.ownerId == userId).toList();
        }

        if (plots.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.landscape_outlined,
                  size: 80,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  _showOwnedOnly ? 'No Owned Plots' : 'No Plots Available',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _showOwnedOnly
                      ? 'Your purchased plots will appear here'
                      : 'No plots available in this society',
                  style: TextStyle(color: Colors.grey.shade500),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            await _loadCurrentUser();
            setState(() {});
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: plots.length,
            itemBuilder: (context, index) => _buildPlotCard(plots[index]),
          ),
        );
      },
    );
  }

  Widget _buildPlotCard(PlotModel plot) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showPlotDetails(plot),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with society and status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plot.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          plot.society,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.royalBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusChip(plot.status),
                ],
              ),
              const SizedBox(height: 8),
              // Plot details grid
              Row(
                children: [
                  Expanded(child: _buildDetailItem('📐 Size', plot.size)),
                  Expanded(
                    child: _buildDetailItem('🏘️ Block', plot.blockName),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildDetailItem('📍 Plot #', plot.plotNumber),
                  ),
                  Expanded(child: _buildDetailItem('🏠 Type', plot.plotType)),
                ],
              ),
              const SizedBox(height: 12),
              // Price section
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.lightBlue.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Price:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      plot.formattedPrice,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.royalBlue,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Description
              Text(
                plot.description,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.royalBlue,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      onPressed: () => _showPlotDetails(plot),
                      icon: const Icon(Icons.info_outline, size: 16),
                      label: const Text(
                        'View Details',
                        style: TextStyle(fontSize: 12, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (plot.status == 'available')
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        onPressed: _isLoadingUser
                            ? null
                            : () => _onBuyPlotPressed(plot),
                        icon: const Icon(Icons.shopping_bag, size: 16),
                        label: const Text(
                          'Buy Plot',
                          style: TextStyle(fontSize: 12, color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String status) {
    Color backgroundColor;
    Color textColor;
    IconData icon;

    switch (status) {
      case 'available':
        backgroundColor = Colors.green[50]!;
        textColor = Colors.green[700]!;
        icon = Icons.check_circle;
        break;
      case 'sold':
        backgroundColor = Colors.red[50]!;
        textColor = Colors.red[700]!;
        icon = Icons.block;
        break;
      case 'reserved':
        backgroundColor = Colors.orange[50]!;
        textColor = Colors.orange[700]!;
        icon = Icons.schedule;
        break;
      default:
        backgroundColor = Colors.grey[200]!;
        textColor = Colors.grey[700]!;
        icon = Icons.help;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  void _showPlotDetails(PlotModel plot) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.8,
        maxChildSize: 0.95,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            plot.title,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            plot.society,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppTheme.royalBlue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildStatusChip(plot.status),
                  ],
                ),
                const SizedBox(height: 20),
                // Details Section
                _buildDetailSection('Basic Information', [
                  ('Plot Number', plot.plotNumber),
                  ('Block/Sector', plot.blockName),
                  ('Size', plot.size),
                  ('Type', plot.plotType),
                  ('Location', plot.location),
                ]),
                const SizedBox(height: 16),
                // Price Section
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.lightBlue.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.royalBlue, width: 1),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Price:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        plot.formattedPrice,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.royalBlue,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Description
                const Text(
                  'Description',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  plot.description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 20),
                if (!_isDocumentVerified) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.shade300),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.amber),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Document verification is required before plot purchase.',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                // Action Buttons
                if (plot.status == 'available') ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: _isProcessing || _isLoadingUser
                          ? null
                          : () => _onBuyPlotPressed(plot),
                      icon: _isProcessing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.shopping_bag),
                      label: Text(
                        _isProcessing
                            ? 'Processing...'
                            : _isDocumentVerified
                            ? 'Proceed to Payment'
                            : 'Verify Documents to Buy',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onBuyPlotPressed(PlotModel plot) {
    if (!_isDocumentVerified) {
      _showVerificationRequiredDialog();
      return;
    }
    _showPurchaseOptions(plot);
  }

  Future<void> _showVerificationRequiredDialog() async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Verification Required'),
        content: const Text(
          'You can view plots, but purchase is locked until your documents are verified by admin.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushNamed(context, '/client-documents');
            },
            child: const Text('Go to Documents'),
          ),
        ],
      ),
    );
  }

  int _extractPercent(dynamic raw, int fallback) {
    if (raw == null) return fallback;
    final cleaned = raw.toString().replaceAll('%', '').trim();
    return int.tryParse(cleaned) ?? fallback;
  }

  Future<void> _showPurchaseOptions(PlotModel plot) async {
    bool isFiler = _currentUser?.isFiler ?? true;
    int installments = isFiler ? 15 : 12;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final plan = isFiler
                ? AppConstants.filerPlan
                : AppConstants.nonFilerPlan;
            final maxInstallments =
                (plan['months'] as int?) ?? (isFiler ? 36 : 30);
            final minInstallments = isFiler ? 15 : 12;
            if (installments < minInstallments) installments = minInstallments;
            if (installments > maxInstallments) installments = maxInstallments;

            final bookingPercent = _extractPercent(plan['booking'], 10);
            final confirmationPercent = _extractPercent(
              plan['confirmation'],
              15,
            );

            final bookingAmount = plot.price * (bookingPercent / 100);
            final confirmationAmount = plot.price * (confirmationPercent / 100);
            final remainingAfterUpfront =
                (plot.price - bookingAmount - confirmationAmount)
                    .clamp(0, double.infinity)
                    .toDouble();
            final monthlyInstallment = installments > 0
                ? remainingAfterUpfront / installments
                : remainingAfterUpfront;
            final firstInstallment = bookingAmount;

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Choose Payment Plan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment<bool>(value: true, label: Text('Filer')),
                        ButtonSegment<bool>(
                          value: false,
                          label: Text('Non-Filer'),
                        ),
                      ],
                      selected: {isFiler},
                      onSelectionChanged: (value) {
                        setModalState(() {
                          isFiler = value.first;
                          installments = isFiler ? 15 : 12;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Installments: $installments (Min ${isFiler ? 15 : 12}, Max $maxInstallments)',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Slider(
                      value: installments.toDouble(),
                      min: minInstallments.toDouble(),
                      max: maxInstallments.toDouble(),
                      divisions: maxInstallments - minInstallments,
                      label: '$installments',
                      onChanged: (v) => setModalState(() {
                        installments = v.round();
                      }),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.lightBlue.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Total: ${plot.formattedPrice}'),
                          Text(
                            'Booking ($bookingPercent%): PKR ${bookingAmount.toStringAsFixed(0)}',
                          ),
                          Text(
                            'First Installment Due Now: PKR ${firstInstallment.toStringAsFixed(0)}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            'Confirmation ($confirmationPercent%): PKR ${confirmationAmount.toStringAsFixed(0)}',
                          ),
                          Text(
                            'Monthly Installment: PKR ${monthlyInstallment.toStringAsFixed(0)}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          Navigator.pop(ctx);
                          await _startOnlinePaymentFlow(
                            plot: plot,
                            isFiler: isFiler,
                            installments: installments,
                            bookingAmount: firstInstallment,
                            confirmationAmount: confirmationAmount,
                            monthlyInstallment: monthlyInstallment,
                          );
                        },
                        icon: const Icon(Icons.arrow_forward_rounded),
                        label: const Text('Proceed to Payment'),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<PaymentModel?> _ensurePaymentPlan({
    required PlotModel plot,
    required int installments,
    required double bookingAmount,
    required double confirmationAmount,
    required double monthlyInstallment,
  }) async {
    final existing = await _paymentService.getPaymentByClientAndPlot(
      clientId: userId,
      plotId: plot.id,
    );
    if (existing != null) return existing;

    final payment = PaymentModel(
      id: '',
      clientId: userId,
      clientName: FirebaseAuth.instance.currentUser?.displayName ?? 'Client',
      plotId: plot.id,
      plotDetails: '${plot.size} - ${plot.blockName} - ${plot.society}',
      totalAmount: plot.price,
      bookingAmount: bookingAmount,
      confirmationAmount: confirmationAmount,
      monthlyInstallment: monthlyInstallment,
      totalInstallments: installments,
      remainingAmount: plot.price,
      status: 'unpaid',
      nextDueDate: DateTime(DateTime.now().year, DateTime.now().month + 1, 5),
    );

    final created = await _paymentService.createPayment(payment);
    if (!created) return null;

    return _paymentService.getPaymentByClientAndPlot(
      clientId: userId,
      plotId: plot.id,
    );
  }

  Future<void> _startOnlinePaymentFlow({
    required PlotModel plot,
    required bool isFiler,
    required int installments,
    required double bookingAmount,
    required double confirmationAmount,
    required double monthlyInstallment,
  }) async {
    await _openPaymentTransactionPage(
      plot: plot,
      isFiler: isFiler,
      installments: installments,
      bookingAmount: bookingAmount,
      confirmationAmount: confirmationAmount,
      monthlyInstallment: monthlyInstallment,
      initialMode: 'online',
    );
  }

  Future<void> _openPaymentTransactionPage({
    required PlotModel plot,
    required bool isFiler,
    required int installments,
    required double bookingAmount,
    required double confirmationAmount,
    required double monthlyInstallment,
    required String initialMode,
  }) async {
    final payment = await _ensurePaymentPlan(
      plot: plot,
      installments: installments,
      bookingAmount: bookingAmount,
      confirmationAmount: confirmationAmount,
      monthlyInstallment: monthlyInstallment,
    );

    if (!mounted) return;
    if (payment == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not initialize payment plan.')),
      );
      return;
    }

    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ClientManualPaymentScreen(
          propertyId: plot.id,
          propertyName: plot.title,
          amount: bookingAmount,
          linkedPaymentId: payment.id,
          installmentNumber: payment.paidInstallments + 1,
          installmentType: 'first_installment',
          isOnlineFlow: initialMode == 'online',
          initialMode: initialMode,
          hasVoucher: true,
          onDownloadChallan: () => _downloadVoucherForPaymentPage(
            plot: plot,
            isFiler: isFiler,
            installments: installments,
            bookingAmount: bookingAmount,
            confirmationAmount: confirmationAmount,
            monthlyInstallment: monthlyInstallment,
          ),
        ),
      ),
    );
  }

  Future<void> _downloadVoucherForPaymentPage({
    required PlotModel plot,
    required bool isFiler,
    required int installments,
    required double bookingAmount,
    required double confirmationAmount,
    required double monthlyInstallment,
  }) async {
    List<PaymentMethodModel> methods = [];
    try {
      methods = await _manualPaymentService.getActivePaymentMethodsOnce();
    } catch (_) {
      methods = [];
    }

    final bytes = await _buildVoucherPdf(
      plot: plot,
      isFiler: isFiler,
      installments: installments,
      bookingAmount: bookingAmount,
      confirmationAmount: confirmationAmount,
      monthlyInstallment: monthlyInstallment,
      paymentMethods: methods,
    );

    await Printing.sharePdf(
      bytes: bytes,
      filename: 'royalnest_voucher_${plot.id}.pdf',
    );
  }

  Future<Uint8List> _buildVoucherPdf({
    required PlotModel plot,
    required bool isFiler,
    required int installments,
    required double bookingAmount,
    required double confirmationAmount,
    required double monthlyInstallment,
    required List<PaymentMethodModel> paymentMethods,
  }) async {
    final doc = pw.Document();
    final now = DateTime.now();
    final issuedAt =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final voucherNumber =
        'RN-${plot.id.toUpperCase()}-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          pw.Widget item(String label, String value, {bool strong = false}) {
            return pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 8),
              child: pw.Row(
                children: [
                  pw.SizedBox(
                    width: 160,
                    child: pw.Text(
                      label,
                      style: pw.TextStyle(
                        fontSize: 11,
                        color: PdfColors.blueGrey800,
                      ),
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Text(
                      value,
                      style: pw.TextStyle(
                        fontSize: strong ? 13 : 11,
                        fontWeight: strong
                            ? pw.FontWeight.bold
                            : pw.FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return pw.Padding(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(14),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.blue900,
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'ROYAL NEST - PAYMENT VOUCHER',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      pw.Text(
                        voucherNumber,
                        style: const pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 16),
                item('Issued At', issuedAt),
                item('Plot', plot.title),
                item('Plot ID', plot.id),
                item('Society', plot.society),
                item(
                  'Client Name',
                  _currentUser?.username.isNotEmpty == true
                      ? _currentUser!.username
                      : (FirebaseAuth.instance.currentUser?.displayName ??
                            'Client'),
                ),
                item(
                  'Client Email',
                  _currentUser?.email.isNotEmpty == true
                      ? _currentUser!.email
                      : (FirebaseAuth.instance.currentUser?.email ?? 'N/A'),
                ),
                item('Customer Type', isFiler ? 'Filer' : 'Non-Filer'),
                item('Selected Installments', '$installments Months'),
                pw.Divider(color: PdfColors.grey400),
                pw.Text(
                  'Admin Payment Channels',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                pw.SizedBox(height: 6),
                if (paymentMethods.isEmpty)
                  item(
                    'Account Details',
                    'Will be provided in app payment methods',
                  )
                else
                  ...paymentMethods
                      .take(4)
                      .map(
                        (method) => item(
                          method.methodName,
                          '${method.accountTitle} - ${method.accountNumber}',
                        ),
                      ),
                pw.Divider(color: PdfColors.grey400),
                item(
                  'Total Plot Price',
                  'PKR ${plot.price.toStringAsFixed(0)}',
                ),
                item(
                  'First Installment (Pay Now)',
                  'PKR ${bookingAmount.toStringAsFixed(0)}',
                  strong: true,
                ),
                item(
                  'Confirmation Amount',
                  'PKR ${confirmationAmount.toStringAsFixed(0)}',
                ),
                item(
                  'Monthly Installment',
                  'PKR ${monthlyInstallment.toStringAsFixed(0)}',
                ),
                pw.SizedBox(height: 18),
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Text(
                    'Instructions: Pay only the First Installment amount shown above, then upload your paid receipt screenshot in the app from Manual Payment screen. Admin will verify and confirm your installment.',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    return doc.save();
  }

  Widget _buildDetailSection(
    String title,
    List<(String label, String value)> items,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...items.asMap().entries.map((entry) {
          final (label, value) = entry.value;
          final isLast = entry.key == items.length - 1;
          return Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              if (!isLast) const SizedBox(height: 8),
              if (!isLast) Divider(height: 1, color: Colors.grey[300]),
              if (!isLast) const SizedBox(height: 8),
            ],
          );
        }),
      ],
    );
  }
}
