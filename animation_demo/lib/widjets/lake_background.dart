// lib/widgets/lake_background.dart
//
// Renders the correct background image and crossfades to the new
// one whenever the stage or water level changes.
//
// HOW THE CROSSFADE WORKS:
// Two Image widgets are stacked on top of each other.
// When the required image path changes:
//   1. We preload the new image into memory (precacheImage)
//   2. We run an AnimationController from 0.0 → 1.0 over 800ms
//   3. The old image fades out (opacity = 1 - animValue)
//   4. The new image fades in  (opacity = animValue)
//   5. Once complete, the old path is replaced by the new path

import 'package:flutter/material.dart';

class LakeBackground extends StatefulWidget {
  final String assetPath;

  const LakeBackground({required this.assetPath, super.key});

  @override
  State<LakeBackground> createState() => _LakeBackgroundState();
}

class _LakeBackgroundState extends State<LakeBackground>
    with SingleTickerProviderStateMixin {
  // The image currently displayed
  late String _currentPath;

  // The image we are crossfading TO
  String? _nextPath;

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _currentPath = widget.assetPath;

    // AnimationController drives the crossfade timing
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // CurvedAnimation makes the fade ease in and out (not linear)
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void didUpdateWidget(LakeBackground old) {
    super.didUpdateWidget(old);

    // Only trigger crossfade if the path actually changed
    if (widget.assetPath != _currentPath && widget.assetPath != _nextPath) {
      _startCrossfade(widget.assetPath);
    }
  }

  void _startCrossfade(String newPath) async {
    // Preload the new image into memory before crossfading.
    // This prevents a white flash during the transition.
    if (mounted) {
      await precacheImage(AssetImage(newPath), context);
    }
    if (!mounted) return;

    setState(() {
      _nextPath = newPath;
    });

    // Reset and run the fade animation
    _controller.forward(from: 0.0).then((_) {
      // Crossfade complete — the next image is now fully visible.
      // Promote it to "current" so we don't keep stacking images.
      if (mounted) {
        setState(() {
          _currentPath = newPath;
          _nextPath = null;
        });
        _controller.reset();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, _) {
        return Stack(
          fit: StackFit.expand,
          children: [
            // ── Layer 1: Current image (fades OUT) ───────────────
            Opacity(
              opacity: _nextPath != null
                  ? (1.0 - _fadeAnimation.value).clamp(0.0, 1.0)
                  : 1.0,
              child: Image.asset(
                _currentPath,
                fit: BoxFit.cover,
                // Error widget so the app doesn't crash if an asset is missing
                errorBuilder: (_, error, __) => Container(
                  color: const Color(0xFF1a3a4a),
                  child: Center(
                    child: Text(
                      'Missing asset:\n$_currentPath',
                      style:
                      const TextStyle(color: Colors.white70, fontSize: 11),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),

            // ── Layer 2: Next image (fades IN) ───────────────────
            if (_nextPath != null)
              Opacity(
                opacity: _fadeAnimation.value.clamp(0.0, 1.0),
                child: Image.asset(
                  _nextPath!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, error, __) => Container(
                    color: const Color(0xFF1a3a4a),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
