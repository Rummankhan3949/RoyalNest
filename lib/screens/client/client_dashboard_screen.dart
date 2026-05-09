import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/theme/app_theme.dart';
import '../../models/plot_model.dart';
import '../../models/payment_model.dart';
import '../../services/plot_service.dart';
import '../../services/payment_service.dart';
import 'client_drawer.dart';

/// Client Dashboard Screen - Overview of plots, payments, and status
class ClientDashboardScreen extends StatefulWidget {
  const ClientDashboardScreen({super.key});

  @override
  State<ClientDashboardScreen> createState() => _ClientDashboardScreenState();
}

class _ClientDashboardScreenState extends State<ClientDashboardScreen> {
  final PlotService _plotService = PlotService();
  final PaymentService _paymentService = PaymentService();
  String get userId => FirebaseAuth.instance.currentUser?.uid ?? '';

  static const List<_OverviewAction> _overviewActions = [
    _OverviewAction(
      label: 'Plots',
      icon: Icons.landscape_outlined,
      color: AppTheme.royalBlue,
      route: '/client-plots',
    ),
    _OverviewAction(
      label: 'Payments',
      icon: Icons.payments_outlined,
      color: Color(0xFF2F80ED),
      route: '/client-payments',
    ),
    _OverviewAction(
      label: 'Manual Pay',
      icon: Icons.receipt_long_outlined,
      color: Color(0xFF00A36C),
      route: '/client-manual-payments',
    ),
    _OverviewAction(
      label: 'Queries',
      icon: Icons.chat_bubble_outline,
      color: Color(0xFF7B61FF),
      route: '/client-queries',
    ),
    _OverviewAction(
      label: 'Appointments',
      icon: Icons.event_available_outlined,
      color: Color(0xFFF2994A),
      route: '/client-appointments',
    ),
    _OverviewAction(
      label: 'Documents',
      icon: Icons.folder_open_outlined,
      color: Color(0xFF1E6FD9),
      route: '/client-documents',
    ),
    _OverviewAction(
      label: 'Notifications',
      icon: Icons.notifications_none,
      color: Color(0xFFEB5757),
      route: '/client-notifications',
    ),
    _OverviewAction(
      label: 'Profile',
      icon: Icons.person_outline,
      color: Color(0xFF3D5AFE),
      route: '/client-profile',
    ),
    _OverviewAction(
      label: 'AI Assistant',
      icon: Icons.smart_toy_outlined,
      color: Color(0xFF0F7DA0),
      route: '/client-ai-assistant',
    ),
  ];

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
          'Dashboard',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: const ClientDrawer(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Welcome Card
            _buildWelcomeCard(),
            // Stats Cards
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Overview Section
                  const Text(
                    'Your Overview',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildOverviewGrid(),
                  const SizedBox(height: 18),
                  FutureBuilder<List<PlotModel>>(
                    future: _plotService.getClientPlots(userId).first,
                    builder: (context, snapshot) {
                      final plots = snapshot.data ?? [];
                      return _buildStatsGrid(plots);
                    },
                  ),
                  const SizedBox(height: 24),
                  // Owned Plots Section
                  const Text(
                    'My Plots',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FutureBuilder<List<PlotModel>>(
                    future: _plotService.getClientPlots(userId).first,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final plots = snapshot.data ?? [];
                      if (plots.isEmpty) {
                        return _buildEmptyState(
                          'No Plots Yet',
                          'Browse available plots to get started',
                          Icons.landscape_outlined,
                        );
                      }

                      return Column(
                        children: List.generate(
                          plots.length,
                          (index) => _buildPlotCard(plots[index]),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  // Payment Status Section
                  const Text(
                    'Payment Status',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FutureBuilder<List<PaymentModel>>(
                    future: _paymentService.getClientPayments(userId).first,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final payments = snapshot.data ?? [];
                      if (payments.isEmpty) {
                        return _buildEmptyState(
                          'No Payments',
                          'Payment history will appear here',
                          Icons.payment_outlined,
                        );
                      }

                      double totalPaid = 0;
                      double totalDue = 0;
                      int completedPayments = 0;
                      int pendingPayments = 0;

                      for (final payment in payments) {
                        if (payment.status == 'completed') {
                          totalPaid += payment.paidAmount;
                          completedPayments++;
                        } else if (payment.status == 'pending') {
                          totalDue += payment.remainingAmount;
                          pendingPayments++;
                        }
                      }

                      return Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildPaymentStatCard(
                                  'Paid',
                                  _formatCurrency(totalPaid),
                                  Colors.green,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildPaymentStatCard(
                                  'Due',
                                  _formatCurrency(totalDue),
                                  Colors.orange,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildPaymentStatCard(
                                  'Completed',
                                  '$completedPayments',
                                  AppTheme.royalBlue,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildPaymentStatCard(
                                  'Pending',
                                  '$pendingPayments',
                                  Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    final user = FirebaseAuth.instance.currentUser;
    return Container(
      decoration: const BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome back,',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            user?.displayName ?? 'Client',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Here is an overview of your property management',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(List<PlotModel> plots) {
    int totalPlots = plots.length;
    int ownedPlots = plots.where((p) => p.ownerId == userId).length;
    int availablePlots = plots.where((p) => p.status == 'available').length;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Plots',
            '$totalPlots',
            Icons.landscape,
            AppTheme.royalBlue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Owned',
            '$ownedPlots',
            Icons.verified,
            Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Available',
            '$availablePlots',
            Icons.check_circle,
            Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width < 360
            ? 2
            : width < 520
            ? 3
            : 4;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.05,
          ),
          itemCount: _overviewActions.length,
          itemBuilder: (context, index) {
            final action = _overviewActions[index];
            return _OverviewActionTile(
              action: action,
              index: index,
              onTap: () => Navigator.pushNamed(context, action.route),
            );
          },
        );
      },
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlotCard(PlotModel plot) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppTheme.lightBlue,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Icon(
                  Icons.landscape,
                  color: AppTheme.royalBlue,
                  size: 28,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plot.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    plot.society,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    plot.formattedPrice,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.royalBlue,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(plot.status).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                plot.status.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: _getStatusColor(plot.status),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Center(
      child: Column(
        children: [
          Icon(icon, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'available':
        return Colors.green;
      case 'sold':
        return Colors.red;
      case 'reserved':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _formatCurrency(double amount) {
    if (amount >= 10000000) {
      return 'PKR ${(amount / 10000000).toStringAsFixed(2)}Cr';
    } else if (amount >= 100000) {
      return 'PKR ${(amount / 100000).toStringAsFixed(2)}L';
    } else if (amount >= 1000) {
      return 'PKR ${(amount / 1000).toStringAsFixed(2)}K';
    }
    return 'PKR ${amount.toStringAsFixed(0)}';
  }
}

class _OverviewAction {
  const _OverviewAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.route,
  });

  final String label;
  final IconData icon;
  final Color color;
  final String route;
}

class _OverviewActionTile extends StatefulWidget {
  const _OverviewActionTile({
    required this.action,
    required this.index,
    required this.onTap,
  });

  final _OverviewAction action;
  final int index;
  final VoidCallback onTap;

  @override
  State<_OverviewActionTile> createState() => _OverviewActionTileState();
}

class _OverviewActionTileState extends State<_OverviewActionTile> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(Duration(milliseconds: 120 + widget.index * 70), () {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final action = widget.action;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      opacity: _visible ? 1 : 0,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutBack,
        scale: _visible ? 1 : 0.94,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [action.color.withValues(alpha: 0.14), Colors.white],
                ),
                border: Border.all(color: action.color.withValues(alpha: 0.25)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: action.color.withValues(alpha: 0.14),
                    ),
                    child: Icon(action.icon, color: action.color, size: 20),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    action.label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
