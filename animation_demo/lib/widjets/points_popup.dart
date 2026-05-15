// lib/widgets/points_popup.dart
//
// Shows a floating "+5" or "-3" badge that animates upward and fades out.
//
// Three animations play simultaneously:
//   1. ScaleAnimation  — pops from 50% to 100% size (elastic feel)
//   2. SlideAnimation  — floats upward
//   3. FadeAnimation   — fades out towards the end
//
// Total duration: 2 seconds.
//
// HOW IT IS TRIGGERED:
// The pendingPointsProvider holds an int? value.
// When it becomes non-null, this widget shows and starts animating.
// When the animation completes, it calls onComplete() which clears
// the pendingPointsProvider back to null.
//
// ─── DEFENSIVE HARDENING ─────────────────────────────────────────────────────
// `CurvedAnimation` asserts its parent's value is in [0, 1]. Most of the time
// `AnimationController` honours that, but on some platforms (and during the
// brief moment AnimationController.forward() is settling at the end), the
// value can be reported as 1.0000003-ish — enough to trip the assertion in
// debug mode.
//
// We feed every CurvedAnimation here through `ClampedAnimation` so the
// parent value is always in [0, 1]. This costs effectively nothing and
// guarantees the popup never causes the "parametric value … outside of
// [0, 1] range" assertion, regardless of curve choice (including
// `Interval(..., elasticOut)`).

import 'package:flutter/material.dart';
import '../utils/safe_curve.dart';

class PointsPopup extends StatefulWidget {
  final int points;
  final VoidCallback onComplete;

  const PointsPopup({
    required this.points,
    required this.onComplete,
    super.key,
  });

  @override
  State<PointsPopup> createState() => _PointsPopupState();
}

class _PointsPopupState extends State<PointsPopup>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // ClampedAnimation guarantees the parent value handed to every
  // CurvedAnimation below is strictly within [0, 1].
  late Animation<double> _safeController;

  // Scale: 0.5 → 1.0 (pops up)
  late Animation<double> _scaleAnim;

  // Fade: 1.0 → 0.0 (fades out near the end)
  late Animation<double> _fadeAnim;

  // Slide: moves upward as it fades
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _safeController = ClampedAnimation(_controller);

    // Scale animation: plays in first 35% of total duration.
    // Interval(0.0, 0.35) means it runs from 0ms to 700ms.
    // elasticOut intentionally overshoots above 1.0 — that overshoot
    // is OK as a Tween OUTPUT (a scale of 1.08 just looks bouncy);
    // what we must NOT do is feed an >1.0 value back into another curve.
    _scaleAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _safeController,
        curve: const Interval(0.0, 0.35, curve: Curves.elasticOut),
      ),
    );

    // Fade out: plays in last 40% of total duration
    _fadeAnim = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _safeController,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
      ),
    );

    // Slide upward: plays from 30% to end
    _slideAnim = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -1.8),
    ).animate(
      CurvedAnimation(
        parent: _safeController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
      ),
    );

    // Start the animation and notify when done
    _controller.forward().then((_) {
      if (mounted) widget.onComplete();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPositive = widget.points >= 0;
    final sign = isPositive ? '+' : '';
    final bgColor = isPositive
        ? const Color(0xFF2E7D32) // dark green
        : const Color(0xFFC62828); // dark red

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return SlideTransition(
          position: _slideAnim,
          child: FadeTransition(
            opacity: _fadeAnim,
            child: ScaleTransition(
              scale: _scaleAnim,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: bgColor.withOpacity(0.4),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Text(
                  '$sign${widget.points}',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
