// lib/providers/lake_provider.dart

import 'package:animation_demo/mock_api_service/mock_api_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ecosystem_state.dart';

class PendingPointsNotifier extends StateNotifier<int?> {
  PendingPointsNotifier() : super(null);
  void show(int points) => state = points;
  void clear() => state = null;
}

final pendingPointsProvider =
    StateNotifierProvider<PendingPointsNotifier, int?>(
  (_) => PendingPointsNotifier(),
);

class LakeNotifier extends StateNotifier<EcosystemState> {
  final MockApiService _api;
  final PendingPointsNotifier _pointsNotifier;

  LakeNotifier(this._api, this._pointsNotifier)
      : super(EcosystemState.initial()) {
    loadInitialState();
  }

  Future<void> loadInitialState() async {
    try {
      final response = await _api.getLakeState();
      state = EcosystemState.fromJson(
          response['ecosystemState'] as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Failed to load lake state: $e');
    }
  }

  Future<void> refreshOnResume() async {
    final previousScore = state.lakeScore;
    try {
      final response = await _api.getLakeState();
      final newState = EcosystemState.fromJson(
          response['ecosystemState'] as Map<String, dynamic>);
      if (newState.lakeScore < previousScore) {
        _pointsNotifier.show(newState.lakeScore - previousScore);
      }
      state = newState;
    } catch (e) {
      debugPrint('Refresh on resume failed: $e');
    }
  }

  Future<void> logActivity({
    required String category,
    required String subType,
    required int durationMinutes,
    bool isPositive = true,
  }) async {
    try {
      final response = await _api.logActivity(
        category: category,
        subType: subType,
        durationMinutes: durationMinutes,
        isPositive: isPositive,
      );
      _pointsNotifier.show(response['pointsAwarded'] as int);
      state = EcosystemState.fromJson(
          response['ecosystemState'] as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Log activity failed: $e');
    }
  }

  Future<void> logMood(String mood) async {
    try {
      final response = await _api.logMood(mood);
      _pointsNotifier.show(1);
      state = EcosystemState.fromJson(
          response['ecosystemState'] as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Log mood failed: $e');
    }
  }

  Future<void> completeMeditation({
    required String meditationId,
    required int durationMinutes,
  }) async {
    try {
      final response = await _api.completeMeditation(
        meditationId: meditationId,
        durationMinutes: durationMinutes,
      );
      _pointsNotifier.show(response['pointsAwarded'] as int);
      state = EcosystemState.fromJson(
          response['ecosystemState'] as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Complete meditation failed: $e');
    }
  }

  Future<void> simulateDrain() async {
    try {
      final response = await _api.simulateMidnightDrain();
      _pointsNotifier.show(-(response['drained'] as int));
      state = EcosystemState.fromJson(
          response['ecosystemState'] as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Simulate drain failed: $e');
    }
  }

  Future<void> loadScenario(DemoScenario scenario) async {
    await Future.delayed(const Duration(milliseconds: 180));
    final newState = EcosystemState.fromJson(
        scenario.response['ecosystemState'] as Map<String, dynamic>);
    if (scenario.pointsDelta != 0) {
      _pointsNotifier.show(scenario.pointsDelta);
    }
    state = newState;
  }

  Future<void> setScore(int score) async {
    try {
      final prevScore = state.lakeScore;
      final response = await _api.setScoreDirectly(score);
      final newState = EcosystemState.fromJson(
          response['ecosystemState'] as Map<String, dynamic>);
      final delta = newState.lakeScore - prevScore;
      if (delta != 0) _pointsNotifier.show(delta);
      state = newState;
    } catch (e) {
      debugPrint('Set score failed: $e');
    }
  }
}

final apiServiceProvider = Provider<MockApiService>((_) => MockApiService());

final lakeProvider = StateNotifierProvider<LakeNotifier, EcosystemState>((ref) {
  final api = ref.read(apiServiceProvider);
  final pointsNotifier = ref.read(pendingPointsProvider.notifier);
  return LakeNotifier(api, pointsNotifier);
});
