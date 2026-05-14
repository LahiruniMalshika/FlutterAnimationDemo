// lib/widgets/lake_scene.dart
//
// The master widget that composes all visual layers of the lake scene.
//
// LAYER ORDER (bottom to top):
//   1. LakeBackground  — the full-scene illustration (crossfades between 27 images)
//   2. WaterShimmer    — looping shimmer strips over the water surface
//   3. WildlifeLayer   — all 6 animals at their fixed positions
//   4. BonsaiWidget    — bonsai tree at Serenity Spring coordinates
//   5. LakeScoreDisplay — score counter + stage info (top-left)
//   6. ZoneInfoOverlay — zone states shown top-right (demo only)
//   7. PointsPopup     — +N / -N floating badge (centre screen)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ecosystem_state.dart';
import '../providers/lake_provider.dart';
import 'lake_background.dart';
import 'water_shimmer.dart';
import 'wildlife_layer.dart';
import 'bonsai_widget.dart';
import 'lake_score_display.dart';
import 'points_popup.dart';

class LakeScene extends ConsumerWidget {
  const LakeScene({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ecosystemState = ref.watch(lakeProvider);
    final pendingPoints = ref.watch(pendingPointsProvider);
    final size = MediaQuery.of(context).size;

    return Stack(
      fit: StackFit.expand,
      children: [
        // ── Layer 1: Background ─────────────────────────────────
        LakeBackground(assetPath: ecosystemState.backgroundAssetPath),

        // ── Layer 2: Water shimmer ──────────────────────────────
        WaterShimmer(timeOfDay: ecosystemState.timeOfDay),

        // ── Layer 3: Animals ────────────────────────────────────
        WildlifeLayer(state: ecosystemState),

        // ── Layer 4: Bonsai ─────────────────────────────────────
        Positioned(
          left: size.width * 0.65,
          top: size.height * 0.46,
          child: BonsaiWidget(
            bonsaiState: ecosystemState.bonsai.state,
            timeOfDay: ecosystemState.timeOfDay,
          ),
        ),

        // ── Layer 5: Score display (top left) ───────────────────
        Positioned(
          top: MediaQuery.of(context).padding.top + 16,
          left: 16,
          child: LakeScoreDisplay(
            score: ecosystemState.lakeScore,
            stage: ecosystemState.stage,
            waterLevel: ecosystemState.waterLevel.name,
          ),
        ),

        // ── Layer 6: Zone info overlay (top right, demo only) ───
        Positioned(
          top: MediaQuery.of(context).padding.top + 16,
          right: 16,
          child: _ZoneInfoOverlay(state: ecosystemState),
        ),

        // ── Layer 7: Points popup ───────────────────────────────
        if (pendingPoints != null)
          Center(
            child: PointsPopup(
              points: pendingPoints,
              onComplete: () =>
                  ref.read(pendingPointsProvider.notifier).clear(),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Zone Info Overlay — shows current zone states for demo
// This panel is for debugging only — not part of the real app UI.
// ─────────────────────────────────────────────────────────────

class _ZoneInfoOverlay extends StatelessWidget {
  final EcosystemState state;
  const _ZoneInfoOverlay({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.42),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          _row('🌲', state.zones.physicalForest.replaceAll('_', ' ')),
          _row('🚣', state.zones.dock.replaceAll('_', ' ')),
          _row('🌱', 'bonsai: ${state.bonsai.state.name}'),
          _row('🕐', state.timeOfDay.name),
          _row('🏔', 'stage ${state.stage} · ${state.waterLevel.name}'),
          _row('🐾', _wildlifeStr()),
        ],
      ),
    );
  }

  Widget _row(String icon, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: Text(
        '$icon  $label',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _wildlifeStr() {
    final w = state.wildlife;
    final shown = <String>[];
    if (w.fish) shown.add('🐟');
    if (w.bird) shown.add('🐦');
    if (w.rabbit) shown.add('🐰');
    if (w.duck) shown.add('🦆');
    if (w.otter) shown.add('🦦');
    if (w.deer) shown.add('🦌');
    return shown.isEmpty ? 'none' : shown.join(' ');
  }
}
