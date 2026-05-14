// lib/models/animal_config.dart
//
// Static configuration for each animal — frame counts, positions,
// and which asset files to use for each state.
//
// POSITIONS: expressed as fractions (0.0–1.0) of screen width/height.
// These must be calibrated against the actual background artwork.
// The values below are reasonable starting estimates — adjust after
// seeing the animals overlaid on the real background images.

import 'package:flutter/material.dart';

class AnimalConfig {
  /// Name key — must match the asset file name pattern.
  final String name;

  /// Number of frames in the AWAKE sprite sheet.
  final int awakeFrameCount;

  /// Number of frames in the SLEEPING sprite sheet.
  final int sleepingFrameCount;

  /// Position as fraction of screen dimensions.
  /// (0.0, 0.0) = top-left corner, (1.0, 1.0) = bottom-right corner.
  final Offset scenePosition;

  /// Display width in logical pixels at full size.
  final double displayWidth;

  /// Minimum stage for this animal to appear (1, 2, or 3).
  final int minStage;

  /// Frames per second for the awake animation.
  final double awakeFps;

  /// Frames per second for the sleeping animation.
  final double sleepingFps;

  const AnimalConfig({
    required this.name,
    required this.awakeFrameCount,
    required this.sleepingFrameCount,
    required this.scenePosition,
    required this.displayWidth,
    required this.minStage,
    this.awakeFps = 10,
    this.sleepingFps = 4,
  });

  // ── Asset path helpers ─────────────────────────────────────────

  /// Returns the awake sprite sheet path for a given time of day.
  /// NOTE: Currently only dusk variant exists for bird; day for fish/otter.
  /// When the illustrator provides all variants, update the logic here.
  String awakeAssetPath(String timeOfDay) {
    // Bird: only dusk awake sheet exists so far
    if (name == 'bird') {
      return 'assets/animals/awake/dusk/bird_awake_sheet_dusk.png';
    }
    // Otter: day awake sheet exists
    if (name == 'otter') {
      return 'assets/animals/awake/day/otter_awake_sheet.png';
    }
    // Fish: day awake sheet (fish1)
    if (name == 'fish') {
      return 'assets/animals/awake/day/fish1_awake_sheet.png';
    }
    // For rabbit, duck, deer — awake sheets pending from illustrator.
    // Fallback to sleeping sheet so the code doesn't crash.
    return sleepingAssetPath(timeOfDay);
  }

  /// Returns the sleeping sprite sheet path for a given time of day.
  String sleepingAssetPath(String timeOfDay) {
    final suffix = (timeOfDay == 'night') ? '_night' : '';
    switch (name) {
      case 'fish':
        // fish1_sleeping_sheet_night.png exists; day version missing — use fish2
        return (timeOfDay == 'night')
            ? 'assets/animals/sleeping/night/fish1_sleeping_sheet_night.png'
            : 'assets/animals/sleeping/day/fish2_sleeping_sheet.png';
      case 'bird':
        return (timeOfDay == 'night')
            ? 'assets/animals/sleeping/night/bird_sleeping_sheet_night.png'
            : 'assets/animals/sleeping/day/bird_sleeping_sheet.png';
      case 'rabbit':
        return (timeOfDay == 'night')
            ? 'assets/animals/sleeping/night/rabbit_sleeping_sheet_night.png'
            : 'assets/animals/sleeping/day/rabbit_sleeping_sheet.png';
      case 'duck':
        return (timeOfDay == 'night')
            ? 'assets/animals/sleeping/night/duck_sleeping_sheet_night.png'
            : 'assets/animals/sleeping/day/duck_sleeping_sheet.png';
      case 'otter':
        return (timeOfDay == 'night')
            ? 'assets/animals/sleeping/night/otter_sleeping_sheet_night.png'
            : 'assets/animals/sleeping/day/otter_sleeping_sheet.png';
      case 'deer':
        return (timeOfDay == 'night')
            ? 'assets/animals/sleeping/night/deer_sleeping_sheet_night.png'
            : 'assets/animals/sleeping/day/deer_sleeping_sheet.png';
      default:
        return 'assets/animals/sleeping/day/fish2_sleeping_sheet.png';
    }
  }
}

// ─────────────────────────────────────────────────────────────
// All animal configurations
//
// Positions are calibrated estimates — adjust after overlaying
// on the real 3378×4958 background images.
// ─────────────────────────────────────────────────────────────

const Map<String, AnimalConfig> kAnimalConfigs = {
  'fish': AnimalConfig(
    name: 'fish',
    awakeFrameCount: 9, // fish1_awake_sheet.png = 2253x251px → 9 frames
    sleepingFrameCount: 10, // fish2_sleeping_sheet.png = 2176x221px → 10 frames
    scenePosition: Offset(0.38, 0.58), // centre of lake water
    displayWidth: 110,
    minStage: 2,
    awakeFps: 10,
    sleepingFps: 5,
  ),
  'bird': AnimalConfig(
    name: 'bird',
    awakeFrameCount: 6, // bird_awake_sheet_dusk.png = 2781x432px → 6 frames
    sleepingFrameCount: 5, // bird_sleeping_sheet.png = 1651x353px → 5 frames
    scenePosition: Offset(0.70, 0.32), // upper right, on a branch area
    displayWidth: 75,
    minStage: 2,
    awakeFps: 8,
    sleepingFps: 3,
  ),
  'rabbit': AnimalConfig(
    name: 'rabbit',
    awakeFrameCount: 6, // pending from illustrator — using sleeping count
    sleepingFrameCount: 6, // rabbit_sleeping_sheet.png = 2438x433px → 6 frames
    scenePosition: Offset(0.15, 0.68), // lower left meadow area
    displayWidth: 85,
    minStage: 2,
    awakeFps: 8,
    sleepingFps: 3,
  ),
  'duck': AnimalConfig(
    name: 'duck',
    awakeFrameCount: 7, // pending — using sleeping count
    sleepingFrameCount: 7, // duck_sleeping_sheet.png = 3090x413px → 7 frames
    scenePosition: Offset(0.52, 0.53), // lake surface area
    displayWidth: 95,
    minStage: 3,
    awakeFps: 9,
    sleepingFps: 3,
  ),
  'otter': AnimalConfig(
    name: 'otter',
    awakeFrameCount: 15, // otter_awake_sheet.png = 5551x361px → 15 frames
    sleepingFrameCount: 12, // otter_sleeping_sheet.png = 4445x361px → 12 frames
    scenePosition: Offset(0.62, 0.61), // lake edge
    displayWidth: 105,
    minStage: 3,
    awakeFps: 12,
    sleepingFps: 4,
  ),
  'deer': AnimalConfig(
    name: 'deer',
    awakeFrameCount: 6, // pending — using sleeping count
    sleepingFrameCount: 6, // deer_sleeping_sheet.png = 5173x835px → 6 frames
    scenePosition: Offset(0.80, 0.44), // forest edge right side
    displayWidth: 140,
    minStage: 3,
    awakeFps: 7,
    sleepingFps: 3,
  ),
};
