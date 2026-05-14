//
// Renders two semi-transparent shimmer strips that slide across
// the water surface in a continuous loop, making the lake look alive.
//
// HOW IT WORKS:
// Each shimmer strip is a small image (~183x97px).
// We place it over the water area and use Transform.translate to
// move it horizontally. The AnimationController loops forever,
// so the strip slides right continuously. Two strips at different
// speeds (6s and 9s) create an organic, natural-looking water effect.
//
// ASSET FILES USED:
//   Day:  assets/shimmer/day/water_shimmer_strip_1.png  (183x97)
//         assets/shimmer/day/water_shimmer_strip_2.png  (123x72)
//   Dusk: assets/shimmer/dusk/water_shimmer_strip_1_dusk.png
//         assets/shimmer/dusk/water_shimmer_strip_2_dusk.png
//   Night:assets/shimmer/night/water_shimmer_strip_1_night.png
//         assets/shimmer/night/water_shimmer_strip_2_night.png

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
  // Strip 1: slower (6 seconds per full loop)
  late AnimationController _strip1Controller;
  // Strip 2: faster (9 seconds — different speed = more natural)
  late AnimationController _strip2Controller;

  @override
  void initState() {
    super.initState();

    _strip1Controller = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    )..repeat(); // repeat = loops forever

    _strip2Controller = AnimationController(
      duration: const Duration(seconds: 9),
      vsync: this,
    )..repeat();

    // Add listeners to clamp values
    _strip1Controller.addListener(() {
      if (_strip1Controller.value < 0.0) _strip1Controller.value = 0.0;
      if (_strip1Controller.value > 1.0) _strip1Controller.value = 1.0;
    });

    _strip2Controller.addListener(() {
      if (_strip2Controller.value < 0.0) _strip2Controller.value = 0.0;
      if (_strip2Controller.value > 1.0) _strip2Controller.value = 1.0;
    });
  }

  @override
  void dispose() {
    _strip1Controller.dispose();
    _strip2Controller.dispose();
    super.dispose();
  }

  // ── Get the correct shimmer asset path ────────────────────────
  String _shimmerPath(int stripNumber) {
    final tod = widget.timeOfDay.name; // "day" | "dusk" | "night"
    final suffix = (tod == 'day') ? '' : '_$tod';
    return 'assets/shimmer/$tod/water_shimmer_strip_${stripNumber}$suffix.png';
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Strip 1 — positioned at approximately the water surface level
        _buildShimmerStrip(
          controller: _strip1Controller,
          stripNumber: 1,
          topFraction: 0.52, // 52% down the screen (adjust to match artwork)
          opacity: 0.45,
          heightFraction: 0.06, // strip height as fraction of screen height
        ),

        // Strip 2 — slightly lower on the water, different speed
        _buildShimmerStrip(
          controller: _strip2Controller,
          stripNumber: 2,
          topFraction: 0.58,
          opacity: 0.35,
          heightFraction: 0.04,
        ),
      ],
    );
  }

  Widget _buildShimmerStrip({
    required AnimationController controller,
    required int stripNumber,
    required double topFraction,
    required double opacity,
    required double heightFraction,
  }) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;
        final stripHeight = screenHeight * heightFraction;

        // Clamp controller value to [0,1] to prevent precision errors
        final safeValue = controller.value.clamp(0.0, 1.0);
        // The strip moves from -screenWidth to +screenWidth
        // safeValue goes 0.0 → 1.0
        // offset goes from -screenWidth to +screenWidth
        final offsetX = (safeValue * screenWidth * 2) - screenWidth;

        return Positioned(
          top: screenHeight * topFraction,
          left: 0,
          right: 0,
          height: stripHeight,
          child: Transform.translate(
            offset: Offset(offsetX, 0),
            child: Opacity(
              opacity: opacity,
              child: Image.asset(
                _shimmerPath(stripNumber),
                fit: BoxFit.fitHeight,
                // If asset missing, silently show nothing
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ),
        );
      },
    );
  }
}
