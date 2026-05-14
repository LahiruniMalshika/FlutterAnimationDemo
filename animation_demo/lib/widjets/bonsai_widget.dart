// lib/widgets/bonsai_widget.dart
//
// Renders the bonsai tree in the Serenity Spring zone.
//
// The bonsai has 3 states driven ONLY by meditation points (NOT lake score):
//   BonsaiState.none  → invisible (no meditation in last 7 days)
//   BonsaiState.small → small bonsai image
//   BonsaiState.large → large bonsai image
//
// TRANSITION ANIMATION (AnimatedSwitcher):
// AnimatedSwitcher is a Flutter widget that automatically animates
// between two different child widgets. When you give it a new child,
// it plays a transition from the old child to the new one.
//
// We combine two effects:
//   1. FadeTransition — old fades out, new fades in
//   2. ScaleTransition — old shrinks, new grows (elasticOut curve)
//
// The elasticOut curve gives a satisfying "pop" effect when the
// bonsai grows from small to large.
//
// ASSET FILES:
//   Day:  assets/bonsai/day/bonsai_small.png   (653x687px)
//         assets/bonsai/day/bonsai_large.png   (928x977px)
//   Dusk: assets/bonsai/dusk/bonsai_small_dusk.png
//         assets/bonsai/dusk/bonsai_large_dusk.png
//   Night:assets/bonsai/night/bonsai_small_night.png
//         assets/bonsai/night/bonsai_large_night.png

import 'package:animation_demo/utils/safe_curve.dart';
import 'package:flutter/material.dart' hide TimeOfDay;
import '../models/ecosystem_state.dart';

class BonsaiWidget extends StatelessWidget {
  final BonsaiState bonsaiState;
  final TimeOfDay timeOfDay;

  const BonsaiWidget({
    required this.bonsaiState,
    required this.timeOfDay,
    super.key,
  });

  // ── Derive the correct asset path ─────────────────────────────
  String? get _assetPath {
    if (bonsaiState == BonsaiState.none) return null;

    final tod = timeOfDay.name; // "day" | "dusk" | "night"
    final size = bonsaiState == BonsaiState.large ? 'large' : 'small';
    final suffix = (tod == 'day') ? '' : '_$tod'; // "" | "_dusk" | "_night"
    return 'assets/bonsai/$tod/bonsai_$size$suffix.png';
  }

  @override
  Widget build(BuildContext context) {
    final path = _assetPath;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 1500),
      switchInCurve: Curves.elasticOut,
      switchOutCurve: Curves.easeIn,
      // Custom transition: fade + scale simultaneously
      transitionBuilder: (Widget child, Animation<double> animation) {
        final clamped = ClampedAnimation(animation); // add this
        return FadeTransition(
          opacity: clamped,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.6, end: 1.0).animate(
              CurvedAnimation(parent: clamped, curve: Curves.elasticOut),
            ),
            child: child,
          ),
        );
      },
      child: path != null
          ? Image.asset(
              path,
              // ValueKey is critical — AnimatedSwitcher uses it to detect
              // when the child actually changed (needs to run the animation).
              // Without ValueKey, it won't animate between small and large.
              key: ValueKey<String>(path),
              width: 100,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            )
          : const SizedBox.shrink(key: ValueKey<String>('none')),
    );
  }
}
