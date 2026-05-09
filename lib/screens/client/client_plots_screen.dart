import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:media_store_plus/media_store_plus.dart';

import '../../core/theme/app_theme.dart';
import '../../core/data/panorama_scenes.dart';
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
import 'panorama_fullscreen_screen.dart';

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

  String _formatPkr(double amount) => 'PKR ${amount.toStringAsFixed(0)}';

  double _selectedPriceForTaxStatus(PlotModel plot, bool isFiler) {
    final filerPrice = plot.filerPrice;
    final nonFilerPrice = plot.nonFilerPrice;

    if (isFiler && filerPrice != null && filerPrice > 0) {
      return filerPrice;
    }

    if (!isFiler && nonFilerPrice != null && nonFilerPrice > 0) {
      return nonFilerPrice;
    }

    return plot.price;
  }

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
        onTap: () => _openVirtualTourForPlot(plot),
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

  void _openVirtualTourForPlot(PlotModel plot) {
    final group = findPanoramaGroupByName(plot.society);
    if (group == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Virtual tour is not available for this society yet.'),
        ),
      );
      return;
    }

    final scenes = buildTourScenes(group);
    if (scenes.isEmpty) return;

    for (int i = 0; i < scenes.length && i < 4; i++) {
      precacheImage(AssetImage(scenes[i].imagePath), context);
    }

    Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 500),
        reverseTransitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (_, __, ___) => PanoramaFullscreenScreen(
          scenes: scenes,
          societyName: group.name,
          accentColor: group.accentColor,
        ),
        transitionsBuilder: (_, animation, __, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.93, end: 1.0).animate(curved),
              child: child,
            ),
          );
        },
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

  Future<void> _showPurchaseOptions(PlotModel plot) async {
    bool isFiler = _currentUser?.isFiler ?? true;
    bool isInstallmentPlan = false;
    int installmentYears = 3;
    final paymentHeroTag = 'payment-hero-${plot.id}';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final selectedTotal = _selectedPriceForTaxStatus(plot, isFiler);
            final months = isInstallmentPlan ? installmentYears * 12 : 1;
            final downPaymentPercent = !isInstallmentPlan
                ? 100
                : installmentYears == 3
                ? 20
                : installmentYears == 2
                ? 40
                : 60;
            final bookingAmount = selectedTotal * (downPaymentPercent / 100);
            final remainingAfterUpfront = (selectedTotal - bookingAmount)
                .clamp(0, double.infinity)
                .toDouble();
            final monthlyInstallment = isInstallmentPlan
                ? remainingAfterUpfront / months
                : 0.0;
            final confirmationAmount = 0.0;
            final isFullPayment = !isInstallmentPlan;

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF0A2E73), Color(0xFF2F7ADB)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Hero(
                            tag: paymentHeroTag,
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.account_balance_wallet_rounded,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Choose Your Payment Method',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Step 1: Select Tax Status',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
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
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Step 2: Choose Plan',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () =>
                                setModalState(() => isInstallmentPlan = false),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isInstallmentPlan
                                    ? Colors.white
                                    : const Color(0xFFEAF2FF),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isInstallmentPlan
                                      ? Colors.grey.shade300
                                      : AppTheme.royalBlue,
                                  width: isInstallmentPlan ? 1 : 1.6,
                                ),
                              ),
                              child: const Column(
                                children: [
                                  Icon(Icons.payments_rounded),
                                  SizedBox(height: 6),
                                  Text(
                                    'Full Payment',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: GestureDetector(
                            onTap: () =>
                                setModalState(() => isInstallmentPlan = true),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isInstallmentPlan
                                    ? const Color(0xFFEAF2FF)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isInstallmentPlan
                                      ? AppTheme.royalBlue
                                      : Colors.grey.shade300,
                                  width: isInstallmentPlan ? 1.6 : 1,
                                ),
                              ),
                              child: const Column(
                                children: [
                                  Icon(Icons.calendar_month_rounded),
                                  SizedBox(height: 6),
                                  Text(
                                    'Installments',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 260),
                      child: !isInstallmentPlan
                          ? const SizedBox(height: 0)
                          : Padding(
                              key: const ValueKey('installment-tenure'),
                              padding: const EdgeInsets.only(top: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Step 3: Select Installment Tenure',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  SegmentedButton<int>(
                                    segments: const [
                                      ButtonSegment<int>(
                                        value: 1,
                                        label: Text('1 Year'),
                                      ),
                                      ButtonSegment<int>(
                                        value: 2,
                                        label: Text('2 Years'),
                                      ),
                                      ButtonSegment<int>(
                                        value: 3,
                                        label: Text('3 Years'),
                                      ),
                                    ],
                                    selected: {installmentYears},
                                    onSelectionChanged: (value) {
                                      setModalState(() {
                                        installmentYears = value.first;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.lightBlue.withValues(alpha: 0.24),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Selected Price: ${_formatPkr(selectedTotal)}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            'Customer Type: ${isFiler ? 'Filer' : 'Non-Filer'}',
                          ),
                          Text(
                            'Plan: ${isFullPayment ? 'Full Payment' : '$installmentYears Year Installments'}',
                          ),
                          Text(
                            'Pay Now ($downPaymentPercent%): ${_formatPkr(bookingAmount)}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          if (!isFullPayment)
                            Text(
                              'Remaining: ${_formatPkr(remainingAfterUpfront)}',
                            ),
                          if (!isFullPayment)
                            Text(
                              'Monthly Installment ($months months): ${_formatPkr(monthlyInstallment)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
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
                            heroTag: paymentHeroTag,
                            totalAmount: selectedTotal,
                            installments: months,
                            bookingAmount: bookingAmount,
                            confirmationAmount: confirmationAmount,
                            monthlyInstallment: monthlyInstallment,
                          );
                        },
                        icon: const Icon(Icons.arrow_forward_rounded),
                        label: Text(
                          isFullPayment
                              ? 'Proceed with Full Payment'
                              : 'Proceed with Installments',
                        ),
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
    required double totalAmount,
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
      totalAmount: totalAmount,
      bookingAmount: bookingAmount,
      confirmationAmount: confirmationAmount,
      monthlyInstallment: monthlyInstallment,
      totalInstallments: installments,
      remainingAmount: totalAmount,
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
    required String heroTag,
    required double totalAmount,
    required int installments,
    required double bookingAmount,
    required double confirmationAmount,
    required double monthlyInstallment,
  }) async {
    await _openPaymentTransactionPage(
      plot: plot,
      isFiler: isFiler,
      heroTag: heroTag,
      totalAmount: totalAmount,
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
    required String heroTag,
    required double totalAmount,
    required int installments,
    required double bookingAmount,
    required double confirmationAmount,
    required double monthlyInstallment,
    required String initialMode,
  }) async {
    final payment = await _ensurePaymentPlan(
      plot: plot,
      totalAmount: totalAmount,
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
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 460),
        reverseTransitionDuration: const Duration(milliseconds: 340),
        pageBuilder: (_, animation, __) {
          return FadeTransition(
            opacity: animation,
            child: ClientManualPaymentScreen(
              propertyId: plot.id,
              propertyName: plot.title,
              amount: bookingAmount,
              heroTag: heroTag,
              linkedPaymentId: payment.id,
              installmentNumber: payment.paidInstallments + 1,
              installmentType: installments <= 1
                  ? 'full_payment'
                  : 'first_installment',
              isOnlineFlow: initialMode == 'online',
              initialMode: initialMode,
              hasVoucher: true,
              onDownloadChallan: () => _downloadVoucherForPaymentPage(
                plot: plot,
                isFiler: isFiler,
                totalAmount: totalAmount,
                installments: installments,
                bookingAmount: bookingAmount,
                confirmationAmount: confirmationAmount,
                monthlyInstallment: monthlyInstallment,
              ),
            ),
          );
        },
        transitionsBuilder: (_, animation, __, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.06),
              end: Offset.zero,
            ).animate(curved),
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.99, end: 1).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }

  Future<bool> _downloadVoucherForPaymentPage({
    required PlotModel plot,
    required bool isFiler,
    required double totalAmount,
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
      totalAmount: totalAmount,
      installments: installments,
      bookingAmount: bookingAmount,
      confirmationAmount: confirmationAmount,
      monthlyInstallment: monthlyInstallment,
      paymentMethods: methods,
    );
    return _saveAndSharePdf(bytes, 'royalnest_voucher_${plot.id}.pdf');
  }

  Future<bool> _saveAndSharePdf(Uint8List bytes, String filename) async {
    if (Platform.isAndroid) {
      try {
        await MediaStore.ensureInitialized();
        MediaStore.appFolder = 'RoyalNest';
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/$filename');
        await tempFile.writeAsBytes(bytes, flush: true);
        final saved = await MediaStore().saveFile(
          tempFilePath: tempFile.path,
          dirType: DirType.download,
          dirName: DirName.download,
          relativePath: null,
        );
        if (saved != null) {
          return true;
        }
      } catch (_) {
        // Continue to fallback.
      }
    }
    return false;
  }

  PaymentMethodModel? _pickSocietyPaymentMethod(
    List<PaymentMethodModel> methods,
    String societyName,
  ) {
    if (methods.isEmpty) return null;
    final normalizedSociety = societyName.trim().toLowerCase();
    final matched = methods.firstWhere(
      (method) => method.societyName.trim().toLowerCase() == normalizedSociety,
      orElse: () => methods.first,
    );
    return matched;
  }

  Future<Uint8List> _buildVoucherPdf({
    required PlotModel plot,
    required bool isFiler,
    required double totalAmount,
    required int installments,
    required double bookingAmount,
    required double confirmationAmount,
    required double monthlyInstallment,
    required List<PaymentMethodModel> paymentMethods,
  }) async {
    // ── Layout constants ──────────────────────────────────────
    // A4 landscape = 842 × 595 pt.  Margin 24 each side → 794 usable.
    // 3 copies × 250 + 2 gaps × 12 = 774 pt  ✓  fits comfortably.
    const double colW = 250;
    const double colGap = 12;
    const double pagePad = 24;
    const double labelW = 70;
    const double valueW = colW - labelW - 22; // 22 = cell paddings + border
    const double innerW = colW - 16; // 8 padding × 2
    final royalBlue = PdfColor.fromHex('#0050FF');
    final lightBlue = PdfColor.fromHex('#E8F0FF');

    // ── Data preparation ──────────────────────────────────────
    final doc = pw.Document();
    final now = DateTime.now();
    final issuedAt =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
    final dueDate = now.add(const Duration(days: 4));
    final dueAt =
        '${dueDate.day.toString().padLeft(2, '0')}/${dueDate.month.toString().padLeft(2, '0')}/${dueDate.year}';
    final rawVoucher =
        'RN-${plot.id.toUpperCase()}-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
    // Truncate long voucher IDs to prevent overflow
    final voucherNumber = rawVoucher.length > 22
        ? '${rawVoucher.substring(0, 22)}...'
        : rawVoucher;
    final isFullPayment = installments <= 1;
    final selectedPlotPrice = _selectedPriceForTaxStatus(plot, isFiler);

    String money(double value) => 'PKR ${value.toStringAsFixed(0)}';
    String safe(String v) => v.trim().isEmpty ? 'N/A' : v.trim();
    final clientName = _currentUser?.username.isNotEmpty == true
        ? _currentUser!.username
        : (FirebaseAuth.instance.currentUser?.displayName ?? 'Client');
    final clientEmail = _currentUser?.email.isNotEmpty == true
        ? _currentUser!.email
        : (FirebaseAuth.instance.currentUser?.email ?? 'N/A');
    final method = _pickSocietyPaymentMethod(paymentMethods, plot.society);

    // ── Reusable text style helpers ───────────────────────────
    pw.TextStyle labelStyle() => pw.TextStyle(
      fontSize: 7,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.grey800,
    );
    pw.TextStyle valueStyle() => pw.TextStyle(fontSize: 7);
    pw.TextStyle sectionStyle() => pw.TextStyle(
      fontSize: 7,
      fontWeight: pw.FontWeight.bold,
      color: royalBlue,
    );

    // ── Table row builder (fixed widths, constrained text) ────
    pw.TableRow tableRow(String label, String value, int idx) {
      return pw.TableRow(
        decoration: pw.BoxDecoration(
          color: idx.isEven ? PdfColors.white : PdfColors.grey50,
        ),
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(
              vertical: 2.5,
              horizontal: 4,
            ),
            child: pw.ConstrainedBox(
              constraints: const pw.BoxConstraints(
                maxWidth: labelW - 8,
                minHeight: 11,
              ),
              child: pw.Text(
                label,
                style: labelStyle(),
                maxLines: 2,
                softWrap: true,
                overflow: pw.TextOverflow.clip,
              ),
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(
              vertical: 2.5,
              horizontal: 4,
            ),
            child: pw.ConstrainedBox(
              constraints: const pw.BoxConstraints(
                maxWidth: valueW - 8,
                minHeight: 11,
              ),
              child: pw.Text(
                value,
                style: valueStyle(),
                maxLines: 2,
                softWrap: true,
                overflow: pw.TextOverflow.clip,
              ),
            ),
          ),
        ],
      );
    }

    // ── Section header row ────────────────────────────────────
    pw.TableRow sectionRow(String title) {
      return pw.TableRow(
        decoration: pw.BoxDecoration(color: lightBlue),
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 4),
            child: pw.Text(title, style: sectionStyle(), maxLines: 1),
          ),
          pw.SizedBox(),
        ],
      );
    }

    // ── Build one challan copy ────────────────────────────────
    pw.Widget challanCopy(String copyTitle) {
      // Collect all data rows
      int rowIdx = 0;
      final rows = <pw.TableRow>[
        sectionRow('CHALLAN INFO'),
        tableRow('Voucher No', voucherNumber, rowIdx++),
        tableRow('Issue Date', issuedAt, rowIdx++),
        tableRow('Due Date', dueAt, rowIdx++),
        sectionRow('PROPERTY DETAILS'),
        tableRow('Society', safe(plot.society), rowIdx++),
        tableRow('Plot Title', safe(plot.title), rowIdx++),
        tableRow('Plot No', safe(plot.plotNumber), rowIdx++),
        tableRow('Block', safe(plot.blockName), rowIdx++),
        tableRow('Type', safe(plot.plotType), rowIdx++),
        tableRow('Size', safe(plot.size), rowIdx++),
        tableRow('Location', safe(plot.location), rowIdx++),
        sectionRow('CLIENT INFO'),
        tableRow('Name', safe(clientName), rowIdx++),
        tableRow('Email', safe(clientEmail), rowIdx++),
        tableRow(
          'Plan',
          isFullPayment ? 'Full Payment' : 'Installments',
          rowIdx++,
        ),
        if (!isFullPayment)
          tableRow('Installment', '1 of $installments', rowIdx++),
        sectionRow('PAYMENT INFO'),
        tableRow('Plot Price', money(selectedPlotPrice), rowIdx++),
        tableRow(
          'Amount Due',
          money(isFullPayment ? totalAmount : bookingAmount),
          rowIdx++,
        ),
        if (!isFullPayment)
          tableRow('Confirmation', money(confirmationAmount), rowIdx++),
        if (!isFullPayment)
          tableRow('Monthly', money(monthlyInstallment), rowIdx++),
        sectionRow('BANK DETAILS'),
      ];

      if (method == null) {
        rows.add(tableRow('Account', 'Contact admin', rowIdx++));
      } else {
        rows.add(tableRow('Bank', safe(method.methodName), rowIdx++));
        rows.add(tableRow('Title', safe(method.accountTitle), rowIdx++));
        rows.add(tableRow('Account', safe(method.accountNumber), rowIdx++));
        if (method.bankId.isNotEmpty) {
          rows.add(tableRow('Bank ID', safe(method.bankId), rowIdx++));
        }
      }

      return pw.SizedBox(
        width: colW,
        child: pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: royalBlue, width: 1),
            color: PdfColors.white,
          ),
          padding: const pw.EdgeInsets.all(8),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              // ── Header ──
              pw.Container(
                width: innerW,
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 5,
                ),
                decoration: pw.BoxDecoration(
                  color: royalBlue,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.SizedBox(
                      width: innerW - 16,
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'ROYAL NEST',
                            style: pw.TextStyle(
                              color: PdfColors.white,
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 9,
                            ),
                            maxLines: 1,
                          ),
                          pw.Text(
                            copyTitle,
                            style: pw.TextStyle(
                              color: PdfColors.white,
                              fontSize: 7,
                            ),
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.SizedBox(
                      width: innerW - 16,
                      child: pw.Text(
                        'PAYMENT CHALLAN / VOUCHER SLIP',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 7,
                        ),
                        maxLines: 1,
                        softWrap: true,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 6),

              // ── Data table ──
              pw.Table(
                border: pw.TableBorder.all(
                  color: PdfColors.grey300,
                  width: 0.3,
                ),
                columnWidths: {
                  0: const pw.FixedColumnWidth(labelW),
                  1: const pw.FixedColumnWidth(valueW),
                },
                children: rows,
              ),
              pw.SizedBox(height: 6),

              // ── Instructions ──
              pw.Container(
                width: innerW,
                padding: const pw.EdgeInsets.all(5),
                decoration: pw.BoxDecoration(
                  color: lightBlue,
                  borderRadius: pw.BorderRadius.circular(3),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.SizedBox(
                      width: innerW - 10,
                      child: pw.Text(
                        'Instructions:',
                        style: sectionStyle(),
                        maxLines: 1,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.SizedBox(
                      width: innerW - 10,
                      child: pw.Text(
                        '1. Verify details and Bank ID before paying.',
                        style: pw.TextStyle(fontSize: 6),
                        maxLines: 2,
                        softWrap: true,
                        overflow: pw.TextOverflow.clip,
                      ),
                    ),
                    pw.SizedBox(
                      width: innerW - 10,
                      child: pw.Text(
                        '2. Keep bank copy and receipt together.',
                        style: pw.TextStyle(fontSize: 6),
                        maxLines: 2,
                        softWrap: true,
                        overflow: pw.TextOverflow.clip,
                      ),
                    ),
                    pw.SizedBox(
                      width: innerW - 10,
                      child: pw.Text(
                        '3. Upload payment proof after deposit.',
                        style: pw.TextStyle(fontSize: 6),
                        maxLines: 2,
                        softWrap: true,
                        overflow: pw.TextOverflow.clip,
                      ),
                    ),
                    if (plot.description.trim().isNotEmpty)
                      pw.SizedBox(
                        width: innerW - 10,
                        child: pw.Text(
                          '4. Notes: ${plot.description.trim()}',
                          style: pw.TextStyle(fontSize: 6),
                          maxLines: 2,
                          softWrap: true,
                          overflow: pw.TextOverflow.clip,
                        ),
                      ),
                  ],
                ),
              ),
              pw.SizedBox(height: 8),

              // ── Signatures ──
              pw.SizedBox(
                width: innerW,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Container(
                          width: 50,
                          height: 0.7,
                          color: PdfColors.black,
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'Client Signature',
                          style: pw.TextStyle(fontSize: 6),
                          maxLines: 1,
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Container(
                          width: 50,
                          height: 0.7,
                          color: PdfColors.black,
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'Cashier Signature',
                          style: pw.TextStyle(fontSize: 6),
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 3),
              pw.SizedBox(
                width: innerW,
                child: pw.Text(
                  'Pay within 3-4 days. Keep this copy safe.',
                  style: pw.TextStyle(fontSize: 6, color: PdfColors.grey600),
                  maxLines: 1,
                  softWrap: true,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ── Build page (A4 LANDSCAPE for proper fit) ──────────────
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(pagePad),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.SizedBox(
                width: colW * 3 + colGap * 2,
                child: pw.Text(
                  'Print this challan and deposit at your bank branch. Keep your copy for record.',
                  style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                  maxLines: 1,
                  softWrap: true,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  challanCopy('Customer Copy'),
                  pw.SizedBox(width: colGap),
                  challanCopy('Office Copy'),
                  pw.SizedBox(width: colGap),
                  challanCopy('Bank Copy'),
                ],
              ),
            ],
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
