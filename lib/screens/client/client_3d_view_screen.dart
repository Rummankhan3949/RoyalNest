import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/location_node.dart';

/// Virtual Visit screen with society selection + single-screen walkthrough.
class Client3DViewScreen extends StatefulWidget {
  const Client3DViewScreen({super.key});

  @override
  State<Client3DViewScreen> createState() => _Client3DViewScreenState();
}

class _Client3DViewScreenState extends State<Client3DViewScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  final TransformationController _transformationController =
      TransformationController();

  final List<_SocietyOption> _societies = const [
    _SocietyOption(
      id: 'royal_smart_city',
      name: 'Royal Smart City',
      subtitle: 'Premium smart lifestyle community',
      coverImagePath: 'assets/images/tour/entrance.jpg',
      accentColor: Color(0xFF2F80ED),
    ),
    _SocietyOption(
      id: 'royal_city',
      name: 'Royal City',
      subtitle: 'Nature-first plots and boulevards',
      coverImagePath: 'assets/images/tour/main_road.jpg',
      accentColor: Color(0xFF2D9C5B),
    ),
    _SocietyOption(
      id: 'royal_homes',
      name: 'Royal Homes',
      subtitle: 'Modern living with smart planning',
      coverImagePath: 'assets/images/tour/park_area.jpg',
      accentColor: Color(0xFFE67E22),
    ),
  ];

  final Map<String, LocationNode> _locations = {
    'entrance': const LocationNode(
      id: 'entrance',
      title: 'Society Entrance',
      imagePath: 'assets/images/tour/entrance.jpg',
      hotspots: [
        TourHotspot(
          x: 0.5,
          y: 0.78,
          targetId: 'main_gate',
          label: 'Move to Main Gate',
          icon: 'forward',
        ),
      ],
    ),
    'main_gate': const LocationNode(
      id: 'main_gate',
      title: 'Main Gate',
      imagePath: 'assets/images/tour/main_gate.jpg',
      hotspots: [
        TourHotspot(
          x: 0.53,
          y: 0.67,
          targetId: 'main_road',
          label: 'Enter Main Road',
          icon: 'forward',
        ),
        TourHotspot(
          x: 0.24,
          y: 0.66,
          targetId: 'entrance',
          label: 'Back to Entrance',
          icon: 'back',
        ),
      ],
    ),
    'main_road': const LocationNode(
      id: 'main_road',
      title: 'Main Road',
      imagePath: 'assets/images/tour/main_road.jpg',
      hotspots: [
        TourHotspot(
          x: 0.5,
          y: 0.55,
          targetId: 'residential_block',
          label: 'Go to Residential Block',
          icon: 'forward',
        ),
        TourHotspot(
          x: 0.72,
          y: 0.58,
          targetId: 'commercial_boulevard',
          label: 'Visit Commercial Boulevard',
          icon: 'right',
        ),
        TourHotspot(
          x: 0.3,
          y: 0.58,
          targetId: 'main_gate',
          label: 'Back to Main Gate',
          icon: 'back',
        ),
      ],
    ),
    'residential_block': const LocationNode(
      id: 'residential_block',
      title: 'Residential Block',
      imagePath: 'assets/images/tour/residential_block.jpg',
      hotspots: [
        TourHotspot(
          x: 0.51,
          y: 0.52,
          targetId: 'plot_corridor',
          label: 'Move to Plot Corridor',
          icon: 'forward',
        ),
        TourHotspot(
          x: 0.34,
          y: 0.63,
          targetId: 'main_road',
          label: 'Back to Main Road',
          icon: 'back',
        ),
      ],
    ),
    'plot_corridor': const LocationNode(
      id: 'plot_corridor',
      title: 'Plot Corridor',
      imagePath: 'assets/images/tour/plot_corridor.jpg',
      hotspots: [
        TourHotspot(
          x: 0.2,
          y: 0.48,
          targetId: 'park_area',
          label: 'Walk to Park Area',
          icon: 'right',
        ),
        TourHotspot(
          x: 0.58,
          y: 0.7,
          targetId: 'residential_block',
          label: 'Return to Residential Block',
          icon: 'back',
        ),
      ],
    ),
    'park_area': const LocationNode(
      id: 'park_area',
      title: 'Park Area',
      imagePath: 'assets/images/tour/park_area.jpg',
      hotspots: [
        TourHotspot(
          x: 0.5,
          y: 0.58,
          targetId: 'mosque_view',
          label: 'Move to Mosque View',
          icon: 'forward',
        ),
        TourHotspot(
          x: 0.22,
          y: 0.64,
          targetId: 'plot_corridor',
          label: 'Back to Plots',
          icon: 'left',
        ),
      ],
    ),
    'commercial_boulevard': const LocationNode(
      id: 'commercial_boulevard',
      title: 'Commercial Boulevard',
      imagePath: 'assets/images/tour/commercial_boulevard.jpg',
      hotspots: [
        TourHotspot(
          x: 0.16,
          y: 0.68,
          targetId: 'main_road',
          label: 'Back to Main Road',
          icon: 'left',
        ),
        TourHotspot(
          x: 0.85,
          y: 0.68,
          targetId: 'exit_gate',
          label: 'Move toward Exit Gate',
          icon: 'forward',
        ),
      ],
    ),
    'mosque_view': const LocationNode(
      id: 'mosque_view',
      title: 'Mosque View',
      imagePath: 'assets/images/tour/mosque_view.jpg',
      hotspots: [
        TourHotspot(
          x: 0.28,
          y: 0.66,
          targetId: 'park_area',
          label: 'Back to Park Area',
          icon: 'back',
        ),
        TourHotspot(
          x: 0.74,
          y: 0.56,
          targetId: 'exit_gate',
          label: 'Continue to Exit',
          icon: 'right',
        ),
      ],
    ),
    'exit_gate': const LocationNode(
      id: 'exit_gate',
      title: 'Exit Gate',
      imagePath: 'assets/images/tour/exit_gate.jpg',
      hotspots: [
        TourHotspot(
          x: 0.5,
          y: 0.72,
          targetId: 'main_road',
          label: 'Back to Main Road',
          icon: 'left',
        ),
        TourHotspot(
          x: 0.5,
          y: 0.2,
          targetId: 'entrance',
          label: 'Restart Tour',
          icon: 'refresh',
        ),
      ],
    ),
  };

  _SocietyOption? _selectedSociety;
  String _currentLocationId = 'entrance';
  final List<String> _history = [];
  bool _didPrecache = false;

  LocationNode get _currentLocation => _locations[_currentLocationId]!;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didPrecache) {
      return;
    }

    _didPrecache = true;
    for (final location in _locations.values) {
      precacheImage(AssetImage(location.imagePath), context);
    }
    for (final society in _societies) {
      precacheImage(AssetImage(society.coverImagePath), context);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  void _selectSociety(_SocietyOption society) {
    setState(() {
      _selectedSociety = society;
      _currentLocationId = 'entrance';
      _history.clear();
      _transformationController.value = Matrix4.identity();
    });
  }

  void _moveTo(String targetId) {
    if (!_locations.containsKey(targetId) || targetId == _currentLocationId) {
      return;
    }

    setState(() {
      _history.add(_currentLocationId);
      _currentLocationId = targetId;
      _transformationController.value = Matrix4.identity();
    });
  }

  void _onAppBarBackPressed() {
    if (_selectedSociety == null) {
      _exitScreen();
      return;
    }

    if (_history.isNotEmpty) {
      setState(() {
        _currentLocationId = _history.removeLast();
        _transformationController.value = Matrix4.identity();
      });
      return;
    }

    setState(() {
      _selectedSociety = null;
      _currentLocationId = 'entrance';
      _history.clear();
      _transformationController.value = Matrix4.identity();
    });
  }

  void _exitScreen() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }

    Navigator.of(context).pushReplacementNamed('/client-main');
  }

  @override
  Widget build(BuildContext context) {
    final selectedSociety = _selectedSociety;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: AppTheme.royalBlue,
        foregroundColor: Colors.white,
        leading: IconButton(
          onPressed: _onAppBarBackPressed,
          icon: Icon(
            selectedSociety == null
                ? Icons.close
                : (_history.isEmpty ? Icons.arrow_back : Icons.arrow_back_ios),
          ),
          tooltip: selectedSociety == null ? 'Exit' : 'Back',
        ),
        title: Text(selectedSociety?.name ?? 'Select Society'),
        actions: [
          if (selectedSociety != null)
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _selectedSociety = null;
                  _currentLocationId = 'entrance';
                  _history.clear();
                  _transformationController.value = Matrix4.identity();
                });
              },
              icon: const Icon(Icons.swap_horiz, color: Colors.white, size: 18),
              label: const Text(
                'Change',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 450),
        switchInCurve: Curves.easeInOutCubic,
        switchOutCurve: Curves.easeInOutCubic,
        transitionBuilder: (child, animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: selectedSociety == null
            ? _buildSocietySelector()
            : _buildTourContent(selectedSociety),
      ),
    );
  }

  Widget _buildSocietySelector() {
    return LayoutBuilder(
      key: const ValueKey<String>('selector'),
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width >= 1000
            ? 3
            : width >= 680
            ? 2
            : 1;

        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0E1322), Color(0xFF15294B)],
            ),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                  child: Text(
                    'Choose a society to start your virtual walkthrough',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.94),
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: crossAxisCount == 1 ? 1.08 : 1.05,
                    ),
                    itemCount: _societies.length,
                    itemBuilder: (context, index) {
                      final society = _societies[index];
                      return _SocietyCard(
                        society: society,
                        onTap: () => _selectSociety(society),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTourContent(_SocietyOption selectedSociety) {
    final location = _currentLocation;

    return LayoutBuilder(
      key: ValueKey<String>('tour-${selectedSociety.id}'),
      builder: (context, constraints) {
        return Stack(
          fit: StackFit.expand,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              switchInCurve: Curves.easeInOutCubic,
              switchOutCurve: Curves.easeInOutCubic,
              transitionBuilder: (child, animation) {
                return FadeTransition(opacity: animation, child: child);
              },
              child: InteractiveViewer(
                key: ValueKey<String>('${selectedSociety.id}_${location.id}'),
                transformationController: _transformationController,
                minScale: 0.9,
                maxScale: 4.0,
                boundaryMargin: const EdgeInsets.all(120),
                panEnabled: true,
                child: SizedBox.expand(
                  child: Image.asset(
                    location.imagePath,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.medium,
                    gaplessPlayback: true,
                  ),
                ),
              ),
            ),
            ...location.hotspots.map(
              (hotspot) => Positioned(
                left: _normalizedToViewport(hotspot.x, constraints.maxWidth),
                top: _normalizedToViewport(hotspot.y, constraints.maxHeight),
                child: _HotspotButton(
                  pulseAnimation: _pulseController,
                  icon: _iconForHotspot(hotspot.icon),
                  label: hotspot.label,
                  color: selectedSociety.accentColor,
                  onTap: () => _moveTo(hotspot.targetId),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  IconData _iconForHotspot(String iconType) {
    switch (iconType) {
      case 'left':
        return Icons.arrow_circle_left_outlined;
      case 'right':
        return Icons.arrow_circle_right_outlined;
      case 'back':
        return Icons.arrow_circle_up_outlined;
      case 'refresh':
        return Icons.restart_alt;
      default:
        return Icons.arrow_circle_up_outlined;
    }
  }

  double _normalizedToViewport(double value, double size) {
    if (size <= 56) {
      return 0;
    }

    final mapped = (value * size) - 24;
    return math.max(4, math.min(size - 52, mapped));
  }
}

class _SocietyCard extends StatelessWidget {
  const _SocietyCard({required this.society, required this.onTap});

  final _SocietyOption society;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 20,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(society.coverImagePath, fit: BoxFit.cover),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.1),
                        Colors.black.withValues(alpha: 0.6),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 14,
                  right: 14,
                  bottom: 14,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        society.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        society.subtitle,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: society.accentColor.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'Start Virtual Visit',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HotspotButton extends StatelessWidget {
  const _HotspotButton({
    required this.pulseAnimation,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final Animation<double> pulseAnimation;
  final IconData icon;
  final String? label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseAnimation,
      builder: (context, child) {
        final glow = 0.7 + (pulseAnimation.value * 0.3);

        return Semantics(
          button: true,
          label: label ?? 'Move to next location',
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(28),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.2),
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: glow),
                    blurRadius: 22,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
          ),
        );
      },
    );
  }
}

class _SocietyOption {
  const _SocietyOption({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.coverImagePath,
    required this.accentColor,
  });

  final String id;
  final String name;
  final String subtitle;
  final String coverImagePath;
  final Color accentColor;
}
