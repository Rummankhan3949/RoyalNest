import 'package:flutter/material.dart';

/// A single panorama scene in the virtual tour.
class TourScene {
  const TourScene({
    required this.id,
    required this.title,
    required this.imagePath,
    required this.icon,
    this.isAsset = true,
    this.connections = const [],
  });

  final String id;
  final String title;
  final String imagePath;
  final IconData icon;
  final bool isAsset;
  final List<SceneConnection> connections;
}

/// A navigable link from one scene to another, placed at a specific
/// position on the panorama sphere.
class SceneConnection {
  const SceneConnection({
    required this.targetSceneId,
    required this.label,
    required this.latitude,
    required this.longitude,
    this.icon = Icons.arrow_circle_right_outlined,
  });

  final String targetSceneId;
  final String label;
  final double latitude;
  final double longitude;
  final IconData icon;
}
