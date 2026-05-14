// lib/screens/home_screen.dart
//
// The main screen showing the lake ecosystem.
//
// WHAT THIS SCREEN DOES:
//   1. Shows the full-screen lake scene (LakeScene widget)
//   2. Provides a floating action button to open the demo control panel
//   3. Handles app lifecycle (resume = refresh state from backend)
//
// APP LIFECYCLE:
// When the user presses the home button and comes back to the app,
// didChangeAppLifecycleState fires with AppLifecycleState.resumed.
// We call refreshOnResume() which:
//   - Fetches the latest lake state from the server
//   - Applies any passive drain that happened overnight
//   - Updates the time-of-day environment if needed

import 'package:animation_demo/widjets/demo_control_panel.dart';
import 'package:animation_demo/widjets/lake_scene.dart';
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
    // Register this widget as an app lifecycle observer
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // ── Called when app comes back from background ────────────────
  @override
  void didChangeAppLifecycleState(AppLifecycleState appState) {
    if (appState == AppLifecycleState.resumed) {
      // Re-fetch state:
      //   - Applies passive drain for any nights missed
      //   - Updates time-of-day from device clock
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

      // ── Demo control panel button ─────────────────────────────
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openControlPanel,
        backgroundColor: const Color(0xFF1C2833).withOpacity(0.92),
        icon: const Icon(Icons.tune, color: Colors.white),
        label: const Text(
          'Demo Panel',
          style: TextStyle(color: Colors.white, fontSize: 13),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
