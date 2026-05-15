// lib/widgets/wildlife_layer.dart
//
// Positions all animals over the lake scene.
//
// TWO BEHAVIOURS:
//
//   1. STATIONARY animals (fish, rabbit, duck, otter, deer)
//      Rendered at config.scenePosition (or one of config.scenePositions
//      when count > 1). They cycle through sprite frames in place.
//
//   2. FLYING animals (bird — config.flyAcross == true)
//      Each copy gets its own FlightPath from config.flightPaths.
//      Different startX / endX / y / duration / rest per copy — so
//      multiple birds clearly look like separate birds with their own
//      flight pattern.
//
// SLEEPING MODE (night):
//   Flying animals stop their journey and sit at scenePosition with the
//   sleeping sprite cycle. Stationary animals just switch sprite sheets.

import 'package:flutter/material.dart' hide TimeOfDay;
import '../models/animal_config.dart';
import '../models/ecosystem_state.dart';
import 'animal_sprite.dart';

class WildlifeLayer extends StatelessWidget {
  final EcosystemState state;

  const WildlifeLayer({required this.state, super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSleeping = state.timeOfDay == TimeOfDay.night;

    final widgets = <Widget>[];

    kAnimalConfigs.forEach((name, config) {
      final isVisible = _isVisible(name);

      for (int copyIndex = 0; copyIndex < config.count; copyIndex++) {
        // ── FLYING animal (bird) ─────────────────────────────────
        if (config.flyAcross && !isSleeping) {
          final path = _flightPathFor(config, copyIndex);
          widgets.add(_FlyJourney(
            key: ValueKey('fly_${name}_$copyIndex'),
            config: config,
            path: path,
            copyIndex: copyIndex,
            isVisible: isVisible,
            isSleeping: isSleeping,
            timeOfDay: state.timeOfDay,
          ));
          continue;
        }

        // ── STATIONARY animal (or sleeping bird) ─────────────────
        final position = _positionFor(config, copyIndex);
        final cx = size.width * position.dx;
        final cy = size.height * position.dy;
        final left = (cx - config.displayWidth / 2)
            .clamp(0.0, size.width - config.displayWidth);
        final top = (cy - config.displayHeight)
            .clamp(0.0, size.height - config.displayHeight);

        widgets.add(Positioned(
          key: ValueKey('still_${name}_$copyIndex'),
          left: left,
          top: top,
          width: config.displayWidth,
          height: config.displayHeight,
          child: AnimalSprite(
            config: config,
            isVisible: isVisible,
            isSleeping: isSleeping,
            timeOfDay: state.timeOfDay,
          ),
        ));
      }
    });

    return Stack(fit: StackFit.expand, children: widgets);
  }

  Offset _positionFor(AnimalConfig config, int copyIndex) {
    if (config.scenePositions.isEmpty) return config.scenePosition;
    return config.scenePositions[copyIndex % config.scenePositions.length];
  }

  /// Pick a FlightPath for copy N. If flightPaths is empty (misconfigured)
  /// fall back to a sensible default full-screen path at scenePosition.dy.
  FlightPath _flightPathFor(AnimalConfig config, int copyIndex) {
    if (config.flightPaths.isEmpty) {
      return FlightPath(
        startX: 1.15,
        endX: -0.15,
        y: config.scenePosition.dy,
        durationMs: 7500,
        restMs: 4000,
      );
    }
    return config.flightPaths[copyIndex % config.flightPaths.length];
  }

  bool _isVisible(String name) {
    switch (name) {
      case 'fish':
        return state.wildlife.fish;
      case 'bird':
        return state.wildlife.bird;
      case 'rabbit':
        return state.wildlife.rabbit;
      case 'duck':
        return state.wildlife.duck;
      case 'otter':
        return state.wildlife.otter;
      case 'deer':
        return state.wildlife.deer;
      default:
        return false;
    }
  }
}

// ─────────────────────────────────────────────────────────────
// _FlyJourney — translates ONE bird along ONE FlightPath
//
// LIFECYCLE (one full cycle):
//   1. waiting — invisible off-screen for (path.restMs + per-copy stagger)
//   2. flying  — translates from (startX, y) to (endX, y) over path.durationMs
//                while AnimalSprite plays the wing-flap cycle
//   3. → goto 1
//
// Each path's own restMs and durationMs are used, so two birds with
// different paths fly at different speeds and rest for different times —
// over a few cycles they completely de-sync and look like two free birds.
// ─────────────────────────────────────────────────────────────

class _FlyJourney extends StatefulWidget {
  final AnimalConfig config;
  final FlightPath path;
  final int copyIndex;
  final bool isVisible;
  final bool isSleeping;
  final TimeOfDay timeOfDay;

  const _FlyJourney({
    required this.config,
    required this.path,
    required this.copyIndex,
    required this.isVisible,
    required this.isSleeping,
    required this.timeOfDay,
    super.key,
  });

  @override
  State<_FlyJourney> createState() => _FlyJourneyState();
}

class _FlyJourneyState extends State<_FlyJourney>
    with SingleTickerProviderStateMixin {
  late AnimationController _flight;
  bool _isFlying = false;

  @override
  void initState() {
    super.initState();
    _flight = AnimationController(
      duration: Duration(milliseconds: widget.path.durationMs),
      vsync: this,
    );

    // Stagger first flight per copy so two birds don't enter together
    // on the very first cycle. After that, their natural duration/rest
    // differences will keep them de-synced.
    final stagger = Duration(
      milliseconds: 400 + widget.copyIndex * (widget.path.durationMs ~/ 2),
    );

    Future.delayed(stagger, _beginFlight);
  }

  void _beginFlight() {
    if (!mounted) return;
    if (!widget.isVisible || widget.isSleeping) {
      _scheduleNextFlight();
      return;
    }

    setState(() => _isFlying = true);
    _flight.forward(from: 0).whenComplete(() {
      if (!mounted) return;
      setState(() => _isFlying = false);
      _scheduleNextFlight();
    });
  }

  void _scheduleNextFlight() {
    Future.delayed(
      Duration(milliseconds: widget.path.restMs),
      _beginFlight,
    );
  }

  @override
  void didUpdateWidget(_FlyJourney old) {
    super.didUpdateWidget(old);

    // If we became invisible or fell asleep mid-flight, abort.
    if ((old.isVisible && !widget.isVisible) ||
        (!old.isSleeping && widget.isSleeping)) {
      _flight.stop();
      setState(() => _isFlying = false);
    }

    // If the FlightPath itself changed (hot reload, config update),
    // update the controller's duration so the next flight uses it.
    if (old.path.durationMs != widget.path.durationMs) {
      _flight.duration = Duration(milliseconds: widget.path.durationMs);
    }
  }

  @override
  void dispose() {
    _flight.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isFlying) return const SizedBox.shrink();

    final size = MediaQuery.of(context).size;
    final cfg = widget.config;
    final path = widget.path;

    return AnimatedBuilder(
      animation: _flight,
      builder: (context, _) {
        final t = _flight.value.clamp(0.0, 1.0);

        // Centre-x interpolates from startX to endX (both are fractions
        // of screen width). The path's startX and endX are already
        // expressed as the bird's CENTRE position, so values like 1.15
        // mean "centre is 15% past the right edge" — which puts the
        // entire sprite off-screen.
        final centreX =
            size.width * (path.startX + (path.endX - path.startX) * t);
        final centreY = size.height * path.y;

        final left = centreX - cfg.displayWidth / 2;
        final top = centreY - cfg.displayHeight;

        // Edge fades: bird fades IN over the first 8% of the flight and
        // fades OUT over the last 8%. This makes partial-traversal paths
        // (where endX is still on-screen) look clean — the bird drifts
        // away gently instead of popping out at endX.
        double opacity;
        if (t < 0.08) {
          opacity = t / 0.08;
        } else if (t > 0.92) {
          opacity = (1.0 - t) / 0.08;
        } else {
          opacity = 1.0;
        }
        opacity = opacity.clamp(0.0, 1.0);

        return Positioned(
          left: left,
          top: top,
          width: cfg.displayWidth,
          height: cfg.displayHeight,
          child: Opacity(
            opacity: opacity,
            child: AnimalSprite(
              config: cfg,
              isVisible: true,
              isSleeping: false,
              timeOfDay: widget.timeOfDay,
            ),
          ),
        );
      },
    );
  }
}
