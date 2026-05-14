// lib/widgets/demo_control_panel.dart
//
// The demo control panel that lets you:
//   1. Step through pre-defined mock API scenarios
//   2. Log specific activities with the mock API
//   3. Set the score directly with a slider
//   4. Simulate midnight drain
//
// This panel IS NOT part of the real app.
// In production, activities are logged through the regular activity log screen.
//
// TAB STRUCTURE:
//   Tab 1 — Scenarios: pre-built API responses showing all ecosystem states
//   Tab 2 — Activities: log specific activities and watch the score change
//   Tab 3 — Slider: set score directly to any value

import 'package:animation_demo/mock_api_service/mock_api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/lake_provider.dart';

class DemoControlPanel extends ConsumerStatefulWidget {
  const DemoControlPanel({super.key});

  @override
  ConsumerState<DemoControlPanel> createState() => _DemoControlPanelState();
}

class _DemoControlPanelState extends ConsumerState<DemoControlPanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  double _sliderValue = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _runWithLoading(Future<void> Function() action) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentScore = ref.watch(lakeProvider).lakeScore;

    return Container(
      height: MediaQuery.of(context).size.height * 0.52,
      decoration: const BoxDecoration(
        color: Color(0xFF1C2833),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // ── Handle bar ──────────────────────────────────────────
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 4),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // ── Header ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                const Text(
                  'Demo Control Panel',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Score: $currentScore',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ),
                if (_isLoading) ...[
                  const SizedBox(width: 8),
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white54,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ── Tab bar ─────────────────────────────────────────────
          TabBar(
            controller: _tabController,
            indicatorColor: const Color(0xFF4CAF50),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white38,
            labelStyle:
                const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            tabs: const [
              Tab(text: 'Scenarios'),
              Tab(text: 'Activities'),
              Tab(text: 'Slider'),
            ],
          ),

          // ── Tab views ───────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _ScenariosTab(onRun: _runWithLoading),
                _ActivitiesTab(onRun: _runWithLoading),
                _SliderTab(
                  value: _sliderValue,
                  currentScore: currentScore,
                  onChanged: (v) => setState(() => _sliderValue = v),
                  onSet: _runWithLoading,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Tab 1: Scenarios — pre-defined API responses
// ─────────────────────────────────────────────────────────────

class _ScenariosTab extends ConsumerWidget {
  final Future<void> Function(Future<void> Function()) onRun;
  const _ScenariosTab({required this.onRun});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scenarios = MockResponses.scenarios;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: scenarios.length,
      itemBuilder: (context, index) {
        final scenario = scenarios[index];
        final pointsDelta = scenario.pointsDelta;
        final isPositive = pointsDelta >= 0;

        return Card(
          color: const Color(0xFF263238),
          margin: const EdgeInsets.only(bottom: 8),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            title: Text(
              scenario.label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                scenario.description,
                style: const TextStyle(color: Colors.white54, fontSize: 11),
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (pointsDelta != 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isPositive
                          ? const Color(0xFF1B5E20)
                          : const Color(0xFF7F0000),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isPositive ? '+$pointsDelta' : '$pointsDelta',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.play_arrow, color: Color(0xFF4CAF50)),
                  onPressed: () => onRun(() =>
                      ref.read(lakeProvider.notifier).loadScenario(scenario)),
                ),
              ],
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Tab 2: Activities — log specific activities
// ─────────────────────────────────────────────────────────────

class _ActivitiesTab extends ConsumerWidget {
  final Future<void> Function(Future<void> Function()) onRun;
  const _ActivitiesTab({required this.onRun});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Positive activities ───────────────────────────────
          const _SectionLabel('✅ Positive Activities'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ActivityBtn(
                  '🏃 Exercise 45min',
                  '+5',
                  () => onRun(() => ref.read(lakeProvider.notifier).logActivity(
                        category: 'exercise',
                        subType: 'cardio',
                        durationMinutes: 45,
                        isPositive: true,
                      ))),
              _ActivityBtn(
                  '🏃 Exercise 20min',
                  '+3',
                  () => onRun(() => ref.read(lakeProvider.notifier).logActivity(
                        category: 'exercise',
                        subType: 'cardio',
                        durationMinutes: 20,
                        isPositive: true,
                      ))),
              _ActivityBtn(
                  '🧘 Meditate 10min',
                  '+5',
                  () => onRun(
                      () => ref.read(lakeProvider.notifier).completeMeditation(
                            meditationId: 'med_001',
                            durationMinutes: 10,
                          ))),
              _ActivityBtn(
                  '🧘 Meditate 5min',
                  '+3',
                  () => onRun(
                      () => ref.read(lakeProvider.notifier).completeMeditation(
                            meditationId: 'med_002',
                            durationMinutes: 5,
                          ))),
              _ActivityBtn(
                  '😴 Sleep 8h',
                  '+3',
                  () => onRun(() => ref.read(lakeProvider.notifier).logActivity(
                        category: 'sleep',
                        subType: '',
                        durationMinutes: 480,
                        isPositive: true,
                      ))),
              _ActivityBtn(
                  '🥗 Healthy meal',
                  '+2',
                  () => onRun(() => ref.read(lakeProvider.notifier).logActivity(
                        category: 'nutrition',
                        subType: '',
                        durationMinutes: 0,
                        isPositive: true,
                      ))),
              _ActivityBtn(
                  '👫 Social',
                  '+2',
                  () => onRun(() => ref.read(lakeProvider.notifier).logActivity(
                        category: 'social',
                        subType: 'quality_time',
                        durationMinutes: 0,
                        isPositive: true,
                      ))),
              _ActivityBtn(
                  '🪥 Hygiene',
                  '+1',
                  () => onRun(() => ref.read(lakeProvider.notifier).logActivity(
                        category: 'hygiene',
                        subType: 'shower',
                        durationMinutes: 0,
                        isPositive: true,
                      ))),
              _ActivityBtn(
                  '🧊 Cold plunge',
                  '+5',
                  () => onRun(() => ref.read(lakeProvider.notifier).logActivity(
                        category: 'health',
                        subType: 'cold_plunge',
                        durationMinutes: 0,
                        isPositive: true,
                      ))),
              _ActivityBtn(
                  '😊 Mood log',
                  '+1',
                  () => onRun(
                      () => ref.read(lakeProvider.notifier).logMood('good'))),
              _ActivityBtn(
                  '🎉 Onboarding',
                  '+5',
                  () => onRun(() => ref.read(lakeProvider.notifier).logActivity(
                        category: 'onboarding',
                        subType: '',
                        durationMinutes: 0,
                        isPositive: true,
                      ))),
            ],
          ),

          const SizedBox(height: 16),

          // ── Negative activities ───────────────────────────────
          const _SectionLabel('❌ Negative Activities'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ActivityBtn(
                  '📱 Social media 3h',
                  '-5',
                  () => onRun(() => ref.read(lakeProvider.notifier).logActivity(
                        category: 'social_media',
                        subType: '',
                        durationMinutes: 180,
                        isPositive: false,
                      )),
                  isNeg: true),
              _ActivityBtn(
                  '📱 Social media 2h',
                  '-3',
                  () => onRun(() => ref.read(lakeProvider.notifier).logActivity(
                        category: 'social_media',
                        subType: '',
                        durationMinutes: 120,
                        isPositive: false,
                      )),
                  isNeg: true),
              _ActivityBtn(
                  '🍔 Junk food',
                  '-3',
                  () => onRun(() => ref.read(lakeProvider.notifier).logActivity(
                        category: 'junk_food',
                        subType: '',
                        durationMinutes: 0,
                        isPositive: false,
                      )),
                  isNeg: true),
              _ActivityBtn(
                  '⚠️ Addictive',
                  '-5',
                  () => onRun(() => ref.read(lakeProvider.notifier).logActivity(
                        category: 'addictive',
                        subType: '',
                        durationMinutes: 0,
                        isPositive: false,
                      )),
                  isNeg: true),
              _ActivityBtn(
                  '🌙 Midnight drain',
                  '-5',
                  () => onRun(
                      () => ref.read(lakeProvider.notifier).simulateDrain()),
                  isNeg: true),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _ActivityBtn extends StatelessWidget {
  final String label;
  final String points;
  final VoidCallback onTap;
  final bool isNeg;

  const _ActivityBtn(this.label, this.points, this.onTap, {this.isNeg = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isNeg
              ? const Color(0xFF4E0000).withOpacity(0.8)
              : const Color(0xFF1B3A1B).withOpacity(0.8),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isNeg
                ? const Color(0xFFE57373).withOpacity(0.4)
                : const Color(0xFF81C784).withOpacity(0.4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: const TextStyle(color: Colors.white, fontSize: 12)),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color:
                    isNeg ? const Color(0xFFB71C1C) : const Color(0xFF2E7D32),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                points,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Tab 3: Slider — set score directly
// ─────────────────────────────────────────────────────────────

class _SliderTab extends ConsumerWidget {
  final double value;
  final int currentScore;
  final ValueChanged<double> onChanged;
  final Future<void> Function(Future<void> Function()) onSet;

  const _SliderTab({
    required this.value,
    required this.currentScore,
    required this.onChanged,
    required this.onSet,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Set lake score directly',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 16),

          // Score display
          Center(
            child: Text(
              '${value.round()}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 48,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Slider
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFF4CAF50),
              inactiveTrackColor: Colors.white24,
              thumbColor: Colors.white,
              overlayColor: Colors.white12,
              trackHeight: 4,
            ),
            child: Slider(
              value: value,
              min: 0,
              max: 100,
              divisions: 100,
              onChanged: onChanged,
            ),
          ),

          // Stage markers
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _marker('0', 'Stage 1'),
              _marker('30', ''),
              _marker('31', 'Stage 2'),
              _marker('70', ''),
              _marker('71', 'Stage 3'),
              _marker('100', ''),
            ],
          ),

          const SizedBox(height: 20),

          // Apply button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => onSet(() =>
                  ref.read(lakeProvider.notifier).setScore(value.round())),
              child: Text(
                'Apply Score → ${value.round()}',
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Quick preset buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [0, 5, 31, 46, 71, 81, 100]
                .map(
                  (v) => GestureDetector(
                    onTap: () {
                      onChanged(v.toDouble());
                      onSet(() => ref.read(lakeProvider.notifier).setScore(v));
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white12,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$v',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _marker(String score, String label) {
    return Column(
      children: [
        Text(score, style: const TextStyle(color: Colors.white38, fontSize: 9)),
        if (label.isNotEmpty)
          Text(label,
              style: const TextStyle(color: Colors.white24, fontSize: 8)),
      ],
    );
  }
}
