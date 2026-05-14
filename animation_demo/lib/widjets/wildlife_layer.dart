// lib/widgets/wildlife_layer.dart
//
// Positions all 6 animals over the lake scene using absolute coordinates.
//
// Each animal has a fixed position defined in AnimalConfig.scenePosition
// as fractions of the screen size. For example, (0.38, 0.58) means:
//   left = 38% of screen width
//   top  = 58% of screen height
//
// NIGHT RULE:
// When timeOfDay == night, all animals switch to their sleeping
// sprite sheets automatically. The AnimalSprite widget handles this.
//
// STAGE 3 ONLY ANIMALS:
// Duck, otter, deer can only spawn in stage 3 (score 71+).
// Even if wildlife.duck == true, we check minStage before showing.

import 'package:animation_demo/widjets/animal_sprite.dart';
import 'package:flutter/material.dart' hide TimeOfDay;
import '../models/animal_config.dart';
import '../models/ecosystem_state.dart';

class WildlifeLayer extends StatelessWidget {
  final EcosystemState state;

  const WildlifeLayer({required this.state, super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSleeping = state.timeOfDay == TimeOfDay.night;

    return Stack(
      fit: StackFit.expand,
      children: kAnimalConfigs.entries.map((entry) {
        final name = entry.key;
        final config = entry.value;

        final isVisible = _isAnimalVisible(name);
        final left =
            size.width * config.scenePosition.dx - (config.displayWidth / 2);
        final top =
            size.height * config.scenePosition.dy - (config.displayWidth / 2);

        return Positioned(
          left: left.clamp(0.0, size.width - config.displayWidth),
          top: top.clamp(0.0, size.height - config.displayWidth),
          width: config.displayWidth,
          height: config.displayWidth,
          child: AnimalSprite(
            config: config,
            isVisible: isVisible,
            isSleeping: isSleeping,
            timeOfDay: state.timeOfDay,
          ),
        );
      }).toList(),
    );
  }

  // ── Determine if a specific animal should be visible ──────────
  bool _isAnimalVisible(String name) {
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
