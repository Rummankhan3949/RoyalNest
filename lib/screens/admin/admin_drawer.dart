import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Admin Drawer - Minimal and professional design
class AdminDrawer extends StatelessWidget {
  const AdminDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // Admin Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                gradient: AppTheme.primaryGradient,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.admin_panel_settings,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Admin',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Royal Nest Management',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),

            // Menu Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _buildMenuItem(
                    context,
                    Icons.dashboard,
                    'Dashboard',
                    '/admin-home',
                  ),
                  _buildMenuItem(
                    context,
                    Icons.smart_toy,
                    'AI Assistant',
                    '/admin-ai-assistant',
                  ),
                  _buildMenuItem(
                    context,
                    Icons.add_business,
                    'Plots',
                    '/admin-plots',
                  ),
                  _buildMenuItem(
                    context,
                    Icons.help_outline,
                    'Queries',
                    '/admin-queries',
                  ),
                  _buildMenuItem(
                    context,
                    Icons.calendar_today,
                    'Appointments',
                    '/admin-appointments',
                  ),
                  _buildMenuItem(
                    context,
                    Icons.search_off,
                    'Lost & Found',
                    '/admin-lost-found',
                  ),
                  _buildMenuItem(
                    context,
                    Icons.payment,
                    'Payments',
                    '/admin-payments',
                  ),
                  _buildMenuItem(
                    context,
                    Icons.receipt_long,
                    'Manual Payment Proofs',
                    '/admin-manual-payments',
                  ),
                  _buildMenuItem(
                    context,
                    Icons.account_balance_wallet,
                    'Payment Methods',
                    '/admin-payment-methods',
                  ),
                  _buildMenuItem(
                    context,
                    Icons.verified_user,
                    'Documents',
                    '/admin-documents',
                  ),
                  _buildMenuItem(
                    context,
                    Icons.people,
                    'Clients',
                    '/admin-clients',
                  ),
                  _buildMenuItem(
                    context,
                    Icons.campaign,
                    'Events',
                    '/admin-events',
                  ),
                  _buildMenuItem(
                    context,
                    Icons.psychology,
                    'ML Predictions',
                    '/admin-ml-prediction',
                  ),
                ],
              ),
            ),

            // Logout
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: ListTile(
                leading: Icon(
                  Icons.logout,
                  color: Colors.red.shade600,
                  size: 20,
                ),
                title: Text(
                  'Logout',
                  style: TextStyle(
                    color: Colors.red.shade600,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                dense: true,
                onTap: () => _showLogoutDialog(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    IconData icon,
    String label,
    String route,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.royalBlue, size: 20),
        title: Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        onTap: () {
          final currentRoute = ModalRoute.of(context)?.settings.name;

          Navigator.pop(context);

          if (currentRoute == route) {
            return;
          }

          if (route == '/admin-home') {
            Navigator.pushNamedAndRemoveUntil(context, route, (r) => false);
            return;
          }

          if (currentRoute == '/admin-home') {
            Navigator.pushNamed(context, route);
          } else {
            Navigator.pushReplacementNamed(context, route);
          }
        },
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (route) => false,
              );
            },
            child: const Text(
              'Logout',
              style: TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
