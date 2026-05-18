// lib/widjets/water_shimmer.dart
//
// Renders soft "shimmer" glints flowing along the lake surface.
//
// ─── PER-(STAGE, WATER LEVEL) CONFIG ────────────────────────────────────────
//
// Shimmer intensity is driven by two state values:
//   • stage      — 1, 2, 3 (ecosystem maturity)
//   • waterLevel — low, mid, high
//
// The rules:
//   stage 1 + low                  → NO shimmer at all (early-return)
//   stage 1 + mid/high             → shimmer present, slower speeds
//   stage 2 + low/mid/high         → all three levels shimmer
//   stage 3 + low/mid/high         → all three levels shimmer
//
// Both the NUMBER of streams (glint count) and the SPEED (cycleMs) vary
// per combo — see `_streamsFor(...)` below for the full 9-cell table.
//
// When `stage` or `waterLevel` changes, controllers are disposed and
// rebuilt in `didUpdateWidget`. The stream list itself moves OUT of a
// top-level const and INTO instance state so each rebuild can use a
// different config.
//
// ─── DESIGN: STREAMS, NOT INDEPENDENT GLINTS ────────────────────────────────
//
// A stream defines ONE flow line (start → end). It produces N glints
// traveling that line, evenly spaced in time, sharing one
// AnimationController.
//
//   personalT = (controllerT + glintIndex / glintCount) % 1.0
//
// Each glint runs through: fade IN (0.00–0.18), full (0.18–0.82),
// fade OUT (0.82–1.00). Position interpolates linearly across the
// whole cycle (no hold).

import 'dart:math' show pi;
import 'package:flutter/material.dart' hide TimeOfDay;
import '../models/ecosystem_state.dart' show TimeOfDay, WaterLevel;

class WaterShimmer extends StatefulWidget {
  final TimeOfDay timeOfDay;
  final int stage; // 1, 2, or 3
  final WaterLevel waterLevel; // low, mid, high

  const WaterShimmer({
    required this.timeOfDay,
    required this.stage,
    required this.waterLevel,
    super.key,
  });

  @override
  State<WaterShimmer> createState() => _WaterShimmerState();
}

// ─────────────────────────────────────────────────────────────────────────
// Stream configuration
// ─────────────────────────────────────────────────────────────────────────

class _ShimmerStream {
  final double startX; // entry point (fraction of screen width)
  final double startY; // entry point (fraction of screen height)
  final double endX; // exit point
  final double endY;
  final int glintCount; // glints flowing along this stream at once
  final int cycleMs; // ms for one glint to travel start → end (lower = faster)
  final double rotationDeg;
  final double widthPx;
  final int stripNumber; // 1 or 2
  final double peakOpacity;

  const _ShimmerStream({
    required this.startX,
    required this.startY,
    required this.endX,
    required this.endY,
    required this.glintCount,
    required this.cycleMs,
    required this.rotationDeg,
    required this.widthPx,
    required this.stripNumber,
    required this.peakOpacity,
  });
}

// ─────────────────────────────────────────────────────────────────────────
// Per-(stage, waterLevel) stream table
//
// Tune these freely — each combo is independent. The general progression:
//   • stage 1 low   → none
//   • stage 1 mid   → 2 streams, slow
//   • stage 1 high  → 3 streams, slow-medium
//   • stage 2 low   → 3 streams, medium
//   • stage 2 mid   → 3 streams, medium-fast, more glints
//   • stage 2 high  → 4 streams, fast
//   • stage 3 low   → 4 streams, fast
//   • stage 3 mid   → 4 streams, faster, more glints
//   • stage 3 high  → 4 streams, fastest, most glints
// ─────────────────────────────────────────────────────────────────────────

List<_ShimmerStream> _streamsFor(int stage, WaterLevel level) {
  // ── STAGE 1 ────────────────────────────────────────────────────────────
  if (stage == 1 && level == WaterLevel.low) {
    return const []; // NO shimmer
  }
  if (stage == 1 && level == WaterLevel.mid) {
    return const [
      _ShimmerStream(
        startX: 0.65,
        startY: 0.30,
        endX: 0.65,
        endY: 0.40,
        glintCount: 2,
        cycleMs: 10000,
        rotationDeg: 25,
        widthPx: 30,
        stripNumber: 1,
        peakOpacity: 0.65,
      ),
      _ShimmerStream(
        startX: 0.70,
        startY: 0.55,
        endX: 0.78,
        endY: 0.65,
        glintCount: 1,
        cycleMs: 6500,
        rotationDeg: -5,
        widthPx: 50,
        stripNumber: 1,
        peakOpacity: 0.65,
      ),
      _ShimmerStream(
        startX: 0.58,
        startY: 0.50,
        endX: 0.25,
        endY: 0.55,
        glintCount: 1,
        cycleMs: 8000,
        rotationDeg: 70,
        widthPx: 50,
        stripNumber: 1,
        peakOpacity: 0.65,
      ),
    ];
  }
  if (stage == 1 && level == WaterLevel.high) {
    return const [
      _ShimmerStream(
        // Upper lake flow
        startX: 0.65,
        startY: 0.24,
        endX: 0.65,
        endY: 0.40,
        glintCount: 3,
        cycleMs: 10000,
        rotationDeg: 25,
        widthPx: 30,
        stripNumber: 1,
        peakOpacity: 0.80,
      ),
      _ShimmerStream(
        // mid lake - right to left flow
        startX: 0.70,
        startY: 0.55,
        endX: 0.78,
        endY: 0.65,
        glintCount: 1,
        cycleMs: 8000,
        rotationDeg: -5,
        widthPx: 50,
        stripNumber: 1,
        peakOpacity: 0.80,
      ),
      _ShimmerStream(
        // left end flow
        startX: 0.58,
        startY: 0.50,
        endX: 0.25,
        endY: 0.55,
        glintCount: 2,
        cycleMs: 8000,
        rotationDeg: 70,
        widthPx: 50,
        stripNumber: 1,
        peakOpacity: 0.65,
      ),
      _ShimmerStream(
        // bottom right flow
        startX: 0.05,
        startY: 0.55,
        endX: 0.00,
        endY: 0.60,
        glintCount: 2,
        cycleMs: 8000,
        rotationDeg: 80,
        widthPx: 38,
        stripNumber: 1,
        peakOpacity: 0.85,
      ),
    ];
  }

  // ── STAGE 2 ────────────────────────────────────────────────────────────
  if (stage == 2 && level == WaterLevel.low) {
    return const [
      _ShimmerStream(
        startX: 0.65,
        startY: 0.24,
        endX: 0.65,
        endY: 0.40,
        glintCount: 2,
        cycleMs: 4500,
        rotationDeg: 25,
        widthPx: 30,
        stripNumber: 1,
        peakOpacity: 0.75,
      ),
      _ShimmerStream(
        startX: 0.70,
        startY: 0.55,
        endX: 0.78,
        endY: 0.65,
        glintCount: 2,
        cycleMs: 4800,
        rotationDeg: -5,
        widthPx: 50,
        stripNumber: 1,
        peakOpacity: 0.75,
      ),
      _ShimmerStream(
        startX: 0.58,
        startY: 0.50,
        endX: 0.25,
        endY: 0.55,
        glintCount: 2,
        cycleMs: 5000,
        rotationDeg: 70,
        widthPx: 50,
        stripNumber: 1,
        peakOpacity: 0.65,
      ),
    ];
  }
  if (stage == 2 && level == WaterLevel.mid) {
    return const [
      _ShimmerStream(
        startX: 0.65,
        startY: 0.24,
        endX: 0.65,
        endY: 0.40,
        glintCount: 3,
        cycleMs: 3800,
        rotationDeg: 25,
        widthPx: 30,
        stripNumber: 1,
        peakOpacity: 0.80,
      ),
      _ShimmerStream(
        startX: 0.70,
        startY: 0.55,
        endX: 0.78,
        endY: 0.65,
        glintCount: 2,
        cycleMs: 4000,
        rotationDeg: -5,
        widthPx: 50,
        stripNumber: 1,
        peakOpacity: 0.80,
      ),
      _ShimmerStream(
        startX: 0.58,
        startY: 0.50,
        endX: 0.25,
        endY: 0.55,
        glintCount: 3,
        cycleMs: 4200,
        rotationDeg: 70,
        widthPx: 50,
        stripNumber: 1,
        peakOpacity: 0.70,
      ),
    ];
  }
  if (stage == 2 && level == WaterLevel.high) {
    return const [
      _ShimmerStream(
        // Upper lake flow
        startX: 0.65,
        startY: 0.24,
        endX: 0.65,
        endY: 0.40,
        glintCount: 3,
        cycleMs: 10000,
        rotationDeg: 25,
        widthPx: 30,
        stripNumber: 1,
        peakOpacity: 0.80,
      ),
      _ShimmerStream(
        // mid lake - right to left flow
        startX: 0.70,
        startY: 0.55,
        endX: 0.78,
        endY: 0.65,
        glintCount: 1,
        cycleMs: 8000,
        rotationDeg: -5,
        widthPx: 50,
        stripNumber: 1,
        peakOpacity: 0.80,
      ),
      _ShimmerStream(
        // left end flow
        startX: 0.58,
        startY: 0.50,
        endX: 0.25,
        endY: 0.55,
        glintCount: 2,
        cycleMs: 8000,
        rotationDeg: 70,
        widthPx: 50,
        stripNumber: 1,
        peakOpacity: 0.65,
      ),
      _ShimmerStream(
        // bottom right flow
        startX: 0.05,
        startY: 0.55,
        endX: 0.00,
        endY: 0.60,
        glintCount: 2,
        cycleMs: 8000,
        rotationDeg: 80,
        widthPx: 38,
        stripNumber: 1,
        peakOpacity: 0.85,
      ),
    ];
  }

  // ── STAGE 3 ────────────────────────────────────────────────────────────
  if (stage == 3 && level == WaterLevel.low) {
    return const [
      _ShimmerStream(
        startX: 0.65,
        startY: 0.24,
        endX: 0.65,
        endY: 0.40,
        glintCount: 3,
        cycleMs: 8000,
        rotationDeg: 25,
        widthPx: 30,
        stripNumber: 1,
        peakOpacity: 0.80,
      ),
      _ShimmerStream(
        startX: 0.70,
        startY: 0.55,
        endX: 0.78,
        endY: 0.65,
        glintCount: 2,
        cycleMs: 5200,
        rotationDeg: -5,
        widthPx: 50,
        stripNumber: 1,
        peakOpacity: 0.80,
      ),
      _ShimmerStream(
        startX: 0.58,
        startY: 0.50,
        endX: 0.25,
        endY: 0.55,
        glintCount: 3,
        cycleMs: 5500,
        rotationDeg: 70,
        widthPx: 50,
        stripNumber: 1,
        peakOpacity: 0.75,
      ),
      _ShimmerStream(
        startX: 0.05,
        startY: 0.55,
        endX: 0.00,
        endY: 0.60,
        glintCount: 2,
        cycleMs: 5800,
        rotationDeg: 80,
        widthPx: 38,
        stripNumber: 1,
        peakOpacity: 0.80,
      ),
    ];
  }
  if (stage == 3 && level == WaterLevel.mid) {
    return const [
      _ShimmerStream(
        startX: 0.65,
        startY: 0.24,
        endX: 0.65,
        endY: 0.40,
        glintCount: 4,
        cycleMs: 7500,
        rotationDeg: 25,
        widthPx: 30,
        stripNumber: 1,
        peakOpacity: 0.85,
      ),
      _ShimmerStream(
        startX: 0.70,
        startY: 0.55,
        endX: 0.78,
        endY: 0.65,
        glintCount: 3,
        cycleMs: 5700,
        rotationDeg: -5,
        widthPx: 50,
        stripNumber: 2,
        peakOpacity: 0.85,
      ),
      _ShimmerStream(
        startX: 0.58,
        startY: 0.50,
        endX: 0.25,
        endY: 0.55,
        glintCount: 3,
        cycleMs: 5900,
        rotationDeg: 70,
        widthPx: 50,
        stripNumber: 1,
        peakOpacity: 0.80,
      ),
      _ShimmerStream(
        startX: 0.05,
        startY: 0.55,
        endX: 0.00,
        endY: 0.60,
        glintCount: 3,
        cycleMs: 5000,
        rotationDeg: 80,
        widthPx: 38,
        stripNumber: 2,
        peakOpacity: 0.85,
      ),
    ];
  }
  if (stage == 3 && level == WaterLevel.high) {
    return const [
      _ShimmerStream(
        // Upper lake flow
        startX: 0.65,
        startY: 0.24,
        endX: 0.65,
        endY: 0.40,
        glintCount: 3,
        cycleMs: 10000,
        rotationDeg: 25,
        widthPx: 30,
        stripNumber: 1,
        peakOpacity: 0.80,
      ),
      _ShimmerStream(
        // mid lake - right to left flow
        startX: 0.70,
        startY: 0.55,
        endX: 0.78,
        endY: 0.65,
        glintCount: 1,
        cycleMs: 8000,
        rotationDeg: -5,
        widthPx: 50,
        stripNumber: 1,
        peakOpacity: 0.80,
      ),
      _ShimmerStream(
        // left end flow
        startX: 0.58,
        startY: 0.50,
        endX: 0.25,
        endY: 0.55,
        glintCount: 2,
        cycleMs: 8000,
        rotationDeg: 70,
        widthPx: 50,
        stripNumber: 1,
        peakOpacity: 0.65,
      ),
      _ShimmerStream(
        // bottom right flow
        startX: 0.05,
        startY: 0.55,
        endX: 0.00,
        endY: 0.60,
        glintCount: 2,
        cycleMs: 8000,
        rotationDeg: 80,
        widthPx: 38,
        stripNumber: 1,
        peakOpacity: 0.85,
      ),
    ];
  }

  // Fallback (shouldn't be reached if stages/levels stay in their enums).
  return const [];
}

// ─────────────────────────────────────────────────────────────────────────
// State
// ─────────────────────────────────────────────────────────────────────────

class _WaterShimmerState extends State<WaterShimmer>
    with TickerProviderStateMixin {
  late List<_ShimmerStream> _streams;
  late List<AnimationController> _controllers;

  @override
  void initState() {
    super.initState();
    _buildStreamsAndControllers();
  }

  @override
  void didUpdateWidget(covariant WaterShimmer oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Rebuild only when the config changes — timeOfDay alone just swaps assets
    // and does NOT require new controllers.
    if (oldWidget.stage != widget.stage ||
        oldWidget.waterLevel != widget.waterLevel) {
      _disposeControllers();
      _buildStreamsAndControllers();
    }
  }

  void _buildStreamsAndControllers() {
    _streams = _streamsFor(widget.stage, widget.waterLevel);
    // ONE controller per STREAM — glints within a stream share it and stay synced.
    _controllers = _streams.map((stream) {
      final c = AnimationController(
        duration: Duration(milliseconds: stream.cycleMs),
        vsync: this,
      );
      c.repeat();
      return c;
    }).toList(growable: false);
  }

  void _disposeControllers() {
    for (final c in _controllers) {
      c.dispose();
    }
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  String _assetPath(int stripNumber) {
    final tod = widget.timeOfDay.name;
    final suffix = tod == 'day' ? '' : '_$tod';
    return 'assets/shimmer/$tod/water_shimmer_strip_$stripNumber$suffix.png';
  }

  /// Maps a glint's personal t (in [0,1]) to its current opacity.
  /// Position drifts continuously over the whole cycle (no hold phase).
  double _opacityForT(double t, double peak) {
    const fadeInEnd = 0.18;
    const fadeOutStart = 0.82;

    if (t < fadeInEnd) {
      return (t / fadeInEnd) * peak;
    }
    if (t < fadeOutStart) {
      return peak;
    }
    return peak * (1.0 - (t - fadeOutStart) / (1.0 - fadeOutStart));
  }

  @override
  Widget build(BuildContext context) {
    // Stage 1 low (and any other empty config) — render nothing.
    if (_streams.isEmpty) {
      return const SizedBox.shrink();
    }

    final size = MediaQuery.of(context).size;

    // Flatten every (stream × glint) into one big list of widgets.
    final widgets = <Widget>[];
    for (int sIdx = 0; sIdx < _streams.length; sIdx++) {
      final stream = _streams[sIdx];
      final controller = _controllers[sIdx];

      for (int gIdx = 0; gIdx < stream.glintCount; gIdx++) {
        widgets.add(_GlintWidget(
          key: ValueKey('stream${sIdx}_glint$gIdx'),
          stream: stream,
          glintIndex: gIdx,
          controller: controller,
          screenSize: size,
          assetPath: _assetPath(stream.stripNumber),
          resolveOpacity: _opacityForT,
        ));
      }
    }

    return IgnorePointer(
      child: Stack(fit: StackFit.expand, children: widgets),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// _GlintWidget — one glint within a stream
//
// Computes its OWN t as an offset of the stream's controller.value:
//   personalT = (controller.value + glintIndex/glintCount) % 1.0
// then interpolates position from start → end and opacity through the
// fade-in / full / fade-out curve.
// ─────────────────────────────────────────────────────────────────────────

class _GlintWidget extends StatelessWidget {
  final _ShimmerStream stream;
  final int glintIndex;
  final AnimationController controller;
  final Size screenSize;
  final String assetPath;
  final double Function(double t, double peak) resolveOpacity;

  const _GlintWidget({
    required this.stream,
    required this.glintIndex,
    required this.controller,
    required this.screenSize,
    required this.assetPath,
    required this.resolveOpacity,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        // Each glint runs the SAME cycle as the stream's controller, but
        // offset by glintIndex / glintCount.
        final offset = glintIndex / stream.glintCount;
        final t = (controller.value + offset) % 1.0;

        // Position: linear interpolation from start → end over the cycle.
        final xFrac = stream.startX + (stream.endX - stream.startX) * t;
        final yFrac = stream.startY + (stream.endY - stream.startY) * t;

        // Opacity: fade-in / hold / fade-out (NO movement pause).
        final opacity = resolveOpacity(t, stream.peakOpacity).clamp(0.0, 1.0);

        // Asset aspect = 97/183 ≈ 0.530 (height/width).
        const aspect = 97.0 / 183.0;
        final w = stream.widthPx;
        final h = w * aspect;

        final cx = screenSize.width * xFrac;
        final cy = screenSize.height * yFrac;

        return Positioned(
          left: cx - w / 2,
          top: cy - h / 2,
          width: w,
          height: h,
          child: Opacity(
            opacity: opacity,
            child: Transform.rotate(
              angle: stream.rotationDeg * pi / 180.0,
              child: Image.asset(
                assetPath,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ),
        );
      },
    );
  }
}
