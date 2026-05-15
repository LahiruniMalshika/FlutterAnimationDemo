// lib/models/ecosystem_state.dart
//
// This Dart class mirrors the exact JSON the backend sends.
// Backend sends this after every activity log, mood log,
// meditation complete, or GET /v1/lake on app launch.

// ─────────────────────────────────────────────────────────────
// Enums — only these exact string values are valid
// ─────────────────────────────────────────────────────────────

/// Which third of the day it is — resolved from the DEVICE CLOCK,
/// not from the backend value (backend value is ignored at render time).
enum TimeOfDay {
  day, // 06:00 – 16:59
  dusk, // 17:00 – 19:59
  night, // 20:00 – 05:59
}

/// How full the water is within its stage.
enum WaterLevel { low, mid, high }

/// Bonsai growth state — driven by meditation points in last 7 days.
enum BonsaiState {
  none, // no meditation in last 7 days
  small, // any meditation logged
  large, // 15+ meditation points
}

// ─────────────────────────────────────────────────────────────
// Wildlife — which animals are currently visible
// ─────────────────────────────────────────────────────────────

class WildlifeState {
  final bool fish;
  final bool bird;
  final bool rabbit;
  final bool duck; // stage 3 only
  final bool otter; // stage 3 only
  final bool deer; // stage 3 only

  const WildlifeState({
    required this.fish,
    required this.bird,
    required this.rabbit,
    required this.duck,
    required this.otter,
    required this.deer,
  });

  /// All animals hidden — used for stage 1 (score 0–30).
  factory WildlifeState.none() => const WildlifeState(
    fish: false,
    bird: false,
    rabbit: false,
    duck: false,
    otter: false,
    deer: false,
  );

  factory WildlifeState.fromJson(Map<String, dynamic> json) => WildlifeState(
    fish: json['fish'] as bool? ?? false,
    bird: json['bird'] as bool? ?? false,
    rabbit: json['rabbit'] as bool? ?? false,
    duck: json['duck'] as bool? ?? false,
    otter: json['otter'] as bool? ?? false,
    deer: json['deer'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'fish': fish,
    'bird': bird,
    'rabbit': rabbit,
    'duck': duck,
    'otter': otter,
    'deer': deer,
  };

  @override
  String toString() => 'Wildlife(fish:$fish bird:$bird rabbit:$rabbit '
      'duck:$duck otter:$otter deer:$deer)';
}

// ─────────────────────────────────────────────────────────────
// Ecosystem zones — visual state of each scene zone
// ─────────────────────────────────────────────────────────────

class ZoneState {
  final String
  physicalForest; // "saplings" | "medium_trees" | "full_lush_trees"
  final String vitalityGarden; // "stage_1" | "stage_2" | "stage_3"
  final String moonlitMeadow; // "stage_1" | "stage_2" | "stage_3"
  final String
  serenitySpring; // "bonsai_driven" (always — bonsai resolved separately)
  final String dock; // "empty" | "one_person" | "two_people"

  const ZoneState({
    required this.physicalForest,
    required this.vitalityGarden,
    required this.moonlitMeadow,
    required this.serenitySpring,
    required this.dock,
  });

  factory ZoneState.fromStage(int stage) {
    final forestMap = {1: 'saplings', 2: 'medium_trees', 3: 'full_lush_trees'};
    final dockMap = {1: 'empty', 2: 'one_person', 3: 'two_people'};
    return ZoneState(
      physicalForest: forestMap[stage]!,
      vitalityGarden: 'stage_$stage',
      moonlitMeadow: 'stage_$stage',
      serenitySpring: 'bonsai_driven',
      dock: dockMap[stage]!,
    );
  }

  factory ZoneState.fromJson(Map<String, dynamic> json) => ZoneState(
    physicalForest: json['physicalForest'] as String,
    vitalityGarden: json['vitalityGarden'] as String,
    moonlitMeadow: json['moonlitMeadow'] as String,
    serenitySpring: json['serenitySpring'] as String,
    dock: json['dock'] as String,
  );
}

// ─────────────────────────────────────────────────────────────
// BonsaiInfo — meditation-driven tree state
// ─────────────────────────────────────────────────────────────

class BonsaiInfo {
  final BonsaiState state;
  final int meditationPointsLast7Days;

  const BonsaiInfo(
      {required this.state, required this.meditationPointsLast7Days});

  factory BonsaiInfo.fromJson(Map<String, dynamic> json) {
    final raw = json['state'] as String? ?? 'none';
    final state = BonsaiState.values.firstWhere(
          (e) => e.name == raw,
      orElse: () => BonsaiState.none,
    );
    return BonsaiInfo(
      state: state,
      meditationPointsLast7Days: json['meditationPointsLast7Days'] as int? ?? 0,
    );
  }
}

// ─────────────────────────────────────────────────────────────
// EcosystemState — the master state object
// ─────────────────────────────────────────────────────────────

class EcosystemState {
  final int lakeScore; // 0–100
  final int stage; // 1, 2, or 3
  final WaterLevel waterLevel; // low | mid | high
  final ZoneState zones;
  final WildlifeState wildlife;
  final TimeOfDay timeOfDay; // Flutter overrides with device clock
  final BonsaiInfo bonsai;

  const EcosystemState({
    required this.lakeScore,
    required this.stage,
    required this.waterLevel,
    required this.zones,
    required this.wildlife,
    required this.timeOfDay,
    required this.bonsai,
  });

  // ── Starting state — lake at 0, everything empty ──────────────
  factory EcosystemState.initial() => EcosystemState(
    lakeScore: 0,
    stage: 1,
    waterLevel: WaterLevel.low,
    zones: ZoneState.fromStage(1),
    wildlife: WildlifeState.none(),
    timeOfDay: EcosystemState.resolveTimeOfDay(),
    bonsai: const BonsaiInfo(
        state: BonsaiState.none, meditationPointsLast7Days: 0),
  );

  // ── Parse backend JSON ─────────────────────────────────────────
  factory EcosystemState.fromJson(Map<String, dynamic> json) {
    final waterLevelStr = json['waterLevel'] as String? ?? 'low';
    final waterLevel = WaterLevel.values.firstWhere(
          (e) => e.name == waterLevelStr,
      orElse: () => WaterLevel.low,
    );

    return EcosystemState(
      lakeScore: json['lakeScore'] as int,
      stage: json['stage'] as int,
      waterLevel: waterLevel,
      zones: ZoneState.fromJson(json['zones'] as Map<String, dynamic>),
      wildlife:
      WildlifeState.fromJson(json['wildlife'] as Map<String, dynamic>),
      timeOfDay: EcosystemState.resolveTimeOfDay(), // always from device clock
      bonsai: BonsaiInfo.fromJson(json['bonsai'] as Map<String, dynamic>),
    );
  }

  // ── Resolve time of day from device clock ─────────────────────
  // This is always called by Flutter — the server's timeOfDay field is ignored.
  static TimeOfDay resolveTimeOfDay() {
    final hour = DateTime.now().hour;
    if (hour >= 6 && hour < 17) return TimeOfDay.day;
    if (hour >= 17 && hour < 24) return TimeOfDay.dusk;
    return TimeOfDay.night;
  }

  // ── Derive the correct background image asset path ────────────
  // Returns e.g. "assets/backgrounds/day/stage2_water_mid.png"
  String get backgroundAssetPath {
    final tod = timeOfDay.name; // "day" | "dusk" | "night"
    final lvl = waterLevel.name; // "low" | "mid" | "high"
    return 'assets/backgrounds/$tod/stage${stage}_water_$lvl.png';
  }

  // ── Copy with changed values (immutable update) ───────────────
  EcosystemState copyWith({
    int? lakeScore,
    int? stage,
    WaterLevel? waterLevel,
    ZoneState? zones,
    WildlifeState? wildlife,
    TimeOfDay? timeOfDay,
    BonsaiInfo? bonsai,
  }) {
    return EcosystemState(
      lakeScore: lakeScore ?? this.lakeScore,
      stage: stage ?? this.stage,
      waterLevel: waterLevel ?? this.waterLevel,
      zones: zones ?? this.zones,
      wildlife: wildlife ?? this.wildlife,
      timeOfDay: timeOfDay ?? this.timeOfDay,
      bonsai: bonsai ?? this.bonsai,
    );
  }

  @override
  String toString() => 'EcosystemState(score:$lakeScore stage:$stage '
      'level:${waterLevel.name} tod:${timeOfDay.name} bonsai:${bonsai.state.name})';
}
