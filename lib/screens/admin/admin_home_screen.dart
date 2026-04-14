import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../services/plot_service.dart';
import 'admin_drawer.dart';
import 'admin_society_details_screen.dart';

/// Admin Home Screen - Dashboard with society overview
class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final PlotService _plotService = PlotService();
  Map<String, Map<String, int>> _societyStats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    final stats = await _plotService.getAllSocietiesStats();
    setState(() {
      _societyStats = stats;
      _isLoading = false;
    });
  }

  void _openSocietyDetails(String society) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AdminSocietyDetailsScreen(societyName: society),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.royalBlue,
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadStats,
          ),
        ],
      ),
      drawer: const AdminDrawer(),
      body: RefreshIndicator(
        onRefresh: _loadStats,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _AdminEntranceReveal(
                delay: const Duration(milliseconds: 20),
                child: _buildWelcomeCard(),
              ),
              const SizedBox(height: 24),
              const _AdminEntranceReveal(
                delay: Duration(milliseconds: 120),
                child: Text(
                  'Society Overview',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryTextColor,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _AdminEntranceReveal(
                delay: const Duration(milliseconds: 180),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildSocietyCards(),
              ),
              const SizedBox(height: 24),
              _AdminEntranceReveal(
                delay: const Duration(milliseconds: 260),
                child: _buildQuickActions(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.royalBlue.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome, Admin!',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Manage your Royal Nest societies and clients efficiently.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.admin_panel_settings,
              size: 40,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocietyCards() {
    if (_societyStats.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.blue[200]!),
        ),
        child: Column(
          children: [
            Icon(Icons.info_outline, color: Colors.blue[700], size: 40),
            const SizedBox(height: 12),
            Text(
              'No society data available',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.blue[900],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Societies will appear here once plots are added',
              style: TextStyle(fontSize: 13, color: Colors.blue[700]),
            ),
          ],
        ),
      );
    }

    return Column(
      children: AppConstants.societies.map((society) {
        final stats =
            _societyStats[society] ?? {'total': 0, 'sold': 0, 'available': 0};
        return _buildSocietyCard(society, stats);
      }).toList(),
    );
  }

  Widget _buildSocietyCard(String society, Map<String, int> stats) {
    final total = stats['total'] ?? 0;
    final sold = stats['sold'] ?? 0;
    final available = stats['available'] ?? 0;
    final soldPercentage = total > 0 ? (sold / total * 100) : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: AppTheme.cardDecoration,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openSocietyDetails(society),
          borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.royalBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.location_city,
                        color: AppTheme.royalBlue,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            society,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Tap to view details',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.grey,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildStatItem('Total', total.toString(), Colors.blue),
                    _buildStatItem('Sold', sold.toString(), Colors.red),
                    _buildStatItem(
                      'Available',
                      available.toString(),
                      Colors.green,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: soldPercentage / 100,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      soldPercentage > 80
                          ? Colors.red
                          : soldPercentage > 50
                          ? Colors.orange
                          : Colors.green,
                    ),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${soldPercentage.toStringAsFixed(1)}% sold',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryTextColor,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _buildActionCard(
              'Add Plot',
              Icons.add_business,
              Colors.blue,
              () => Navigator.pushNamed(context, '/admin-plots'),
            ),
            _buildActionCard(
              'Pending Queries',
              Icons.help_outline,
              Colors.orange,
              () => Navigator.pushNamed(context, '/admin-queries'),
            ),
            _buildActionCard(
              'Appointments',
              Icons.calendar_today,
              Colors.purple,
              () => Navigator.pushNamed(context, '/admin-appointments'),
            ),
            _buildActionCard(
              'Verify Docs',
              Icons.verified_user,
              Colors.green,
              () => Navigator.pushNamed(context, '/admin-documents'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Container(
      decoration: AppTheme.cardDecoration,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 32),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminEntranceReveal extends StatefulWidget {
  const _AdminEntranceReveal({required this.child, required this.delay});

  final Widget child;
  final Duration delay;

  @override
  State<_AdminEntranceReveal> createState() => _AdminEntranceRevealState();
}

class _AdminEntranceRevealState extends State<_AdminEntranceReveal> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) {
        setState(() => _visible = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      offset: _visible ? Offset.zero : const Offset(0, 0.05),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOut,
        opacity: _visible ? 1 : 0,
        child: widget.child,
      ),
    );
  }
}
