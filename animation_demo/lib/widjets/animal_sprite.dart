// lib/widgets/animal_sprite.dart
//
// Renders a single animal using sprite sheet animation.
//
// WHAT IS A SPRITE SHEET?
// A sprite sheet is one wide image that contains all animation frames
// placed side by side, like a film strip.
//
// Example — fish1_awake_sheet.png is 2253x251 pixels:
//   [frame0][frame1][frame2][frame3][frame4][frame5][frame6][frame7][frame8]
//   Each frame is 251x251 pixels. 9 frames total.
//
// HOW WE ANIMATE IT:
// We use ClipRect (a window/crop tool) to show only one frame at a time.
// By shifting the Align parameter, we move which frame appears in the window.
//
//   Align(-1.0) → shows frame 0 (leftmost)
//   Align(+1.0) → shows frame 8 (rightmost)
//   Align in between → shows the corresponding frame
//
// An AnimationController counts 0.0 → 1.0 repeatedly.
// We convert that into a frame index (0, 1, 2 ... N-1).
// Then we convert the frame index into an Align value.
//
// VISIBILITY:
// AnimatedOpacity fades the animal in/out over 1.2 seconds when
// its visibility state changes (true → false or false → true).
// This gives a gentle appearance/disappearance effect.

import 'package:flutter/material.dart' hide TimeOfDay;
import '../models/animal_config.dart';
import '../models/ecosystem_state.dart' show TimeOfDay;

class AnimalSprite extends StatefulWidget {
  final AnimalConfig config;
  final bool isVisible;
  final bool isSleeping; // true when timeOfDay == night
  final TimeOfDay timeOfDay;

  const AnimalSprite({
    required this.config,
    required this.isVisible,
    required this.isSleeping,
    required this.timeOfDay,
    super.key,
  });

  @override
  State<AnimalSprite> createState() => _AnimalSpriteState();
}

class _AnimalSpriteState extends State<AnimalSprite>
    with SingleTickerProviderStateMixin {
  late AnimationController _frameController;
  int _currentFrame = 0;

  @override
  void initState() {
    super.initState();
    _frameController = AnimationController(
      duration: _frameDuration,
      vsync: this,
    )
      ..addListener(_onFrameTick)
      ..repeat();
  }

  // ── How long one complete animation cycle takes ───────────────
  // frames / fps = total cycle seconds
  Duration get _frameDuration {
    final fps =
        widget.isSleeping ? widget.config.sleepingFps : widget.config.awakeFps;
    final frames = widget.isSleeping
        ? widget.config.sleepingFrameCount
        : widget.config.awakeFrameCount;
    final totalMs = (frames / fps * 1000).round();
    return Duration(milliseconds: totalMs);
  }

  int get _totalFrames => widget.isSleeping
      ? widget.config.sleepingFrameCount
      : widget.config.awakeFrameCount;

  // ── Called every frame by the AnimationController ─────────────
  void _onFrameTick() {
    // Clamp the controller value to [0, 1] before using it
    // This prevents floating-point precision errors (e.g., 1.0000005)
    final clampedValue = _frameController.value.clamp(0.0, 1.0);
    final newFrame =
        (clampedValue * _totalFrames).floor().clamp(0, _totalFrames - 1);

    if (newFrame != _currentFrame) {
      setState(() => _currentFrame = newFrame);
    }
  }

  @override
  void didUpdateWidget(AnimalSprite old) {
    super.didUpdateWidget(old);

    // When sleep state changes, restart animation with new duration
    if (old.isSleeping != widget.isSleeping) {
      _frameController.duration = _frameDuration;
      _currentFrame = 0;
      _frameController.forward(from: 0);
    }

    // When time of day changes (different asset), restart
    if (old.timeOfDay != widget.timeOfDay) {
      _currentFrame = 0;
      _frameController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _frameController.dispose();
    super.dispose();
  }

  // ── The correct sprite sheet asset path ───────────────────────
  String get _assetPath {
    final tod = widget.timeOfDay.name;
    return widget.isSleeping
        ? widget.config.sleepingAssetPath(tod)
        : widget.config.awakeAssetPath(tod);
  }

  // ── Convert frame index to Align value ────────────────────────
  // Frame 0 → -1.0 (leftmost), Frame N-1 → +1.0 (rightmost)
  double get _alignX {
    if (_totalFrames <= 1) return 0.0;
    return -1.0 + (2.0 * _currentFrame / (_totalFrames - 1));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      // Fade in/out over 1.2 seconds when visibility changes
      opacity: widget.isVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeInOut,
      child: widget.isVisible ? _buildSpriteFrame() : const SizedBox.shrink(),
    );
  }

  Widget _buildSpriteFrame() {
    final frameWidth = widget.config.displayWidth;
    final frameCount = _totalFrames;

    return SizedBox(
      width: frameWidth,
      height: frameWidth, // Sprites are approximately square
      child: ClipRect(
        // ClipRect acts as the window — it hides everything outside its bounds
        child: Align(
          // Align shifts the large sprite sheet image so the correct frame
          // appears inside the ClipRect window
          alignment: Alignment(_alignX, 0.0),
          widthFactor: 1.0 / frameCount,
          child: Image.asset(
            _assetPath,
            // The full image must be frameCount × frameWidth wide
            width: frameWidth * frameCount,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              // Show a placeholder emoji if the asset is missing
              return Container(
                width: frameWidth,
                height: frameWidth,
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    _animalEmoji(widget.config.name),
                    style: TextStyle(fontSize: frameWidth * 0.4),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  String _animalEmoji(String name) {
    const emojis = {
      'fish': '🐟',
      'bird': '🐦',
      'rabbit': '🐰',
      'duck': '🦆',
      'otter': '🦦',
      'deer': '🦌',
    };
    return emojis[name] ?? '🐾';
  }
}
