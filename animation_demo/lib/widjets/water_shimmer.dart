// lib/widgets/water_shimmer.dart
//
// ─── THE BUG: LEFT-TO-RIGHT HORIZONTAL SLIDING ───────────────────────────────
//
// The original code moved shimmer strips purely horizontally:
//   offset = Offset((value * screenWidth * 2) - screenWidth, 0)
//
// This looked wrong because the lake in the scene is NOT a horizontal body
// of water. Looking at the background image, the lake is a vertical/diagonal
// river that flows roughly top-right → bottom-centre → bottom-left.
//
// ─── THE FIX: DIAGONAL MOVEMENT ──────────────────────────────────────────────
//
// The shimmer should move along the water's flow direction.
// From the pixel analysis of the background:
//   Upper water (y≈38%):  centred at screen_x ≈ 61%
//   Mid water   (y≈52%):  centred at screen_x ≈ 44%
//   Lower water (y≈64%):  centred at screen_x ≈ 47-61%
//
// The water flows roughly top-right → bottom-left, so shimmer strips should
// move in that direction: negative X (leftward) and positive Y (downward).
//
// ─── IMPLEMENTATION ───────────────────────────────────────────────────────────
//
// We place multiple shimmer instances across the water body and animate
// them sliding diagonally (leftward + downward) in a loop.
// Each shimmer starts at a different phase offset so they don't all
// move together (staggered start positions).
//
// The shimmer strips are small light-reflection highlights (~183×97px).
// We scale them up slightly and place them at 3-4 positions across the
// water surface, each with a different phase and speed.

import 'package:flutter/material.dart' hide TimeOfDay;
import '../models/ecosystem_state.dart' show TimeOfDay;

class WaterShimmer extends StatefulWidget {
  final TimeOfDay timeOfDay;

  const WaterShimmer({required this.timeOfDay, super.key});

  @override
  State<WaterShimmer> createState() => _WaterShimmerState();
}

class _WaterShimmerState extends State<WaterShimmer>
    with TickerProviderStateMixin {
  // Four controllers — one per shimmer instance — at different speeds
  late List<AnimationController> _controllers;

  // Configuration for each shimmer instance:
  // (startX_frac, startY_frac, width, speed_seconds, phase_offset)
  static const List<_ShimmerInstance> _instances = [
    // Upper water area — smaller, faster
    // _ShimmerInstance(
    //     startX: 0.60, startY: 0.38, width: 55, speedSec: 4.0, phase: 0.0),
    // // Mid water left area — medium
    // _ShimmerInstance(
    //     startX: 0.45, startY: 0.48, width: 70, speedSec: 5.5, phase: 0.4),
    // // Mid water right area
    // _ShimmerInstance(
    //     startX: 0.55, startY: 0.52, width: 60, speedSec: 4.8, phase: 0.7),
    // // Lower water area — larger, slower
    // _ShimmerInstance(
    //     startX: 0.50, startY: 0.60, width: 75, speedSec: 6.5, phase: 0.2),
  ];

  @override
  void initState() {
    super.initState();
    _controllers = _instances
        .map((inst) => AnimationController(
      duration: Duration(milliseconds: (inst.speedSec * 1000).round()),
      vsync: this,
    )
      ..forward(from: inst.phase)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          // Restart the loop
        }
      }))
        .toList();

    // Start all controllers looping with their phase offset
    for (int i = 0; i < _controllers.length; i++) {
      _controllers[i].repeat();
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    super.dispose();
  }

  String _shimmerPath(int index) {
    final tod = widget.timeOfDay.name;
    final stripNum = (index % 2) + 1; // alternates strip 1 and 2
    final suffix = (tod == 'day') ? '' : '_$tod';
    return 'assets/shimmer/$tod/water_shimmer_strip_$stripNum$suffix.png';
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final screenH = MediaQuery.of(context).size.height;

    return Stack(
      fit: StackFit.expand,
      children: List.generate(_instances.length, (i) {
        final inst = _instances[i];
        return AnimatedBuilder(
          animation: _controllers[i],
          builder: (context, _) {
            final t = _controllers[i].value.clamp(0.0, 1.0);

            // Movement direction: the lake flows from top-right to bottom-left.
            // So shimmer moves: leftward (negative dx) and downward (positive dy).
            // Travel distance over one full cycle:
            //   dx = -0.25 of screen width (moves left)
            //   dy = +0.18 of screen height (moves down)
            final dx = t * (-screenW * 0.25);
            final dy = t * (screenH * 0.18);

            // Starting position (where shimmer begins each cycle)
            final baseX = screenW * inst.startX;
            final baseY = screenH * inst.startY;

            // Fade: fade in during first 10% of travel, fade out during last 20%
            double opacity;
            if (t < 0.10) {
              opacity = t / 0.10; // fade in
            } else if (t > 0.80) {
              opacity = (1.0 - t) / 0.20; // fade out
            } else {
              opacity = 1.0;
            }
            opacity = (opacity * 0.55).clamp(0.0, 0.55);

            return Positioned(
              left: baseX + dx,
              top: baseY + dy,
              width: inst.width,
              height: inst.width *
                  0.53, // shimmer strip aspect ratio ~183:97 ≈ 0.53
              child: Opacity(
                opacity: opacity,
                child: Image.asset(
                  _shimmerPath(i),
                  fit: BoxFit.fill,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}

// ─── Data class for shimmer instance configuration ────────────────────────────
class _ShimmerInstance {
  final double startX; // starting screen_x as fraction of screen width
  final double startY; // starting screen_y as fraction of screen height
  final double width; // display width in logical pixels
  final double speedSec; // seconds for one full travel cycle
  final double phase; // starting phase (0.0–1.0) — stagger the instances

  const _ShimmerInstance({
    required this.startX,
    required this.startY,
    required this.width,
    required this.speedSec,
    required this.phase,
  });
}
