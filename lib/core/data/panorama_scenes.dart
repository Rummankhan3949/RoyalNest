import 'package:flutter/material.dart';

import '../../models/panorama_scene.dart';

class PanoramaSceneGroup {
  const PanoramaSceneGroup({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.folder,
    required this.accentColor,
    required this.sceneDefs,
  });

  final String id;
  final String name;
  final String subtitle;
  final String folder;
  final Color accentColor;
  final List<PanoramaSceneDefinition> sceneDefs;
}

class PanoramaSceneDefinition {
  const PanoramaSceneDefinition(this.title, this.icon);

  final String title;
  final IconData icon;
}

const List<PanoramaSceneGroup> panoramaScenes = [
  PanoramaSceneGroup(
    id: 'royal_smart_city',
    name: 'Royal Smart City',
    subtitle: 'Premium smart lifestyle community',
    folder: 'royal_smart_city',
    accentColor: Color(0xFF2F80ED),
    sceneDefs: [
      PanoramaSceneDefinition(
        'Society Entrance',
        Icons.door_front_door_outlined,
      ),
      PanoramaSceneDefinition('Main Gate', Icons.door_sliding_outlined),
      PanoramaSceneDefinition('Main Boulevard', Icons.add_road),
      PanoramaSceneDefinition('Residential Block A', Icons.house_outlined),
      PanoramaSceneDefinition('Plot Corridor', Icons.grid_view_rounded),
      PanoramaSceneDefinition('Central Park', Icons.park_outlined),
      PanoramaSceneDefinition('Commercial Area', Icons.storefront_outlined),
      PanoramaSceneDefinition('Mosque View', Icons.mosque_outlined),
      PanoramaSceneDefinition('Exit Gate', Icons.exit_to_app),
    ],
  ),
  PanoramaSceneGroup(
    id: 'royal_city',
    name: 'Royal City',
    subtitle: 'Nature-first plots and boulevards',
    folder: 'royal_city',
    accentColor: Color(0xFF2D9C5B),
    sceneDefs: [
      PanoramaSceneDefinition(
        'Society Entrance',
        Icons.door_front_door_outlined,
      ),
      PanoramaSceneDefinition('Main Gate', Icons.door_sliding_outlined),
      PanoramaSceneDefinition('Main Road', Icons.add_road),
      PanoramaSceneDefinition('Residential Area', Icons.house_outlined),
      PanoramaSceneDefinition('Plot Street', Icons.grid_view_rounded),
      PanoramaSceneDefinition('Green Park', Icons.park_outlined),
      PanoramaSceneDefinition(
        'Commercial Boulevard',
        Icons.storefront_outlined,
      ),
      PanoramaSceneDefinition('Mosque Area', Icons.mosque_outlined),
      PanoramaSceneDefinition('Community Center', Icons.groups_outlined),
      PanoramaSceneDefinition('Exit Gate', Icons.exit_to_app),
    ],
  ),
  PanoramaSceneGroup(
    id: 'royal_homes',
    name: 'Royal Homes',
    subtitle: 'Modern living with smart planning',
    folder: 'royal_homes',
    accentColor: Color(0xFFE67E22),
    sceneDefs: [
      PanoramaSceneDefinition(
        'Society Entrance',
        Icons.door_front_door_outlined,
      ),
      PanoramaSceneDefinition('Main Gate', Icons.door_sliding_outlined),
      PanoramaSceneDefinition('Main Road', Icons.add_road),
      PanoramaSceneDefinition('Block A Residential', Icons.house_outlined),
      PanoramaSceneDefinition('Plot Corridor', Icons.grid_view_rounded),
      PanoramaSceneDefinition('Park & Playground', Icons.park_outlined),
      PanoramaSceneDefinition('Commercial Zone', Icons.storefront_outlined),
      PanoramaSceneDefinition('Mosque View', Icons.mosque_outlined),
      PanoramaSceneDefinition('Community Hall', Icons.groups_outlined),
      PanoramaSceneDefinition('Sports Area', Icons.sports_soccer_outlined),
      PanoramaSceneDefinition('Garden Walk', Icons.nature_outlined),
      PanoramaSceneDefinition('Exit Gate', Icons.exit_to_app),
    ],
  ),
];

String panoramaImagePath(String folder, int index) {
  final imageIndex = (index + 1).toString().padLeft(2, '0');
  return 'assets/tour/$folder/img_$imageIndex.jpg';
}

List<TourScene> buildTourScenes(PanoramaSceneGroup group) {
  return group.sceneDefs.asMap().entries.map((entry) {
    final i = entry.key;
    final def = entry.value;
    final connections = <SceneConnection>[];

    if (i > 0) {
      connections.add(
        SceneConnection(
          targetSceneId: '${group.id}_${i - 1}',
          label: '← ${group.sceneDefs[i - 1].title}',
          latitude: -15,
          longitude: 160 + (i % 3) * 10.0,
          icon: Icons.arrow_back_rounded,
        ),
      );
    }

    if (i < group.sceneDefs.length - 1) {
      connections.add(
        SceneConnection(
          targetSceneId: '${group.id}_${i + 1}',
          label: '${group.sceneDefs[i + 1].title} →',
          latitude: -15,
          longitude: -20 + (i % 3) * 10.0,
          icon: Icons.arrow_forward_rounded,
        ),
      );
    }

    return TourScene(
      id: '${group.id}_$i',
      title: def.title,
      imagePath: panoramaImagePath(group.folder, i),
      icon: def.icon,
      connections: connections,
    );
  }).toList();
}

PanoramaSceneGroup? findPanoramaGroupByName(String societyName) {
  final normalized = societyName.trim().toLowerCase();
  for (final group in panoramaScenes) {
    if (group.name.trim().toLowerCase() == normalized) {
      return group;
    }
  }
  return null;
}
