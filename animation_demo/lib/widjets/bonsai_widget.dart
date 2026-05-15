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
//   1. FadeTransition  — old fades out, new fades in (LINEAR — fades read better linear)
//   2. ScaleTransition — old shrinks, new grows (elasticOut curve gives the "pop")
//
// ─── IMPORTANT FIX (do not regress) ──────────────────────────────────────────
// Earlier this widget set:
//   switchInCurve: Curves.elasticOut
//   + ScaleTransition with CurvedAnimation(curve: Curves.elasticOut)
//
// AnimatedSwitcher already wraps its raw 0→1 animation in
// CurvedAnimation(curve: switchInCurve). So the `animation` passed to
// transitionBuilder was ALREADY producing elastic-overshoot values
// (e.g. 1.08, 1.26). Wrapping it AGAIN in CurvedAnimation(elasticOut)
// fed 1.08 into `elasticOut.transform(t)`, which asserts t ∈ [0, 1] and
// crashed with:
//   "parametric value 1.08... is outside of [0, 1] range"
//
// The fix: set switchInCurve to Curves.linear so the animation handed to
// transitionBuilder is a clean 0→1 ramp. Apply elasticOut ONCE, inside the
// ScaleTransition's CurvedAnimation, where its overshoot is the desired
// visual effect.
//
// ASSET FILES:
//   Day:  assets/bonsai/day/bonsai_small.png   (653x687px)
//         assets/bonsai/day/bonsai_large.png   (928x977px)
//   Dusk: assets/bonsai/dusk/bonsai_small_dusk.png
//         assets/bonsai/dusk/bonsai_large_dusk.png
//   Night:assets/bonsai/night/bonsai_small_night.png
//         assets/bonsai/night/bonsai_large_night.png

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
      // ⚠️ Keep these LINEAR. The animation handed to transitionBuilder
      // must stay in [0, 1] because we apply our own curves inside.
      switchInCurve: Curves.linear,
      switchOutCurve: Curves.linear,
      // Custom transition: fade (linear) + scale (elastic pop) simultaneously.
      transitionBuilder: (Widget child, Animation<double> animation) {
        // Scale animation — elasticOut applied here, ONCE, with a clean
        // [0, 1] parent. The overshoot above 1.0 is the desired visual.
        final scaleAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: Curves.elasticOut),
        );

        return FadeTransition(
          // Fade uses the raw linear animation — no curve stacking.
          opacity: animation,
          child: ScaleTransition(
            scale: scaleAnim,
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
