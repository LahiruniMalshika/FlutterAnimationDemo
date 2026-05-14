//
// Shows a floating "+5" or "-3" badge that animates upward and fades out.
//
// Three animations play simultaneously:
//   1. ScaleAnimation  — pops from 50% to 120% size (elastic feel)
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

  // Scale: 0.5 → 1.2 (pops up)
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

    // // Add listener to clamp controller values to prevent precision errors
    // _controller.addListener(() {
    //   if (_controller.value < 0.0) _controller.value = 0.0;
    //   if (_controller.value > 1.0) _controller.value = 1.0;
    // });

    // Scale animation: plays in first 40% of total duration
    // Interval(0.0, 0.4) means it runs from 0ms to 800ms
    final clamped = ClampedAnimation(_controller);

    _scaleAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: clamped,
        curve: const Interval(0.0, 0.35, curve: Curves.elasticOut),
      ),
    );

    _fadeAnim = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: clamped,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
      ),
    );

    _slideAnim = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -1.8),
    ).animate(
      CurvedAnimation(
        parent: clamped,
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
