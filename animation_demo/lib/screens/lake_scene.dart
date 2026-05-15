// lib/widgets/lake_scene.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/lake_provider.dart';
import '../widjets/lake_background.dart';
import '../widjets/water_shimmer.dart';
import '../widjets/wildlife_layer.dart';
import '../widjets/bonsai_widget.dart';
import '../widjets/lake_score_display.dart';
import '../widjets/points_popup.dart';

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
        LakeBackground(assetPath: ecosystemState.backgroundAssetPath),
        WaterShimmer(timeOfDay: ecosystemState.timeOfDay),
        WildlifeLayer(state: ecosystemState),
        Positioned(
          left: size.width * 0.70,
          top: size.height * 0.75,
          child: BonsaiWidget(
            bonsaiState: ecosystemState.bonsai.state,
            timeOfDay: ecosystemState.timeOfDay,
          ),
        ),
        Positioned(
          top: MediaQuery.of(context).padding.top,
          left: 16,
          child: LakeScoreDisplay(
            score: ecosystemState.lakeScore,
            stage: ecosystemState.stage,
            waterLevel: ecosystemState.waterLevel.name,
          ),
        ),
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
