// lib/services/mock_api_service.dart
//
// Simulates the real backend API responses.
// In production, replace these with actual HTTP calls to your Node.js server.
//
// Each method returns a Map<String, dynamic> that exactly matches
// the JSON the real backend would return.
//
// The EcosystemState is always nested under "ecosystemState" key,
// matching the real API contract:
//   POST /v1/activities   → { "activity": {...}, "ecosystemState": {...} }
//   POST /v1/moods        → { "mood": {...},     "ecosystemState": {...} }
//   GET  /v1/lake         → { "ecosystemState": {...} }

import 'dart:math';
import '../models/ecosystem_state.dart';

// ─────────────────────────────────────────────────────────────
// Scoring config — mirrors the activity_score_config table
// ─────────────────────────────────────────────────────────────

const Map<String, Map<String, int>> kScoringTiers = {
  'exercise': {'10': 2, '20': 3, '45': 5},
  'meditation': {'3': 2, '5': 3, '10': 5},
  'sleep': {'6': 1, '7': 2, '8': 3},
  'nature': {'10': 1, '30': 2, '60': 3},
  'learning': {'15': 1, '30': 2, '60': 3},
  'productivity': {'30': 1, '60': 2, '120': 3},
  'hobbies': {'15': 1, '30': 2, '60': 3},
};

const Map<String, int> kFixedScores = {
  'hygiene': 1,
  'nutrition': 2,
  'social': 2,
  'health_morning_sunlight': 2,
  'health_sauna': 5,
  'health_cold_plunge': 5,
  'health_journal': 5,
  'health_deep_breaths': 1,
  'mood': 1,
  'social_media_1h': -1,
  'social_media_2h': -3,
  'social_media_3h': -5,
  'junk_food': -3,
  'addictive_behaviour': -5,
  'bad_sleep_6h': -1,
  'bad_sleep_5h': -3,
  'bad_sleep_4h': -5,
};

// ─────────────────────────────────────────────────────────────
// MockApiService
// ─────────────────────────────────────────────────────────────

class MockApiService {
  static final MockApiService _instance = MockApiService._internal();
  factory MockApiService() => _instance;
  MockApiService._internal();

  final _random = Random();

  // Current simulated score — starts at 0 for demo purposes
  int _currentScore = 0;
  int _meditationPts7Days = 0;

  // ── Score clamped to 0–100 ────────────────────────────────────
  int _clamp(int v) => v.clamp(0, 100);

  // ── Simulate network delay (150–350ms) ───────────────────────
  Future<void> _delay() =>
      Future.delayed(Duration(milliseconds: 150 + _random.nextInt(200)));

  // ─────────────────────────────────────────────────────────────
  // GET /v1/lake
  // Called on app launch and resume. Backend applies any passive
  // drain before returning state.
  // ─────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getLakeState() async {
    await _delay();
    return {'ecosystemState': _buildEcosystemState(_currentScore)};
  }

  // ─────────────────────────────────────────────────────────────
  // POST /v1/activities
  // Logs a positive or negative activity and returns updated state.
  // ─────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> logActivity({
    required String category,
    required String subType,
    required int durationMinutes,
    required bool isPositive,
    String? notes,
  }) async {
    await _delay();

    final points = _calculatePoints(category, durationMinutes, isPositive);
    _currentScore = _clamp(_currentScore + points);

    if (category == 'meditation') {
      _meditationPts7Days += points.abs();
    }

    return {
      'activity': {
        'id': 'act_${DateTime.now().millisecondsSinceEpoch}',
        'category': category,
        'subType': subType,
        'durationMinutes': durationMinutes,
        'isPositive': isPositive,
        'pointsAwarded': points,
        'notes': notes,
        'timestamp': DateTime.now().toIso8601String(),
      },
      'pointsAwarded': points,
      'ecosystemState': _buildEcosystemState(_currentScore),
    };
  }

  // ─────────────────────────────────────────────────────────────
  // POST /v1/moods
  // Logs mood (always +1 point).
  // ─────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> logMood(String mood) async {
    await _delay();
    _currentScore = _clamp(_currentScore + 1);
    return {
      'mood': {
        'id': 'mood_${DateTime.now().millisecondsSinceEpoch}',
        'mood': mood,
        'pointsAwarded': 1,
        'timestamp': DateTime.now().toIso8601String(),
      },
      'pointsAwarded': 1,
      'ecosystemState': _buildEcosystemState(_currentScore),
    };
  }

  // ─────────────────────────────────────────────────────────────
  // POST /v1/meditations/:id/complete
  // Marks a meditation as complete, awards lake + bonsai points.
  // ─────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> completeMeditation({
    required String meditationId,
    required int durationMinutes,
  }) async {
    await _delay();
    final points = _calculatePoints('meditation', durationMinutes, true);
    _currentScore = _clamp(_currentScore + points);
    _meditationPts7Days += points;

    return {
      'meditation': {
        'id': meditationId,
        'durationMinutes': durationMinutes,
        'pointsAwarded': points,
        'completedAt': DateTime.now().toIso8601String(),
      },
      'pointsAwarded': points,
      'ecosystemState': _buildEcosystemState(_currentScore),
    };
  }

  // ─────────────────────────────────────────────────────────────
  // Simulate passive midnight drain
  // In production, backend applies this automatically.
  // ─────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> simulateMidnightDrain() async {
    await _delay();
    final drain = (_currentScore >= 5) ? 5 : _currentScore;
    _currentScore = _clamp(_currentScore - drain);
    return {
      'drained': drain,
      'ecosystemState': _buildEcosystemState(_currentScore),
    };
  }

  // ─────────────────────────────────────────────────────────────
  // Direct score setter — for the demo control panel only.
  // Does NOT exist in the real API.
  // ─────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> setScoreDirectly(int score) async {
    await _delay();
    _currentScore = _clamp(score);
    return {'ecosystemState': _buildEcosystemState(_currentScore)};
  }

  // ─────────────────────────────────────────────────────────────
  // Reset for demo
  // ─────────────────────────────────────────────────────────────
  void reset() {
    _currentScore = 0;
    _meditationPts7Days = 0;
  }

  int get currentScore => _currentScore;

  // ─────────────────────────────────────────────────────────────
  // Internal: build the full EcosystemState JSON object
  // This mirrors what Node.js LakeService.buildEcosystemState() does.
  // ─────────────────────────────────────────────────────────────
  Map<String, dynamic> _buildEcosystemState(int score) {
    final stage = _resolveStage(score);
    final waterLevel = _resolveWaterLevel(score);
    final wildlife = _resolveWildlife(stage);
    final bonsai = _resolveBonsai();

    return {
      'lakeScore': score,
      'stage': stage,
      'waterLevel': waterLevel,
      'zones': {
        'physicalForest': _forestZone(stage),
        'vitalityGarden': 'stage_$stage',
        'moonlitMeadow': 'stage_$stage',
        'serenitySpring': 'bonsai_driven',
        'dock': _dockZone(stage),
      },
      'wildlife': wildlife,
      'timeOfDay': EcosystemState.resolveTimeOfDay().name, // from device clock
      'bonsai': bonsai,
    };
  }

  int _resolveStage(int score) {
    if (score <= 30) return 1;
    if (score <= 70) return 2;
    return 3;
  }

  String _resolveWaterLevel(int score) {
    // Stage 1
    if (score <= 10) return 'low';
    if (score <= 20) return 'mid';
    if (score <= 30) return 'high';
    // Stage 2
    if (score <= 45) return 'low';
    if (score <= 60) return 'mid';
    if (score <= 70) return 'high';
    // Stage 3
    if (score <= 80) return 'low';
    if (score <= 90) return 'mid';
    return 'high';
  }

  Map<String, dynamic> _resolveWildlife(int stage) {
    if (stage == 1) {
      return {
        'fish': false,
        'bird': false,
        'rabbit': false,
        'duck': false,
        'otter': false,
        'deer': false,
      };
    }
    if (stage == 2) {
      return {
        'fish': _random.nextDouble() < 0.5,
        'bird': _random.nextDouble() < 0.5,
        'rabbit': _random.nextDouble() < 0.5,
        'duck': false,
        'otter': false,
        'deer': false,
      };
    }
    // Stage 3 — all 75%
    return {
      'fish': _random.nextDouble() < 0.75,
      'bird': _random.nextDouble() < 0.75,
      'rabbit': _random.nextDouble() < 0.75,
      'duck': _random.nextDouble() < 0.75,
      'otter': _random.nextDouble() < 0.75,
      'deer': _random.nextDouble() < 0.75,
    };
  }

  Map<String, dynamic> _resolveBonsai() {
    final pts = _meditationPts7Days;
    String state;
    if (pts >= 15)
      state = 'large';
    else if (pts > 0)
      state = 'small';
    else
      state = 'none';

    return {
      'state': state,
      'meditationPointsLast7Days': pts,
    };
  }

  String _forestZone(int stage) {
    return {1: 'saplings', 2: 'medium_trees', 3: 'full_lush_trees'}[stage]!;
  }

  String _dockZone(int stage) {
    return {1: 'empty', 2: 'one_person', 3: 'two_people'}[stage]!;
  }

  int _calculatePoints(String category, int duration, bool isPositive) {
    if (!isPositive) {
      // Negative activities
      switch (category) {
        case 'social_media':
          if (duration >= 180) return -5;
          if (duration >= 120) return -3;
          return -1;
        case 'bad_sleep':
          if (duration < 240) return -5;
          if (duration < 300) return -3;
          return -1;
        case 'junk_food':
          return -3;
        case 'addictive':
          return -5;
        default:
          return -1;
      }
    }

    // Fixed-point activities (no duration)
    switch (category) {
      case 'hygiene':
        return 1;
      case 'nutrition':
        return 2;
      case 'social':
        return 2;
      case 'mood':
        return 1;
      case 'health':
        if (duration == 0) return 5; // sauna, cold plunge, journal
        break;
    }

    // Duration-based activities
    final tiers = kScoringTiers[category];
    if (tiers == null) return 2; // default

    int points = 0;
    for (final entry in tiers.entries) {
      if (duration >= int.parse(entry.key)) {
        points = entry.value;
      }
    }
    return points == 0 ? 1 : points;
  }
}

// ─────────────────────────────────────────────────────────────
// Pre-defined mock responses for the demo panel
// These are the responses you can cycle through to test animations.
// ─────────────────────────────────────────────────────────────

class MockResponses {
  static Map<String, dynamic> buildState({
    required int score,
    bool fishVisible = false,
    bool birdVisible = false,
    bool rabbitVisible = false,
    bool duckVisible = false,
    bool otterVisible = false,
    bool deerVisible = false,
    String bonsaiState = 'none',
    int meditationPts = 0,
  }) {
    final stage = score <= 30 ? 1 : (score <= 70 ? 2 : 3);
    final wl = _wl(score);
    final forest =
    {1: 'saplings', 2: 'medium_trees', 3: 'full_lush_trees'}[stage]!;
    final dock = {1: 'empty', 2: 'one_person', 3: 'two_people'}[stage]!;

    return {
      'ecosystemState': {
        'lakeScore': score,
        'stage': stage,
        'waterLevel': wl,
        'zones': {
          'physicalForest': forest,
          'vitalityGarden': 'stage_$stage',
          'moonlitMeadow': 'stage_$stage',
          'serenitySpring': 'bonsai_driven',
          'dock': dock,
        },
        'wildlife': {
          'fish': fishVisible,
          'bird': birdVisible,
          'rabbit': rabbitVisible,
          'duck': duckVisible,
          'otter': otterVisible,
          'deer': deerVisible,
        },
        'timeOfDay': EcosystemState.resolveTimeOfDay().name,
        'bonsai': {
          'state': bonsaiState,
          'meditationPointsLast7Days': meditationPts,
        },
      },
    };
  }

  static String _wl(int score) {
    if (score <= 10) return 'low';
    if (score <= 20) return 'mid';
    if (score <= 30) return 'high';
    if (score <= 45) return 'low';
    if (score <= 60) return 'mid';
    if (score <= 70) return 'high';
    if (score <= 80) return 'low';
    if (score <= 90) return 'mid';
    return 'high';
  }

  // ── Scenario list — loaded by the demo panel ─────────────────
  static final List<DemoScenario> scenarios = [
    DemoScenario(
      label: 'Stage 1 · Score 0 · Empty lake',
      description: 'New user. No animals. Stage 1 (saplings). Water very low.',
      response: buildState(score: 0),
      pointsDelta: 0,
    ),
    DemoScenario(
      label: 'Stage 1 · Score 5 · Onboarding done',
      description:
      '+5 points from onboarding. Lake rises a little. Still stage 1.',
      response: buildState(score: 5),
      pointsDelta: 5,
    ),
    DemoScenario(
      label: 'Stage 1 · Score 11 · Water level mid',
      description:
      'Score crosses 11 → water level changes to "mid". Background crossfades.',
      response: buildState(score: 11),
      pointsDelta: 6,
    ),
    DemoScenario(
      label: 'Stage 1 · Score 21 · Water level high',
      description: 'Score crosses 21 → water level "high". Another crossfade.',
      response: buildState(score: 21),
      pointsDelta: 10,
    ),
    DemoScenario(
      label: 'Stage 2 · Score 31 · Animals appear!',
      description:
      'Score crosses 31 → Stage 2 begins. Trees grow. Dock gets one person. Fish, bird, rabbit can appear (50%).',
      response: buildState(
        score: 31,
        fishVisible: true,
        birdVisible: false,
        rabbitVisible: true,
      ),
      pointsDelta: 10,
    ),
    DemoScenario(
      label: 'Stage 2 · Score 46 · Water mid',
      description: 'Score crosses 46 → water level "mid" within stage 2.',
      response: buildState(
        score: 46,
        fishVisible: true,
        birdVisible: true,
        rabbitVisible: false,
      ),
      pointsDelta: 15,
    ),
    DemoScenario(
      label: 'Stage 2 · Score 61 · Water high + bonsai small',
      description:
      'Score crosses 61 → water "high". User also meditated → bonsai_small appears.',
      response: buildState(
        score: 61,
        fishVisible: true,
        birdVisible: true,
        rabbitVisible: true,
        bonsaiState: 'small',
        meditationPts: 5,
      ),
      pointsDelta: 15,
    ),
    DemoScenario(
      label: 'Stage 3 · Score 71 · Full ecosystem!',
      description:
      'Score crosses 71 → Stage 3! Full lush trees. Dock 2 people. Duck, otter, deer can now appear.',
      response: buildState(
        score: 71,
        fishVisible: true,
        birdVisible: true,
        rabbitVisible: false,
        duckVisible: true,
        otterVisible: false,
        deerVisible: true,
        bonsaiState: 'small',
        meditationPts: 10,
      ),
      pointsDelta: 10,
    ),
    DemoScenario(
      label: 'Stage 3 · Score 81 · Water mid · Bonsai large!',
      description:
      'Score 81. 15+ meditation points → bonsai grows to LARGE. All 6 animals can appear.',
      response: buildState(
        score: 81,
        fishVisible: true,
        birdVisible: true,
        rabbitVisible: true,
        duckVisible: true,
        otterVisible: true,
        deerVisible: false,
        bonsaiState: 'large',
        meditationPts: 18,
      ),
      pointsDelta: 10,
    ),
    DemoScenario(
      label: 'Stage 3 · Score 100 · Perfect lake!',
      description:
      'Maximum score. All animals. Bonsai large. Water at its highest.',
      response: buildState(
        score: 100,
        fishVisible: true,
        birdVisible: true,
        rabbitVisible: true,
        duckVisible: true,
        otterVisible: true,
        deerVisible: true,
        bonsaiState: 'large',
        meditationPts: 20,
      ),
      pointsDelta: 19,
    ),
    DemoScenario(
      label: 'Midnight drain · -5 points',
      description:
      'Passive drain applies. Score drops from wherever it was. Animals may disappear if stage drops.',
      response: buildState(
        score: 75,
        fishVisible: true,
        birdVisible: false,
        rabbitVisible: true,
        duckVisible: true,
        otterVisible: false,
        deerVisible: false,
        bonsaiState: 'large',
        meditationPts: 18,
      ),
      pointsDelta: -5,
    ),
    DemoScenario(
      label: 'Negative behaviour · Score drops',
      description:
      'User logged 3h+ social media (-5 pts). Lake drains visibly.',
      response: buildState(
        score: 55,
        fishVisible: true,
        birdVisible: false,
        rabbitVisible: true,
        bonsaiState: 'small',
        meditationPts: 5,
      ),
      pointsDelta: -5,
    ),
  ];
}

class DemoScenario {
  final String label;
  final String description;
  final Map<String, dynamic> response;
  final int pointsDelta; // positive = gain, negative = loss, 0 = no popup

  const DemoScenario({
    required this.label,
    required this.description,
    required this.response,
    required this.pointsDelta,
  });
}
