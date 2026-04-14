import 'package:flutter/foundation.dart';

@immutable
class TourHotspot {
  const TourHotspot({
    required this.x,
    required this.y,
    required this.targetId,
    this.label,
    this.icon = 'forward',
  });

  final double x;
  final double y;
  final String targetId;
  final String? label;
  final String icon;
}

@immutable
class LocationNode {
  const LocationNode({
    required this.id,
    required this.imagePath,
    required this.title,
    required this.hotspots,
  });

  final String id;
  final String imagePath;
  final String title;
  final List<TourHotspot> hotspots;
}
