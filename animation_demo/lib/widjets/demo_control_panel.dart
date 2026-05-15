// lib/widgets/demo_control_panel.dart
import 'package:baseline/mock_api_service/mock_api_service.dart';
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

  Future<void> _run(Future<void> Function() action) async {
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
    final score = ref.watch(lakeProvider).lakeScore;
    return Container(
      height: MediaQuery.of(context).size.height * 0.52,
      decoration: const BoxDecoration(
        color: Color(0xFF1C2833),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(children: [
        Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 4),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.white24, borderRadius: BorderRadius.circular(2)),
            )),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(children: [
            const Text('Demo Control Panel',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(12)),
              child: Text('Score: $score',
                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ),
            if (_isLoading) ...[
              const SizedBox(width: 8),
              const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white54)),
            ],
          ]),
        ),
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
            Tab(text: 'Slider')
          ],
        ),
        Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _ScenariosTab(onRun: _run),
                _ActivitiesTab(onRun: _run),
                _SliderTab(
                    value: _sliderValue,
                    onChanged: (v) => setState(() => _sliderValue = v),
                    onSet: _run),
              ],
            )),
      ]),
    );
  }
}

class _ScenariosTab extends ConsumerWidget {
  final Future<void> Function(Future<void> Function()) onRun;
  const _ScenariosTab({required this.onRun});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: MockResponses.scenarios.length,
      itemBuilder: (_, i) {
        final s = MockResponses.scenarios[i];
        final isPos = s.pointsDelta >= 0;
        return Card(
          color: const Color(0xFF263238),
          margin: const EdgeInsets.only(bottom: 8),
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            title: Text(s.label,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
            subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(s.description,
                    style:
                    const TextStyle(color: Colors.white54, fontSize: 11))),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              if (s.pointsDelta != 0)
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: isPos
                          ? const Color(0xFF1B5E20)
                          : const Color(0xFF7F0000),
                      borderRadius: BorderRadius.circular(8)),
                  child: Text(isPos ? '+${s.pointsDelta}' : '${s.pointsDelta}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.play_arrow, color: Color(0xFF4CAF50)),
                onPressed: () => onRun(
                        () => ref.read(lakeProvider.notifier).loadScenario(s)),
              ),
            ]),
            isThreeLine: true,
          ),
        );
      },
    );
  }
}

class _ActivitiesTab extends ConsumerWidget {
  final Future<void> Function(Future<void> Function()) onRun;
  const _ActivitiesTab({required this.onRun});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void log(String cat, String sub, int dur, {bool pos = true}) =>
        onRun(() => ref.read(lakeProvider.notifier).logActivity(
            category: cat,
            subType: sub,
            durationMinutes: dur,
            isPositive: pos));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const _Label('✅ Positive Activities'),
        Wrap(spacing: 8, runSpacing: 8, children: [
          _Btn('🏃 Exercise 45min', '+5', () => log('exercise', 'cardio', 45)),
          _Btn('🏃 Exercise 20min', '+3', () => log('exercise', 'cardio', 20)),
          _Btn(
              '🧘 Meditate 10min',
              '+5',
                  () => onRun(() => ref
                  .read(lakeProvider.notifier)
                  .completeMeditation(
                  meditationId: 'm1', durationMinutes: 10))),
          _Btn(
              '🧘 Meditate 5min',
              '+3',
                  () => onRun(() => ref
                  .read(lakeProvider.notifier)
                  .completeMeditation(meditationId: 'm2', durationMinutes: 5))),
          _Btn('😴 Sleep 8h', '+3', () => log('sleep', '', 480)),
          _Btn('🥗 Healthy meal', '+2', () => log('nutrition', '', 0)),
          _Btn('👫 Social', '+2', () => log('social', 'quality_time', 0)),
          _Btn('🪥 Hygiene', '+1', () => log('hygiene', 'shower', 0)),
          _Btn('🧊 Cold plunge', '+5', () => log('health', 'cold_plunge', 0)),
          _Btn(
              '😊 Mood log',
              '+1',
                  () =>
                  onRun(() => ref.read(lakeProvider.notifier).logMood('good'))),
          _Btn('🎉 Onboarding', '+5', () => log('onboarding', '', 0)),
        ]),
        const SizedBox(height: 16),
        const _Label('❌ Negative Activities'),
        Wrap(spacing: 8, runSpacing: 8, children: [
          _Btn('📱 Social media 3h', '-5',
                  () => log('social_media', '', 180, pos: false),
              neg: true),
          _Btn('📱 Social media 2h', '-3',
                  () => log('social_media', '', 120, pos: false),
              neg: true),
          _Btn('🍔 Junk food', '-3', () => log('junk_food', '', 0, pos: false),
              neg: true),
          _Btn('⚠️ Addictive', '-5', () => log('addictive', '', 0, pos: false),
              neg: true),
          _Btn(
              '🌙 Midnight drain',
              '-5',
                  () =>
                  onRun(() => ref.read(lakeProvider.notifier).simulateDrain()),
              neg: true),
        ]),
      ]),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text,
        style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w600)),
  );
}

class _Btn extends StatelessWidget {
  final String label, pts;
  final VoidCallback onTap;
  final bool neg;
  const _Btn(this.label, this.pts, this.onTap, {this.neg = false});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: neg
            ? const Color(0xFF4E0000).withOpacity(0.8)
            : const Color(0xFF1B3A1B).withOpacity(0.8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: neg
                ? const Color(0xFFE57373).withOpacity(0.4)
                : const Color(0xFF81C784).withOpacity(0.4)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(label,
            style: const TextStyle(color: Colors.white, fontSize: 12)),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
              color:
              neg ? const Color(0xFFB71C1C) : const Color(0xFF2E7D32),
              borderRadius: BorderRadius.circular(6)),
          child: Text(pts,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold)),
        ),
      ]),
    ),
  );
}

class _SliderTab extends ConsumerWidget {
  final double value;
  final ValueChanged<double> onChanged;
  final Future<void> Function(Future<void> Function()) onSet;
  const _SliderTab(
      {required this.value, required this.onChanged, required this.onSet});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Set lake score directly',
            style: TextStyle(color: Colors.white70, fontSize: 13)),
        const SizedBox(height: 16),
        Center(
            child: Text('${value.round()}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.w700))),
        const SizedBox(height: 8),
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
              onChanged: onChanged),
        ),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          _mk('0', 'Stage 1'),
          _mk('30', ''),
          _mk('31', 'Stage 2'),
          _mk('70', ''),
          _mk('71', 'Stage 3'),
          _mk('100', ''),
        ]),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => onSet(
                    () => ref.read(lakeProvider.notifier).setScore(value.round())),
            child: Text('Apply Score → ${value.round()}',
                style:
                const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [0, 5, 31, 46, 71, 81, 100]
              .map((v) => GestureDetector(
            onTap: () {
              onChanged(v.toDouble());
              onSet(() => ref.read(lakeProvider.notifier).setScore(v));
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(8)),
              child: Text('$v',
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 12)),
            ),
          ))
              .toList(),
        ),
      ]),
    );
  }

  Widget _mk(String s, String l) => Column(children: [
    Text(s, style: const TextStyle(color: Colors.white38, fontSize: 9)),
    if (l.isNotEmpty)
      Text(l, style: const TextStyle(color: Colors.white24, fontSize: 8)),
  ]);
}
