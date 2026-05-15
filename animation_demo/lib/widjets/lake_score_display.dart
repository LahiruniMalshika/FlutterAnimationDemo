// lib/widgets/lake_score_display.dart
//
// Displays the current lake score as a number that smoothly counts
// up or down when the score changes.
//
// HOW IT WORKS:
// IntTween counts from one integer to another over a set duration.
// AnimationController drives the tween from 0.0 to 1.0.
// The AnimatedBuilder rebuilds the Text on every tick, showing
// the current integer value from the tween.
//
// Example: score changes from 31 to 46.
// The number on screen counts: 31, 32, 33, 34 ... 45, 46
// over 600 milliseconds.

import 'package:flutter/material.dart';

class LakeScoreDisplay extends StatefulWidget {
  final int score;
  final int stage;
  final String waterLevel;
  final int totalScore; // always 100, for the progress bar

  const LakeScoreDisplay({
    required this.score,
    required this.stage,
    required this.waterLevel,
    this.totalScore = 100,
    super.key,
  });

  @override
  State<LakeScoreDisplay> createState() => _LakeScoreDisplayState();
}

class _LakeScoreDisplayState extends State<LakeScoreDisplay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _scoreAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scoreAnimation =
        IntTween(begin: widget.score, end: widget.score).animate(_controller);
  }

  @override
  void didUpdateWidget(LakeScoreDisplay old) {
    super.didUpdateWidget(old);

    if (old.score != widget.score) {
      // Count from old score to new score
      _scoreAnimation = IntTween(begin: old.score, end: widget.score).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOut),
      );
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scoreAnimation,
      builder: (context, _) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.35),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Score number
              Text(
                '${_scoreAnimation.value}',
                style: const TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 2),
              // Progress bar
              SizedBox(
                width: 120,
                height: 4,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: _scoreAnimation.value / 100.0,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _stageColor(widget.stage),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              // Stage and water level label
              Text(
                'Stage ${widget.stage} · ${widget.waterLevel}',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withOpacity(0.8),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _stageColor(int stage) {
    switch (stage) {
      case 1:
        return const Color(0xFF80CBC4);
      case 2:
        return const Color(0xFF4CAF50);
      case 3:
        return const Color(0xFF8BC34A);
      default:
        return Colors.white;
    }
  }
}
