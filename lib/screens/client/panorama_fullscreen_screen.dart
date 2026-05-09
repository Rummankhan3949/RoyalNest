import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:panorama_viewer/panorama_viewer.dart';

import '../../models/panorama_scene.dart';

// ── Connected Tour Screen ────────────────────────────────────────

/// Full connected virtual tour with hotspot navigation between scenes.
class PanoramaFullscreenScreen extends StatefulWidget {
  const PanoramaFullscreenScreen({
    super.key,
    required this.scenes,
    required this.societyName,
    required this.accentColor,
    this.startSceneIndex = 0,
  });

  final List<TourScene> scenes;
  final String societyName;
  final Color accentColor;
  final int startSceneIndex;

  @override
  State<PanoramaFullscreenScreen> createState() =>
      _PanoramaFullscreenScreenState();
}

class _PanoramaFullscreenScreenState extends State<PanoramaFullscreenScreen>
    with TickerProviderStateMixin {
  late int _currentIndex;
  bool _isLoading = true;
  bool _showHint = true;
  bool _showControls = true;
  bool _isTransitioning = false;
  bool _showSceneList = false;
  double _currentZoom = 1.0;

  late final AnimationController _hintPulseController;
  late final AnimationController _transitionController;
  late final Animation<double> _hintOpacity;

  Timer? _controlsTimer;
  Timer? _hintTimer;

  TourScene get _currentScene => widget.scenes[_currentIndex];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.startSceneIndex.clamp(0, widget.scenes.length - 1);

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _hintPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _hintOpacity = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _hintPulseController, curve: Curves.easeInOut),
    );

    _transitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _hintTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _showHint = false);
    });

    _startControlsTimer();
  }

  @override
  void dispose() {
    _controlsTimer?.cancel();
    _hintTimer?.cancel();
    _hintPulseController.dispose();
    _transitionController.dispose();
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    super.dispose();
  }

  void _startControlsTimer() {
    _controlsTimer?.cancel();
    _controlsTimer = Timer(const Duration(seconds: 6), () {
      if (mounted) setState(() => _showControls = false);
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
      if (!_showControls) _showSceneList = false;
    });
    if (_showControls) _startControlsTimer();
  }

  /// Navigate to a connected scene with a smooth transition.
  void _navigateToScene(String targetId) {
    if (_isTransitioning) return;
    final idx = widget.scenes.indexWhere((s) => s.id == targetId);
    if (idx < 0 || idx == _currentIndex) return;

    setState(() {
      _isTransitioning = true;
      _showHint = false;
    });

    _transitionController.forward(from: 0).then((_) {
      if (!mounted) return;
      setState(() {
        _currentIndex = idx;
        _currentZoom = 1.0;
        _isLoading = true;
      });
      _transitionController.reverse().then((_) {
        if (mounted) setState(() => _isTransitioning = false);
      });
    });
  }

  void _jumpToScene(int index) {
    if (_isTransitioning || index == _currentIndex) return;
    setState(() => _showSceneList = false);
    final scene = widget.scenes[index];
    _navigateToScene(scene.id);
  }

  void _onImageLoaded() {
    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleControls,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Panorama sphere
            _buildPanorama(),

            // Transition overlay
            AnimatedBuilder(
              animation: _transitionController,
              builder: (_, __) {
                final v = _transitionController.value;
                if (v == 0) return const SizedBox.shrink();
                return Container(color: Colors.black.withValues(alpha: v));
              },
            ),

            // Loading
            if (_isLoading) _buildLoadingOverlay(),

            // Top bar
            _buildTopOverlay(),

            // Swipe hint
            if (_showHint && !_isLoading) _buildSwipeHint(),

            // Bottom bar with scene nav + zoom
            _buildBottomBar(),

            // Scene list panel
            if (_showSceneList) _buildSceneListPanel(),
          ],
        ),
      ),
    );
  }

  Widget _buildPanorama() {
    final scene = _currentScene;
    final hotspots = scene.connections.map((conn) {
      return Hotspot(
        latitude: conn.latitude,
        longitude: conn.longitude,
        width: 160,
        height: 80,
        widget: _HotspotWidget(
          icon: conn.icon,
          accentColor: widget.accentColor,
          onTap: () => _navigateToScene(conn.targetSceneId),
        ),
      );
    }).toList();

    return PanoramaViewer(
      key: ValueKey<String>('pano_${scene.id}'),
      animSpeed: 0.3,
      sensorControl: SensorControl.orientation,
      minZoom: 0.5,
      maxZoom: 3.0,
      zoom: _currentZoom,
      sensitivity: 1.8,
      hotspots: hotspots,
      onImageLoad: _onImageLoaded,
      onViewChanged: (lon, lat, tilt) {
        if (_showHint && mounted) setState(() => _showHint = false);
      },
      child: scene.isAsset
          ? Image.asset(scene.imagePath, fit: BoxFit.cover)
          : Image.network(scene.imagePath, fit: BoxFit.cover),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _PanoramaLoadingIndicator(color: widget.accentColor),
            const SizedBox(height: 24),
            Text(
              'Loading Scene',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.societyName,
              style: TextStyle(
                color: widget.accentColor.withValues(alpha: 0.8),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopOverlay() {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      top: _showControls ? 0 : -120,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.7),
              Colors.black.withValues(alpha: 0.2),
              Colors.transparent,
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 12, 20),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.societyName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.view_in_ar,
                            color: widget.accentColor,
                            size: 13,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Scene ${_currentIndex + 1}/${widget.scenes.length}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.65),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: widget.accentColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: widget.accentColor.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.threesixty,
                        color: widget.accentColor,
                        size: 14,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '360°',
                        style: TextStyle(
                          color: widget.accentColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
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

  Widget _buildSwipeHint() {
    return Positioned.fill(
      child: IgnorePointer(
        child: Center(
          child: AnimatedBuilder(
            animation: _hintPulseController,
            builder: (_, __) => Opacity(
              opacity: _hintOpacity.value,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.swipe,
                      color: Colors.white.withValues(alpha: 0.9),
                      size: 26,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Swipe to Explore',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.95),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    final canPrev = _currentIndex > 0;
    final canNext = _currentIndex < widget.scenes.length - 1;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      bottom: _showControls ? 0 : -140,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withValues(alpha: 0.75),
              Colors.black.withValues(alpha: 0.3),
              Colors.transparent,
            ],
          ),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Scene thumbnail strip
              SizedBox(
                height: 52,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: widget.scenes.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final scene = widget.scenes[i];
                    final isActive = i == _currentIndex;
                    return GestureDetector(
                      onTap: () => _jumpToScene(i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: isActive ? 80 : 52,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isActive
                                ? widget.accentColor
                                : Colors.white24,
                            width: isActive ? 2 : 1,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.asset(
                                scene.imagePath,
                                fit: BoxFit.cover,
                                gaplessPlayback: true,
                                errorBuilder: (_, __, ___) => Container(
                                  color: Colors.grey[900],
                                  child: Icon(
                                    scene.icon,
                                    color: Colors.white24,
                                    size: 16,
                                  ),
                                ),
                              ),
                              if (isActive)
                                Container(
                                  color: widget.accentColor.withValues(
                                    alpha: 0.15,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              // Navigation + zoom controls
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: Row(
                  children: [
                    // Previous
                    _NavButton(
                      icon: Icons.arrow_back_ios_rounded,
                      enabled: canPrev,
                      color: widget.accentColor,
                      onTap: canPrev
                          ? () => _navigateToScene(
                              widget.scenes[_currentIndex - 1].id,
                            )
                          : null,
                    ),
                    const Spacer(),
                    // Zoom out
                    _ZoomBtn(
                      icon: Icons.zoom_out,
                      onTap: () => setState(
                        () =>
                            _currentZoom = (_currentZoom - 0.3).clamp(0.5, 3.0),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Scene list toggle
                    GestureDetector(
                      onTap: () {
                        setState(() => _showSceneList = !_showSceneList);
                        _startControlsTimer();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: widget.accentColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: widget.accentColor.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.map_outlined,
                              color: widget.accentColor,
                              size: 16,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'Scenes',
                              style: TextStyle(
                                color: widget.accentColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Zoom in
                    _ZoomBtn(
                      icon: Icons.zoom_in,
                      onTap: () => setState(
                        () =>
                            _currentZoom = (_currentZoom + 0.3).clamp(0.5, 3.0),
                      ),
                    ),
                    const Spacer(),
                    // Next
                    _NavButton(
                      icon: Icons.arrow_forward_ios_rounded,
                      enabled: canNext,
                      color: widget.accentColor,
                      onTap: canNext
                          ? () => _navigateToScene(
                              widget.scenes[_currentIndex + 1].id,
                            )
                          : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSceneListPanel() {
    return Positioned(
      left: 12,
      right: 12,
      bottom: 145,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 260),
        decoration: BoxDecoration(
          color: const Color(0xE6111827),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
              child: Row(
                children: [
                  Icon(Icons.map, color: widget.accentColor, size: 18),
                  const SizedBox(width: 8),
                  const Text(
                    'Tour Scenes',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => setState(() => _showSceneList = false),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white54,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: Colors.white.withValues(alpha: 0.06)),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: widget.scenes.length,
                itemBuilder: (_, i) {
                  final scene = widget.scenes[i];
                  final isActive = i == _currentIndex;
                  return ListTile(
                    dense: true,
                    visualDensity: VisualDensity.compact,
                    leading: Icon(
                      scene.icon,
                      color: isActive ? widget.accentColor : Colors.white38,
                      size: 20,
                    ),
                    title: Text(
                      'Scene ${i + 1}',
                      style: TextStyle(
                        color: isActive ? widget.accentColor : Colors.white70,
                        fontSize: 13,
                        fontWeight: isActive
                            ? FontWeight.bold
                            : FontWeight.w500,
                      ),
                    ),
                    trailing: isActive
                        ? Icon(
                            Icons.my_location,
                            color: widget.accentColor,
                            size: 16,
                          )
                        : Text(
                            '${i + 1}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.3),
                              fontSize: 12,
                            ),
                          ),
                    onTap: () => _jumpToScene(i),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Hotspot widget ───────────────────────────────────────────────

class _HotspotWidget extends StatefulWidget {
  const _HotspotWidget({
    required this.icon,
    required this.accentColor,
    required this.onTap,
  });
  final IconData icon;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  State<_HotspotWidget> createState() => _HotspotWidgetState();
}

class _HotspotWidgetState extends State<_HotspotWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (_, __) {
          final glow = 0.3 + _pulse.value * 0.5;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: widget.accentColor.withValues(
                  alpha: 0.5 + _pulse.value * 0.3,
                ),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.accentColor.withValues(alpha: glow * 0.4),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(widget.icon, color: widget.accentColor, size: 18),
          );
        },
      ),
    );
  }
}

// ── Nav buttons ──────────────────────────────────────────────────

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.icon,
    required this.enabled,
    required this.color,
    this.onTap,
  });
  final IconData icon;
  final bool enabled;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: enabled
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.white.withValues(alpha: 0.04),
          border: Border.all(color: enabled ? Colors.white30 : Colors.white10),
        ),
        child: Icon(
          icon,
          color: enabled ? Colors.white : Colors.white24,
          size: 18,
        ),
      ),
    );
  }
}

class _ZoomBtn extends StatelessWidget {
  const _ZoomBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.1),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        ),
        child: Icon(icon, color: Colors.white70, size: 18),
      ),
    );
  }
}

// ── Loading indicator ────────────────────────────────────────────

class _PanoramaLoadingIndicator extends StatefulWidget {
  const _PanoramaLoadingIndicator({required this.color});
  final Color color;

  @override
  State<_PanoramaLoadingIndicator> createState() =>
      _PanoramaLoadingIndicatorState();
}

class _PanoramaLoadingIndicatorState extends State<_PanoramaLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => SizedBox(
        width: 72,
        height: 72,
        child: CustomPaint(
          painter: _GlobePainter(progress: _c.value, color: widget.color),
        ),
      ),
    );
  }
}

class _GlobePainter extends CustomPainter {
  _GlobePainter({required this.progress, required this.color});
  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 3;

    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = color.withValues(alpha: 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    final arc = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      progress * math.pi * 2,
      math.pi * 1.2,
      false,
      arc,
    );

    final globe = Paint()
      ..color = color.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    for (int i = 1; i <= 3; i++) {
      final y = c.dy + (i - 2) * r * 0.35;
      final hw = math.sqrt(math.max(0, r * r - (y - c.dy) * (y - c.dy)));
      canvas.drawLine(Offset(c.dx - hw, y), Offset(c.dx + hw, y), globe);
    }
    canvas.drawOval(
      Rect.fromCenter(center: c, width: r * 0.6, height: r * 2),
      globe,
    );

    canvas.drawCircle(
      c,
      2.5,
      Paint()
        ..color = color.withValues(
          alpha: 0.5 + 0.5 * math.sin(progress * math.pi * 2),
        ),
    );
  }

  @override
  bool shouldRepaint(covariant _GlobePainter old) => old.progress != progress;
}
