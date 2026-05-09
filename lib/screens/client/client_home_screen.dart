import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../core/theme/app_theme.dart';
import '../../services/plot_service.dart';
import '../../services/payment_service.dart';
import '../../services/notification_service.dart';
import '../../services/query_service.dart';
import '../../services/appointment_service.dart';
import '../../services/session_cache_service.dart';
import 'client_drawer.dart';

/// Client Home Screen - Dashboard
class ClientHomeScreen extends StatefulWidget {
  const ClientHomeScreen({super.key});

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  final PlotService _plotService = PlotService();
  final PaymentService _paymentService = PaymentService();
  final NotificationService _notificationService = NotificationService();
  final QueryService _queryService = QueryService();
  final AppointmentService _appointmentService = AppointmentService();
  final SessionCacheService _sessionCacheService = SessionCacheService();

  int _plotCount = 0;
  int _openQueries = 0;
  int _appointments = 0;
  bool _isStatsLoading = true;
  bool _isUsingCachedStats = false;
  static const String _defaultCity = 'Multan';

  String get userId {
    try {
      return FirebaseAuth.instance.currentUser?.uid ?? '';
    } catch (_) {
      return '';
    }
  }

  String get userName {
    try {
      return FirebaseAuth.instance.currentUser?.displayName ?? 'User';
    } catch (_) {
      return 'User';
    }
  }

  String? get userPhotoUrl {
    try {
      return FirebaseAuth.instance.currentUser?.photoURL;
    } catch (_) {
      return null;
    }
  }

  String get _firstName {
    final trimmed = userName.trim();
    if (trimmed.isEmpty) {
      return 'User';
    }
    return trimmed.split(RegExp(r'\s+')).first;
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    }
    if (hour < 17) {
      return 'Good Afternoon';
    }
    return 'Good Evening';
  }

  @override
  void initState() {
    super.initState();
    _hydrateDashboard();
  }

  Future<void> _hydrateDashboard() async {
    final uid = userId;
    final cached = await _sessionCacheService.readDashboardSnapshot(uid);

    if (mounted && cached != null) {
      setState(() {
        _plotCount = cached.plotCount;
        _openQueries = cached.openQueries;
        _appointments = cached.appointments;
        _isUsingCachedStats = true;
        _isStatsLoading = false;
      });
    }

    await _refreshDashboardStats(showLoader: cached == null);
  }

  Future<void> _refreshDashboardStats({bool showLoader = false}) async {
    final uid = userId;
    if (uid.isEmpty) {
      return;
    }

    if (showLoader && mounted) {
      setState(() {
        _isStatsLoading = true;
      });
    }

    try {
      final plotFuture = _plotService.getClientPlotsCount(uid);
      final queryFuture = _queryService.getPendingQueriesCount(uid);
      final appointmentFuture = _appointmentService
          .getUpcomingAppointmentsCount(uid);
      final unreadFuture = _notificationService
          .getUnreadCount(uid)
          .first
          .timeout(const Duration(seconds: 2), onTimeout: () => 0);

      final results = await Future.wait<int>([
        plotFuture,
        queryFuture,
        appointmentFuture,
        unreadFuture,
      ]);

      if (!mounted) {
        return;
      }

      setState(() {
        _plotCount = results[0];
        _openQueries = results[1];
        _appointments = results[2];
        _isStatsLoading = false;
        _isUsingCachedStats = false;
      });

      await _sessionCacheService.saveDashboardSnapshot(
        uid,
        DashboardSnapshot(
          plotCount: results[0],
          openQueries: results[1],
          appointments: results[2],
          unreadNotifications: results[3],
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isStatsLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.royalBlue,
        title: const Text(
          'RoyalNest',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          StreamBuilder<int>(
            stream: _notificationService.getUnreadCount(userId),
            builder: (context, snapshot) {
              final count = snapshot.data ?? 0;
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.notifications_outlined,
                      color: Colors.white,
                    ),
                    onPressed: () =>
                        Navigator.pushNamed(context, '/client-notifications'),
                  ),
                  if (count > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          count > 9 ? '9+' : count.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      drawer: const ClientDrawer(),
      body: RefreshIndicator(
        onRefresh: () => _refreshDashboardStats(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _EntranceReveal(
                delay: const Duration(milliseconds: 20),
                child: _buildWelcomeCard(),
              ),
              const SizedBox(height: 20),
              _EntranceReveal(
                delay: const Duration(milliseconds: 120),
                child: _buildQuickStats(),
              ),
              const SizedBox(height: 20),
              _EntranceReveal(
                delay: const Duration(milliseconds: 220),
                child: _buildUpcomingPayment(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(AppTheme.largeRadius),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: _buildUserAvatar(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$_greeting, $_firstName',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      userName,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.88),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 16,
                          color: Colors.white.withValues(alpha: 0.88),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _defaultCity,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.88),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.white70, size: 18),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Track your plots, appointments, documents and lost & found requests from one dashboard.',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    final actions = <_OverviewAction>[
      _OverviewAction(
        label: 'My Plots',
        value: _isStatsLoading ? null : '$_plotCount',
        icon: Icons.landscape_outlined,
        color: const Color(0xFF1F6FEB),
        route: '/client-plots',
      ),
      _OverviewAction(
        label: 'Open Queries',
        value: _isStatsLoading ? null : '$_openQueries',
        icon: Icons.help_outline,
        color: const Color(0xFFE67E22),
        route: '/client-queries',
      ),
      _OverviewAction(
        label: 'Appointments',
        value: _isStatsLoading ? null : '$_appointments',
        icon: Icons.event_available_outlined,
        color: const Color(0xFF6C5CE7),
        route: '/client-appointments',
      ),
      _OverviewAction(
        label: 'Payments',
        value: _isStatsLoading ? null : 'Open',
        icon: Icons.payments_outlined,
        color: const Color(0xFF2D9C5B),
        route: '/client-payments',
      ),
      _OverviewAction(
        label: 'Documents',
        value: _isStatsLoading ? null : 'Upload',
        icon: Icons.folder_open_outlined,
        color: const Color(0xFF0F7DA0),
        route: '/client-documents',
      ),
      _OverviewAction(
        label: 'Lost & Found',
        value: _isStatsLoading ? null : 'Open',
        icon: Icons.search,
        color: const Color(0xFF16A085),
        route: '/client-lost-found',
      ),
      _OverviewAction(
        label: 'Notifications',
        value: _isStatsLoading ? null : 'View',
        icon: Icons.notifications_none,
        color: const Color(0xFFEB5757),
        route: '/client-notifications',
      ),
      _OverviewAction(
        label: 'Profile',
        value: _isStatsLoading ? null : 'Manage',
        icon: Icons.person_outline,
        color: const Color(0xFF3D5AFE),
        route: '/client-profile',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Overview',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          _isUsingCachedStats
              ? 'Refreshing latest stats...'
              : 'Quick actions across your account',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        _buildOverviewGrid(actions),
      ],
    );
  }

  Widget _buildOverviewGrid(List<_OverviewAction> actions) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: actions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final action = actions[index];
        return _OverviewActionTile(
          action: action,
          index: index,
          isLoading: _isStatsLoading,
          onTap: () => Navigator.pushNamed(context, action.route),
        );
      },
    );
  }

  Widget _buildUserAvatar() {
    final photoUrl = userPhotoUrl;
    if (photoUrl != null && photoUrl.trim().isNotEmpty) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: photoUrl,
          width: 46,
          height: 46,
          fit: BoxFit.cover,
          placeholder: (context, url) => const SizedBox(
            width: 46,
            height: 46,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          errorWidget: (context, url, error) =>
              const Icon(Icons.person, color: Colors.white),
        ),
      );
    }

    return Container(
      width: 46,
      height: 46,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          _firstName.substring(0, 1).toUpperCase(),
          style: const TextStyle(
            color: AppTheme.royalBlue,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _buildUpcomingPayment() {
    return FutureBuilder(
      future: _paymentService.getNextPaymentDue(userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return const SizedBox.shrink();
        }

        final payment = snapshot.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Upcoming Payment',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.payment, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          payment['plotDetails'] ?? 'Plot Payment',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Due: ${_formatDate(payment['dueDate'])}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _formatAmount(payment['amount'] ?? 0),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.orange,
                        ),
                      ),
                      TextButton(
                        onPressed: () =>
                            Navigator.pushNamed(context, '/client-payments'),
                        child: const Text('View Details'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    if (date is DateTime) {
      return '${date.day}/${date.month}/${date.year}';
    }
    return date.toString();
  }

  String _formatAmount(dynamic amount) {
    final value = (amount is num) ? amount.toDouble() : 0.0;
    if (value >= 10000000) {
      return 'PKR ${(value / 10000000).toStringAsFixed(2)} Cr';
    } else if (value >= 100000) {
      return 'PKR ${(value / 100000).toStringAsFixed(2)} L';
    }
    return 'PKR ${value.toStringAsFixed(0)}';
  }
}

class _EntranceReveal extends StatefulWidget {
  const _EntranceReveal({required this.child, required this.delay});

  final Widget child;
  final Duration delay;

  @override
  State<_EntranceReveal> createState() => _EntranceRevealState();
}

class _EntranceRevealState extends State<_EntranceReveal> {
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

class _ShimmerBox extends StatefulWidget {
  const _ShimmerBox({
    required this.width,
    required this.height,
    this.radius = 8,
  });

  final double width;
  final double height;
  final double radius;

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        final t = _controller.value;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(-1 + (2 * t), -0.2),
              end: Alignment(1 + (2 * t), 0.2),
              colors: [
                Colors.grey.shade200,
                Colors.grey.shade100,
                Colors.grey.shade200,
              ],
              stops: const [0.15, 0.5, 0.85],
            ),
          ),
        );
      },
    );
  }
}

class _OverviewAction {
  const _OverviewAction({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.route,
  });

  final String label;
  final String? value;
  final IconData icon;
  final Color color;
  final String route;
}

class _OverviewActionTile extends StatefulWidget {
  const _OverviewActionTile({
    required this.action,
    required this.index,
    required this.isLoading,
    required this.onTap,
  });

  final _OverviewAction action;
  final int index;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  State<_OverviewActionTile> createState() => _OverviewActionTileState();
}

class _OverviewActionTileState extends State<_OverviewActionTile> {
  bool _visible = false;
  bool _hovered = false;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: 140 + widget.index * 60), () {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.lightShadow,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            _ShimmerBox(width: 34, height: 34, radius: 12),
            SizedBox(height: 10),
            _ShimmerBox(width: 56, height: 10, radius: 6),
            SizedBox(height: 6),
            _ShimmerBox(width: 40, height: 10, radius: 6),
          ],
        ),
      );
    }

    final action = widget.action;
    final isInteractive = !_pressed && !_hovered;
    final shadowColor = action.color.withValues(alpha: 0.18);
    final baseShadow = BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 14,
      offset: const Offset(0, 8),
    );
    final liftedShadow = BoxShadow(
      color: shadowColor,
      blurRadius: 20,
      offset: const Offset(0, 12),
    );
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      opacity: _visible ? 1 : 0,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
        offset: _visible ? Offset.zero : const Offset(0, 0.08),
        child: MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            onTapDown: (_) => setState(() => _pressed = true),
            onTapUp: (_) => setState(() => _pressed = false),
            onTapCancel: () => setState(() => _pressed = false),
            child: AnimatedScale(
              scale: _pressed
                  ? 0.98
                  : _hovered
                  ? 1.03
                  : 1.0,
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOut,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: Colors.white,
                  border: Border.all(
                    color: action.color.withValues(
                      alpha: _hovered ? 0.35 : 0.2,
                    ),
                  ),
                  boxShadow: [isInteractive ? baseShadow : liftedShadow],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: widget.onTap,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: action.color.withValues(
                                alpha: _hovered ? 0.18 : 0.12,
                              ),
                              shape: BoxShape.circle,
                              boxShadow: _hovered
                                  ? [
                                      BoxShadow(
                                        color: shadowColor,
                                        blurRadius: 12,
                                        offset: const Offset(0, 6),
                                      ),
                                    ]
                                  : [],
                            ),
                            child: Icon(
                              action.icon,
                              color: action.color,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  action.label,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  action.value ?? '...',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            size: 20,
                            color: Colors.grey.shade400,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
