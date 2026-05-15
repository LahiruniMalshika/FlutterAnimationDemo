// lib/screens/home_screen.dart
import 'package:baseline/widjets/demo_control_panel.dart';
import 'package:baseline/screens/lake_scene.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/lake_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState appState) {
    if (appState == AppLifecycleState.resumed) {
      ref.read(lakeProvider.notifier).refreshOnResume();
    }
  }

  void _openControlPanel() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const DemoControlPanel(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: const LakeScene(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openControlPanel,
        backgroundColor: const Color(0xFF1C2833).withOpacity(0.92),
        icon: const Icon(Icons.tune, color: Colors.white),
        label: const Text('Demo Panel',
            style: TextStyle(color: Colors.white, fontSize: 13)),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
