// lib/widgets/animal_sprite.dart
//
// ─── THE BUG THAT WAS CAUSING THE FULL SPRITE SHEET TO SHOW ──────────────────
//
// The original code used this inside ClipRect:
//
//   Align(
//     alignment: Alignment(_alignX, 0.0),
//     widthFactor: 1.0 / frameCount,        ← THIS was wrong
//     child: Image.asset(width: frameWidth * frameCount),
//   )
//
// The problem: widthFactor tells Align how wide to make the clipping window
// as a fraction of the CHILD width. So widthFactor: 1/9 should show 1/9th of
// the image. But the child Image.asset width was set to frameWidth * frameCount
// (the full strip), and the display size (frameWidth) was a rough estimate.
// The numbers didn't add up, so the Align wasn't cropping to exactly one frame.
//
// ─── THE FIX ─────────────────────────────────────────────────────────────────
//
// Use a completely different, more reliable approach: CustomPainter.
//
// CustomPainter draws exactly what you tell it. We load the sprite sheet as
// an ImageProvider, convert it to a dart:ui Image, then on each frame we use
// canvas.drawImageRect() to cut out EXACTLY one frame rectangle and draw it.
//
// drawImageRect(image, sourceRect, destRect, paint)
//   sourceRect = the rectangle inside the sprite sheet for frame N
//   destRect   = the rectangle on screen to draw it into
//
// This is pixel-perfect. No floating-point Align math. No widthFactor issues.
//
// ─── SPRITE SHEET FRAME SIZES (measured from actual files) ───────────────────
//
//   fish1_awake:     2253×251,  9 frames, each 250×251px
//   otter_awake:     5551×361, 15 frames, each 370×361px
//   bird_awake_dusk: 2781×432,  6 frames, each 463×432px
//   bird_sleeping:   1651×353,  5 frames, each 330×353px
//   deer_sleeping:   5173×835,  6 frames, each 862×835px
//   duck_sleeping:   3090×413,  7 frames, each 441×413px
//   fish2_sleeping:  2176×221, 10 frames, each 218×221px
//   otter_sleeping:  4445×361, 12 frames, each 370×361px
//   rabbit_sleeping: 2438×433,  6 frames, each 406×433px

import 'dart:ui' as ui;
import 'package:flutter/material.dart' hide TimeOfDay;
import 'package:flutter/services.dart';
import '../models/animal_config.dart';
import '../models/ecosystem_state.dart' show TimeOfDay;

// ─────────────────────────────────────────────────────────────
// Image cache — loads each sprite sheet image once and reuses it
// ─────────────────────────────────────────────────────────────
final Map<String, ui.Image> _imageCache = {};

Future<ui.Image?> _loadImage(String assetPath) async {
  if (_imageCache.containsKey(assetPath)) {
    return _imageCache[assetPath];
  }
  try {
    final data = await rootBundle.load(assetPath);
    final bytes = data.buffer.asUint8List();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;
    _imageCache[assetPath] = image;
    return image;
  } catch (e) {
    debugPrint('Failed to load sprite sheet: $assetPath — $e');
    return null;
  }
}

// ─────────────────────────────────────────────────────────────
// AnimalSprite — renders one animal with correct frame animation
// ─────────────────────────────────────────────────────────────

class AnimalSprite extends StatefulWidget {
  final AnimalConfig config;
  final bool isVisible;
  final bool isSleeping;
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
  ui.Image? _spriteImage;
  String _loadedPath = '';
  int _currentFrame = 0;

  @override
  void initState() {
    super.initState();
    _frameController = AnimationController(
      duration: _frameDuration,
      vsync: this,
    )
      ..addListener(_onTick)
      ..repeat();
    _loadSprite();
  }

  // ── Duration for one full animation cycle ─────────────────────
  Duration get _frameDuration {
    final fps =
    widget.isSleeping ? widget.config.sleepingFps : widget.config.awakeFps;
    final frames = widget.isSleeping
        ? widget.config.sleepingFrameCount
        : widget.config.awakeFrameCount;
    final ms = ((frames / fps) * 1000).round().clamp(100, 10000);
    return Duration(milliseconds: ms);
  }

  int get _totalFrames => widget.isSleeping
      ? widget.config.sleepingFrameCount
      : widget.config.awakeFrameCount;

  // ── Load sprite sheet image into memory ───────────────────────
  Future<void> _loadSprite() async {
    final tod = widget.timeOfDay.name;
    final path = widget.isSleeping
        ? widget.config.sleepingAssetPath(tod)
        : widget.config.awakeAssetPath(tod);

    if (path == _loadedPath) return; // already loaded

    final img = await _loadImage(path);
    if (mounted) {
      setState(() {
        _spriteImage = img;
        _loadedPath = path;
        _currentFrame = 0;
      });
    }
  }

  // ── Advance frame counter on each animation tick ──────────────
  void _onTick() {
    final val = _frameController.value.clamp(0.0, 1.0);
    final newFrame = (val * _totalFrames).floor().clamp(0, _totalFrames - 1);
    if (newFrame != _currentFrame) {
      setState(() => _currentFrame = newFrame);
    }
  }

  @override
  void didUpdateWidget(AnimalSprite old) {
    super.didUpdateWidget(old);

    final stateChanged = old.isSleeping != widget.isSleeping ||
        old.timeOfDay != widget.timeOfDay;

    if (stateChanged) {
      _frameController.duration = _frameDuration;
      _currentFrame = 0;
      _frameController.forward(from: 0);
      _loadSprite();
    }
  }

  @override
  void dispose() {
    _frameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: widget.isVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeInOut,
      // Always keep the widget in the tree so AnimatedOpacity can fade it.
      // When not visible it is transparent but still animating (low cost).
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_spriteImage == null) {
      // Show emoji placeholder while image loads
      return SizedBox(
        width: widget.config.displayWidth,
        height: widget.config.displayHeight,
        child: Center(
          child: Text(
            _animalEmoji(widget.config.name),
            style: TextStyle(
              fontSize: widget.config.displayWidth * 0.5,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: widget.config.displayWidth,
      height: widget.config.displayHeight,
      child: CustomPaint(
        painter: _SpritePainter(
          image: _spriteImage!,
          frameIndex: _currentFrame,
          totalFrames: _totalFrames,
        ),
      ),
    );
  }

  String _animalEmoji(String name) {
    const m = {
      'fish': '🐟',
      'bird': '🐦',
      'rabbit': '🐰',
      'duck': '🦆',
      'otter': '🦦',
      'deer': '🦌',
    };
    return m[name] ?? '🐾';
  }
}

// ─────────────────────────────────────────────────────────────
// SpritePainter — pixel-perfect frame extraction with drawImageRect
// ─────────────────────────────────────────────────────────────

class _SpritePainter extends CustomPainter {
  final ui.Image image;
  final int frameIndex;
  final int totalFrames;

  const _SpritePainter({
    required this.image,
    required this.frameIndex,
    required this.totalFrames,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (totalFrames <= 0) return;

    // Source rectangle: exactly one frame from the sprite sheet
    // Frame width = total image width / number of frames
    final frameWidth = image.width / totalFrames;
    final srcLeft = frameIndex * frameWidth;

    final srcRect = Rect.fromLTWH(
      srcLeft, // left edge of this frame
      0, // always top
      frameWidth, // width of exactly one frame
      image.height.toDouble(), // full height of the sheet
    );

    // Destination rectangle: fill the widget bounds
    final dstRect = Rect.fromLTWH(0, 0, size.width, size.height);

    final paint = Paint()
      ..filterQuality = FilterQuality.medium
      ..isAntiAlias = true;

    canvas.drawImageRect(image, srcRect, dstRect, paint);
  }

  @override
  bool shouldRepaint(_SpritePainter old) =>
      old.frameIndex != frameIndex ||
          old.image != image ||
          old.totalFrames != totalFrames;
}
