import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/theme/app_theme.dart';
import '../../core/providers/app_state_provider.dart';
import '../../services/auth_service.dart';

/// Client side navigation drawer
class ClientDrawer extends StatefulWidget {
  const ClientDrawer({super.key});

  @override
  State<ClientDrawer> createState() => _ClientDrawerState();
}

class _ClientDrawerState extends State<ClientDrawer> {
  late String? _selectedSociety;

  @override
  void initState() {
    super.initState();
    _selectedSociety = AppStateProvider.getSelectedSociety();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Drawer(
      child: Column(
        children: [
          // User Profile Header - Now clickable
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/client-profile');
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
              decoration: const BoxDecoration(
                gradient: AppTheme.primaryGradient,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        user?.displayName?.isNotEmpty == true
                            ? user!.displayName![0].toUpperCase()
                            : user?.email?[0].toUpperCase() ?? 'C',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.royalBlue,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user?.displayName ?? 'Client',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? '',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap to view profile',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.7),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Menu Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                // Dashboard
                _buildMenuItem(
                  context,
                  icon: Icons.dashboard_outlined,
                  title: 'Dashboard',
                  route: '/client-dashboard',
                ),
                // Societies Section
                _buildSectionHeader('SOCIETIES'),
                ..._buildSocietiesMenuItems(context),
                const Divider(indent: 16, endIndent: 16),
                // Main Menu Items
                _buildMenuItem(
                  context,
                  icon: Icons.payment_outlined,
                  title: 'My Payments / Orders',
                  route: '/client-manual-payments',
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.calendar_today_outlined,
                  title: 'Appointments',
                  route: '/client-appointments',
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.help_outline,
                  title: 'Queries',
                  route: '/client-queries',
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.search_outlined,
                  title: 'Lost & Found',
                  route: '/client-lost-found',
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.description_outlined,
                  title: 'Documents',
                  route: '/client-documents',
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.notifications_outlined,
                  title: 'Notifications',
                  route: '/client-notifications',
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.smart_toy_outlined,
                  title: 'AI Assistant',
                  route: '/client-ai-assistant',
                ),
              ],
            ),
          ),

          // Logout
          Container(
            padding: const EdgeInsets.all(12),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.logout, color: Colors.red, size: 18),
              ),
              title: const Text(
                'Logout',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              onTap: () => _showLogoutDialog(context),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSocietiesMenuItems(BuildContext context) {
    return AppStateProvider.getSocietyOptions()
        .map(
          (society) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            child: ListTile(
              leading: Icon(
                _selectedSociety == society
                    ? Icons.location_on
                    : Icons.location_on_outlined,
                color: _selectedSociety == society
                    ? AppTheme.royalBlue
                    : Colors.grey[600],
                size: 20,
              ),
              title: Text(
                society,
                style: TextStyle(
                  color: _selectedSociety == society
                      ? AppTheme.royalBlue
                      : Colors.black87,
                  fontWeight: _selectedSociety == society
                      ? FontWeight.w600
                      : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
              dense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 0,
              ),
              onTap: () {
                setState(() {
                  _selectedSociety = society;
                });
                AppStateProvider.setSelectedSociety(society);
                Navigator.pop(context);
                Navigator.pushNamed(context, '/client-plots');
              },
            ),
          ),
        )
        .toList();
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          color: AppTheme.royalBlue,
          fontWeight: FontWeight.w700,
          fontSize: 11,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String route,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.royalBlue, size: 20),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
        ),
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        onTap: () {
          Navigator.pop(context);
          Navigator.pushNamed(context, route);
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
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              Navigator.pop(context);
              await AuthService().signOut();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              }
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
