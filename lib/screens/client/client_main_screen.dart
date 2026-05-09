import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/event_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/event_service.dart';
import 'client_home_screen.dart';
import 'client_plots_screen.dart';
import 'client_ai_assistant_screen.dart';
import 'client_3d_view_screen.dart';
import 'client_drawer.dart';
import '../../widgets/event_popup_dialog.dart';

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
  final EventService _eventService = EventService();
  StreamSubscription<UserModel?>? _userGuardSubscription;
  bool _isHandlingBlockedState = false;
  bool _isEventCheckRunning = false;
  bool _hasTriedEventPopupRetry = false;

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
    _startBlockedUserListener();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showEventPopupIfNeeded();
      _scheduleEventPopupRetry();
    });
  }

  void _scheduleEventPopupRetry() {
    if (_hasTriedEventPopupRetry || !mounted) {
      return;
    }

    _hasTriedEventPopupRetry = true;
    Future<void>.delayed(const Duration(seconds: 2), () {
      if (!mounted) {
        return;
      }
      _showEventPopupIfNeeded();
    });
  }

  @override
  void dispose() {
    _userGuardSubscription?.cancel();
    super.dispose();
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

  void _startBlockedUserListener() {
    _userGuardSubscription = _authService.watchCurrentUserProfile().listen((
      profile,
    ) async {
      if (!mounted || _isHandlingBlockedState) return;
      if (profile?.isBlocked != true) return;

      _isHandlingBlockedState = true;
      await _authService.logout();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your account has been blocked by admin'),
          backgroundColor: Colors.red,
        ),
      );

      Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
    });
  }

  Future<void> _showEventPopupIfNeeded() async {
    if (_isEventCheckRunning || !mounted) return;
    _isEventCheckRunning = true;

    try {
      final EventModel? event = await _eventService.getActiveEventForNow();
      if (!mounted || event == null) return;

      final shouldShow = await _eventService.shouldShowEventThisLoginSession(
        event,
      );
      if (!mounted || !shouldShow) return;

      await showGeneralDialog<void>(
        context: context,
        barrierDismissible: true,
        barrierLabel: 'event-popup',
        barrierColor: Colors.transparent,
        transitionDuration: const Duration(milliseconds: 260),
        pageBuilder: (_, __, ___) {
          return EventPopupDialog(
            event: event,
            onClose: () => Navigator.of(context).pop(),
          );
        },
      );

      await _eventService.markEventShownForSession(event.id);
    } finally {
      _isEventCheckRunning = false;
    }
  }

  void _onBottomNavTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_currentIndex != 0) {
          setState(() => _currentIndex = 0);
          return false;
        }
        return true;
      },
      child: Scaffold(
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
      ),
    );
  }
}
