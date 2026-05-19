// lib/models/animal_config.dart
//
// ─── POSITION CALIBRATION ────────────────────────────────────────────────────
//
// The background image is 3378×4958px displayed with BoxFit.cover on a
// 393×852 iPhone screen.
//
// Water region (from pixel analysis of stage3_water_high.png):
//   Upper water centre: screen_x ≈ 60-65% at y=38%
//   Mid water centre:   screen_x ≈ 44-52% at y=50-55%
//   Lower water centre: screen_x ≈ 47-61% at y=62-66%
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

/// Direction a flying animal travels across the screen.
enum FlightDirection { leftToRight, rightToLeft }

// ─────────────────────────────────────────────────────────────
// FlightPath — describes ONE bird's flight across the screen
//
// All x values are fractions of screen WIDTH (0 = left edge, 1 = right edge).
// All y values are fractions of screen HEIGHT (0 = top, 1 = bottom).
// Values can be negative or > 1 to spawn fully off-screen.
//
// Examples:
//   • Full traversal at altitude 0.30:
//       FlightPath(startX: 1.1, endX: -0.1, y: 0.30)
//   • Partial traversal across the upper-left quadrant only:
//       FlightPath(startX: 0.55, endX: -0.1, y: 0.20)
//   • Right-to-left from off-screen to centre, then disappear:
//       FlightPath(startX: 1.1, endX: 0.35, y: 0.45)
// ─────────────────────────────────────────────────────────────

@immutable
class FlightPath {
  /// Where the bird ENTERS, as a fraction of screen width.
  final double startX;

  /// Where the bird EXITS, as a fraction of screen width.
  final double endX;

  /// Constant flight altitude — fraction of screen height.
  final double y;

  /// Duration of one full traversal start→end, in milliseconds.
  /// Lower = faster bird. Slight per-copy variation = natural flock feel.
  final int durationMs;

  /// Time off-screen between flights for THIS path, in milliseconds.
  final int restMs;

  const FlightPath({
    required this.startX,
    required this.endX,
    required this.y,
    this.durationMs = 7500,
    this.restMs = 4000,
  });

  /// Implicit direction — derived from startX vs endX.
  /// Used to decide which side of the screen the bird disappears past.
  FlightDirection get direction =>
      endX < startX ? FlightDirection.rightToLeft : FlightDirection.leftToRight;
}

// ─────────────────────────────────────────────────────────────
// AnimalConfig
// ─────────────────────────────────────────────────────────────

class AnimalConfig {
  final String name;

  final int awakeFrameCount;
  final int sleepingFrameCount;

  /// Default fixed position (fraction of screen).
  /// Used when count == 1 AND flyAcross == false.
  /// For flying animals when sleeping at night, this is where the bird sits.
  final Offset scenePosition;

  /// Per-copy positions for STATIONARY animals (e.g. multiple fish).
  /// Ignored when flyAcross == true.
  final List<Offset> scenePositions;

  /// How many simultaneous copies of this animal to render.
  final int count;

  /// If true, each copy follows one entry from `flightPaths`.
  final bool flyAcross;

  /// One FlightPath per copy. If `flightPaths.length < count`, paths
  /// cycle (copy N uses flightPaths[N % flightPaths.length]). Each path
  /// has its own entry x, exit x, altitude, duration, and rest period —
  /// so multiple birds genuinely look different.
  final List<FlightPath> flightPaths;

  /// Display width in logical pixels.
  final double displayWidth;

  /// Display height in logical pixels. MUST equal displayWidth × (frame_h / frame_w).
  final double displayHeight;

  final int minStage;
  final double awakeFps;
  final double sleepingFps;

  const AnimalConfig({
    required this.name,
    required this.awakeFrameCount,
    required this.sleepingFrameCount,
    required this.scenePosition,
    required this.displayWidth,
    required this.displayHeight,
    required this.minStage,
    this.scenePositions = const <Offset>[],
    this.count = 1,
    this.flyAcross = false,
    this.flightPaths = const <FlightPath>[],
    this.awakeFps = 10,
    this.sleepingFps = 4,
  });

  // ── Asset path helpers ─────────────────────────────────────────

  String awakeAssetPath(String timeOfDay) {
    switch (name) {
      case 'fish':
        return 'assets/animals/awake/day/fish1_awake_sheet.png';
      case 'otter':
        return 'assets/animals/awake/day/otter_awake_sheet.png';
      case 'bird':
        return 'assets/animals/awake/dusk/bird_awake_sheet_dusk.png';
      case 'rabbit':
      case 'duck':
      case 'deer':
        return sleepingAssetPath(timeOfDay);
      default:
        return sleepingAssetPath(timeOfDay);
    }
  }

  String sleepingAssetPath(String timeOfDay) {
    final isNight = timeOfDay == 'night';
    final folder = isNight ? 'night' : 'day';
    final nightSuffix = isNight ? '_night' : '';

    switch (name) {
      case 'fish':
        return isNight
            ? 'assets/animals/sleeping/night/fish1_sleeping_sheet_night.png'
            : 'assets/animals/sleeping/day/fish2_sleeping_sheet.png';
      case 'bird':
        return 'assets/animals/sleeping/$folder/bird_sleeping_sheet$nightSuffix.png';
      case 'rabbit':
        return 'assets/animals/sleeping/$folder/rabbit_sleeping_sheet$nightSuffix.png';
      case 'duck':
        return 'assets/animals/sleeping/$folder/duck_sleeping_sheet$nightSuffix.png';
      case 'otter':
        return 'assets/animals/sleeping/$folder/otter_sleeping_sheet$nightSuffix.png';
      case 'deer':
        return 'assets/animals/sleeping/$folder/deer_sleeping_sheet$nightSuffix.png';
      default:
        return 'assets/animals/sleeping/day/fish2_sleeping_sheet.png';
    }
  }
}
// ─────────────────────────────────────────────────────────────
// Animal configurations
// ─────────────────────────────────────────────────────────────

const Map<String, AnimalConfig> kAnimalConfigs = {
  // ── FISH — three copies, different positions in the water ────
  'fish': AnimalConfig(
    name: 'fish',
    awakeFrameCount: 8,
    sleepingFrameCount: 8,
    scenePosition: const Offset(0.55, 0.65), // fallback if scenePositions empty
    scenePositions: <Offset>[
      Offset(0.52, 0.65), // mid-right
      Offset(0.45, 0.60), // lower-mid
      Offset(0.60, 0.62), // lower-right
    ],
    count: 3,
    displayWidth: 40,
    displayHeight: 40, // 50 × (251/250) ≈ 50
    minStage: 2,
    awakeFps: 4,
    sleepingFps: 4,
  ),

  // ── BIRD — two birds, DISTINCT flight paths ──────────────────
  //
  // Bird 1: high in the sky, slow, full-screen traversal right→left
  // Bird 2: lower, faster, comes from off-screen-right but exits sooner
  //         (only crosses the upper-right portion of the sky)
  //
  // Different altitudes (y), different x-ranges, different speeds, and
  // different rest periods — so the two birds clearly look like two
  // separate birds with their own flight pattern.
  'bird': AnimalConfig(
    name: 'bird',
    awakeFrameCount: 6,
    sleepingFrameCount: 6,
    scenePosition: const Offset(0.50, 0.35), // used only when sleeping
    count: 2,
    flyAcross: true,
    flightPaths: <FlightPath>[
      // Bird 1 — high altitude, slow, crosses the whole sky
      FlightPath(
        startX: 1.15,
        endX: 0.05,
        y: 0.28,
        durationMs: 9000,
        restMs: 5000,
      ),
      // Bird 2 — lower altitude, faster, only over the right half
      FlightPath(
        startX: 1.15,
        endX: 0.0,
        y: 0.20,
        durationMs: 6000,
        restMs: 3500,
      ),
    ],
    displayWidth: 80,
    displayHeight: 75,
    minStage: 2,
    awakeFps: 3,
    sleepingFps: 1,
  ),

  // ── RABBIT — left ground bank, fixed ─────────────────────────
  'rabbit': AnimalConfig(
    name: 'rabbit',
    awakeFrameCount: 8,
    sleepingFrameCount: 8,
    scenePosition: const Offset(0.15, 0.82),
    displayWidth: 70,
    displayHeight: 75,
    minStage: 2,
    awakeFps: 1,
    sleepingFps: 1,
  ),

  // ── DUCK — water surface, fixed ──────────────────────────────
  'duck': AnimalConfig(
    name: 'duck',
    awakeFrameCount: 8,
    sleepingFrameCount: 8,
    scenePosition: const Offset(0.52, 0.50),
    displayWidth: 65,
    displayHeight: 50,
    minStage: 3,
    awakeFps: 1,
    sleepingFps: 1,
  ),

  // ── OTTER — water, fixed ─────────────────────────────────────
  'otter': AnimalConfig(
    name: 'otter',
    awakeFrameCount: 10,
    sleepingFrameCount: 10,
    scenePosition: const Offset(0.25, 0.55),
    displayWidth: 90,
    displayHeight: 88,
    minStage: 3,
    awakeFps: 1,
    sleepingFps: 1,
  ),

  // ── DEER — right bank, fixed ─────────────────────────────────
  'deer': AnimalConfig(
    name: 'deer',
    awakeFrameCount: 7,
    sleepingFrameCount: 7,
    scenePosition: const Offset(0.88, 0.75),
    displayWidth: 120,
    displayHeight: 116,
    minStage: 3,
    awakeFps: 1,
    sleepingFps: 1,
  ),
};
