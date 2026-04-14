import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../services/auth_service.dart';
import 'client_home_screen.dart';
import 'client_plots_screen.dart';
import 'client_ai_assistant_screen.dart';
import 'client_3d_view_screen.dart';
import 'client_drawer.dart';

/// Client Navigation Wrapper with Bottom Navigation Bar
class ClientMainScreen extends StatefulWidget {
  const ClientMainScreen({super.key});

  @override
  State<ClientMainScreen> createState() => _ClientMainScreenState();
}

class _ClientMainScreenState extends State<ClientMainScreen> {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final AuthService _authService = AuthService();

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const ClientHomeScreen(),
      const ClientPlotsScreen(),
      const Client3DViewScreen(),
      const ClientAIAssistantScreen(),
    ];
    _enforceVerificationGuard();
  }

  Future<void> _enforceVerificationGuard() async {
    final user = _authService.currentUser;
    if (user == null) {
      if (!mounted) {
        return;
      }
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
      return;
    }

    final isVerified = await _authService.isCurrentUserEmailVerified();
    if (!mounted || isVerified) {
      return;
    }

    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil('/verify-email', (_) => false);
  }

  void _onBottomNavTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: const ClientDrawer(),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 320),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          final slide = Tween<Offset>(
            begin: const Offset(0.04, 0.0),
            end: Offset.zero,
          ).animate(animation);
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(position: slide, child: child),
          );
        },
        child: KeyedSubtree(
          key: ValueKey<int>(_currentIndex),
          child: _screens[_currentIndex],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onBottomNavTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: AppTheme.royalBlue,
          unselectedItemColor: Colors.grey.shade400,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined, size: 24),
              activeIcon: Icon(Icons.home, size: 24),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.landscape_outlined, size: 24),
              activeIcon: Icon(Icons.landscape, size: 24),
              label: 'Plots',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.view_in_ar_outlined, size: 24),
              activeIcon: Icon(Icons.view_in_ar, size: 24),
              label: 'Virtual Visit',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.smart_toy_outlined, size: 24),
              activeIcon: Icon(Icons.smart_toy, size: 24),
              label: 'AI Chat',
            ),
          ],
        ),
      ),
    );
  }
}
