// lib/main.dart
//
// App entry point.
//
// KEY THING HERE: ProviderScope
// ProviderScope is a widget that wraps the entire app.
// It is required by Riverpod — it creates the storage space
// where all providers (lakeProvider, pendingPointsProvider, etc.) live.
// Without it, the app will crash the moment any widget tries to
// use ref.watch() or ref.read().
//
// RULE: ProviderScope must be the outermost widget, wrapping everything else.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock the app to portrait mode (iOS wellness apps are always portrait)
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Make the status bar transparent so the lake fills the full screen
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  runApp(
    // ProviderScope MUST wrap the whole app — it is the Riverpod container
    const ProviderScope(
      child: BaselineApp(),
    ),
  );
}

class BaselineApp extends StatelessWidget {
  const BaselineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Baseline — Lake Demo',
      debugShowCheckedModeBanner: false,

      // Dark theme — the lake looks much better on a dark background
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF4CAF50),
          secondary: Color(0xFF26A69A),
          surface: Color(0xFF1C2833),
        ),
        useMaterial3: true,
        fontFamily: 'SF Pro Display', // iOS system font; falls back to default
      ),

      home: const HomeScreen(),
    );
  }
}
