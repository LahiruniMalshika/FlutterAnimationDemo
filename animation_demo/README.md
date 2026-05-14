# Baseline Animation Flutter Demo — Setup Guide

A complete animation demo for the Baseline iOS wellness app.
Uses mock backend responses to drive all lake ecosystem animations.

---

## What This Demo Does

- Shows the **27-image lake background** that crossfades as the score changes
- **Water shimmer** strips that loop continuously over the lake surface
- **6 animals** (fish, bird, rabbit, duck, otter, deer) that fade in/out using sprite sheet animation
- **Bonsai tree** that grows from nothing → small → large based on meditation points
- **+N / -N popup badge** that floats upward after every activity log
- **Score counter** that ticks up or down smoothly
- A **Demo Control Panel** (bottom sheet) to change the state at any time

---

## Packages Used — What Each One Does

### 1. `flutter_riverpod: ^2.4.9` — State Management

**What is it?**
Riverpod is the library that manages data flow in the app. When the lake score changes,
Riverpod automatically tells every widget that is watching the score to rebuild itself.

**Without Riverpod:**
You would manually pass the score from screen → widget → widget → widget.
If any widget in the middle changes, you have to update every file that touches the data.

**With Riverpod:**
Any widget in the app can directly read the lake state with one line:
```dart
final state = ref.watch(lakeProvider);
```
When the state changes (after logging an activity), every widget watching `lakeProvider`
automatically rebuilds — no manual passing of data.

**Key concepts:**
```
Provider       = a named slot that holds one piece of data
StateNotifier  = the class that changes the data inside a Provider
ref.watch()    = "give me this data AND rebuild me when it changes"
ref.read()     = "give me this data just once, no rebuild needed"
WidgetRef ref  = the object that gives you access to providers
```

**How widgets use it:**
```dart
// Step 1: Widget must extend ConsumerWidget (not StatelessWidget)
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {

    // Step 2: Watch the provider — rebuilds when score changes
    final state = ref.watch(lakeProvider);

    // Step 3: Use the data
    return Text('Score: ${state.lakeScore}');
  }
}
```

**How to trigger an action:**
```dart
// Call a method on the notifier using ref.read (not ref.watch)
ref.read(lakeProvider.notifier).logActivity(
  category: 'exercise',
  subType: 'cardio',
  durationMinutes: 45,
  isPositive: true,
);
```

---

### 2. Built-in Flutter Animation Classes (no extra package needed)

Flutter has powerful animation tools built in. Here are the ones used in this project:

#### `AnimationController`
The "timer" for animations. You set a duration and it counts from 0.0 to 1.0.
```dart
// Create it
_controller = AnimationController(
  duration: const Duration(milliseconds: 800),
  vsync: this,  // "this" = the State class, which is a TickerProvider
);

// Start it
_controller.forward();      // count 0.0 → 1.0 once
_controller.repeat();       // count 0.0 → 1.0 forever (for loops)
_controller.forward(from: 0.0); // restart from beginning
```

**What is `vsync: this`?**
vsync stands for "vertical sync". It links the animation to the screen refresh rate
(60 or 120 frames per second). Without it, the animation would run too fast or waste
battery by updating when the screen isn't even refreshing.
The State class must `with SingleTickerProviderStateMixin` to be a vsync source.

#### `CurvedAnimation`
Makes the animation speed up or slow down in a non-linear way (feels more natural).
```dart
_fadeAnim = CurvedAnimation(
  parent: _controller,
  curve: Curves.easeInOut,   // starts slow, speeds up, slows down again
);

// Other useful curves:
// Curves.linear         → constant speed
// Curves.easeOut        → starts fast, slows down
// Curves.elasticOut     → overshoots then settles (the "pop" feel)
// Curves.bounceOut      → bounces like a ball
```

#### `Tween`
Defines the START and END values of an animation.
```dart
// Fade from fully visible (1.0) to invisible (0.0)
_fadeAnim = Tween<double>(begin: 1.0, end: 0.0).animate(_controller);

// Count from old score to new score (whole numbers only)
_scoreAnim = IntTween(begin: 31, end: 46).animate(_controller);

// Move position from (0,0) to (0, -100 pixels)
_slideAnim = Tween<Offset>(begin: Offset.zero, end: Offset(0, -1.5))
    .animate(_controller);
```

#### `AnimatedBuilder`
Rebuilds a widget every time the animation ticks.
```dart
AnimatedBuilder(
  animation: _controller,
  builder: (context, child) {
    // This runs on every frame — use the animation value here
    return Opacity(
      opacity: _fadeAnim.value,  // reads current value of the animation
      child: child,
    );
  },
  child: const Text('Hello'), // built once, passed into builder
);
```

#### `AnimatedOpacity`
The simplest way to fade anything in or out. No AnimationController needed.
```dart
AnimatedOpacity(
  opacity: isVisible ? 1.0 : 0.0,   // just set the target opacity
  duration: const Duration(milliseconds: 1200),
  curve: Curves.easeInOut,
  child: const AnimalWidget(),
);
```
When `isVisible` changes from true → false, Flutter automatically fades it out.
When it changes from false → true, Flutter fades it in.

#### `AnimatedSwitcher`
Automatically animates between two different child widgets.
```dart
AnimatedSwitcher(
  duration: const Duration(milliseconds: 1500),
  child: Image.asset(
    bonsaiState == BonsaiState.large
        ? 'assets/bonsai/day/bonsai_large.png'
        : 'assets/bonsai/day/bonsai_small.png',
    key: ValueKey(bonsaiState),  // KEY IS REQUIRED — tells Flutter the child changed
  ),
);
```
**Important:** The `key` is critical. Without it, AnimatedSwitcher doesn't know
the child changed and won't play the animation.

#### `ClipRect` + `Align` (for sprite sheets)
This combo is how sprite sheet frame animation works.
```dart
ClipRect(               // the "window" — crops to show only one frame
  child: Align(
    alignment: Alignment(-1.0, 0.0),  // -1.0 = leftmost frame, +1.0 = rightmost
    widthFactor: 1.0 / frameCount,    // how much of the image to show
    child: Image.asset(
      'assets/animals/awake/day/fish1_awake_sheet.png',
      width: frameWidth * frameCount, // the FULL sprite sheet width
    ),
  ),
),
```
To advance to the next frame, change the Alignment value and call setState().

#### `Transform.translate`
Moves a widget by a pixel offset. Used for the water shimmer sliding effect.
```dart
Transform.translate(
  offset: Offset(100, 0),  // move 100px to the right
  child: const ShimmerStrip(),
);
```

---

## Project File Structure

```
baseline/
├── lib/
│   ├── main.dart                        ← App entry point
│   │
│   ├── models/
│   │   ├── ecosystem_state.dart         ← Data classes matching backend JSON
│   │   └── animal_config.dart           ← Animal frame counts & positions
│   │
│   ├── providers/
│   │   └── lake_provider.dart           ← Riverpod state management
│   │
│   ├── services/
│   │   └── mock_api_service.dart        ← Fake backend API responses
│   │
│   ├── screens/
│   │   └── home_screen.dart             ← Main lake screen
│   │
│   └── widgets/
│       ├── lake_scene.dart              ← Master scene composer (all layers)
│       ├── lake_background.dart         ← Background crossfade
│       ├── water_shimmer.dart           ← Looping shimmer strips
│       ├── animal_sprite.dart           ← Sprite sheet frame animator
│       ├── wildlife_layer.dart          ← Positions all 6 animals
│       ├── bonsai_widget.dart           ← Bonsai grow/shrink transition
│       ├── lake_score_display.dart      ← Animated score counter
│       ├── points_popup.dart            ← +N / -N floating badge
│       └── demo_control_panel.dart      ← Bottom sheet control panel
│
├── assets/
│   ├── backgrounds/
│   │   ├── day/     (9 PNG files)
│   │   ├── dusk/    (9 PNG files)
│   │   └── night/   (9 PNG files)
│   ├── animals/
│   │   ├── awake/day/      (fish1, otter)
│   │   ├── awake/dusk/     (bird)
│   │   ├── sleeping/day/   (all 6 animals)
│   │   └── sleeping/night/ (all 6 animals)
│   ├── shimmer/
│   │   ├── day/    (2 strip images)
│   │   ├── dusk/   (2 strip images)
│   │   └── night/  (2 strip images)
│   └── bonsai/
│       ├── day/    (small + large)
│       ├── dusk/   (small + large)
│       └── night/  (small + large)
│
├── pubspec.yaml
└── setup_assets.sh
```

---

## Step-by-Step Setup

### Step 1 — Create a new Flutter project

Open Terminal and run:
```bash
flutter create baseline
cd baseline
```
This creates a new Flutter project with a default counter app.

### Step 2 — Replace the generated files

Copy ALL the files from this package into your `baseline/` folder,
replacing any existing files.

Your project should now look like the structure above.

### Step 3 — Set up assets

Extract the zip file `Baseline app assets (1).zip` next to your project folder.

Then run:
```bash
# Make the script executable
chmod +x setup_assets.sh

# Run it (assumes the zip was extracted next to the project)
./setup_assets.sh
```

If the script fails because of a different extraction path, manually create the
`assets/` folders and copy the files following the structure shown above.

### Step 4 — Install packages

```bash
flutter pub get
```
This downloads flutter_riverpod and all other dependencies listed in pubspec.yaml.

### Step 5 — Run the app

```bash
# Run on a connected iPhone or iOS Simulator
flutter run

# Run on a specific device (list devices first)
flutter devices
flutter run -d "iPhone 15"
```

---

## How to Use the Demo Panel

When the app runs, you will see:
- The lake scene filling the full screen
- A **"Demo Panel"** button at the bottom

Tap **Demo Panel** to open the control panel. It has 3 tabs:

### Tab 1: Scenarios
12 pre-defined mock API responses covering every ecosystem state.
Tap the ▶ button on any scenario to instantly apply it.

Watch for:
- Background crossfades when water level changes
- Animals fading in or out
- Bonsai growing
- Score counter ticking

### Tab 2: Activities
Buttons for every activity type from the SRS.
Each button calls the mock API (which adds/subtracts points) and updates the scene.

Suggested sequence to see all animations:
1. Tap "Hygiene +1" several times → watch score climb
2. Tap "Exercise 45min +5" → score jumps, watch for crossfade at boundaries
3. Keep going until score hits 31 → watch Stage 2 unlock (animals appear!)
4. Tap "Meditate 10min +5" three times → bonsai grows to large (needs 15pts)
5. Keep going until score hits 71 → Stage 3 unlocks (duck, otter, deer appear!)
6. Tap "Midnight drain -5" → score drops, watch lake drain animation

### Tab 3: Slider
Drag the slider to set the score to any value from 0 to 100.
Quick preset buttons at the bottom: 0, 5, 31, 46, 71, 81, 100.
These jump directly to the boundary values where visual changes happen.

---

## Changing API Responses Over Time (Simulating Real Backend Behaviour)

To test how animations respond to changing data, you can change
`MockApiService._currentScore` directly or add a timer in your demo:

```dart
// In HomeScreen.initState(), add a timer that cycles through scenarios:
Timer.periodic(const Duration(seconds: 5), (timer) {
  final scenarios = MockResponses.scenarios;
  final nextIndex = (_currentScenarioIndex + 1) % scenarios.length;
  _currentScenarioIndex = nextIndex;
  ref.read(lakeProvider.notifier).loadScenario(scenarios[nextIndex]);
});
```

Or to test the midnight drain on a schedule:
```dart
// Fire a drain every 30 seconds for demo purposes
Timer.periodic(const Duration(seconds: 30), (_) {
  ref.read(lakeProvider.notifier).simulateDrain();
});
```

---

## Calibrating Animal Positions

The animal positions in `animal_config.dart` are estimates.
Once you see the app running with the real background images, you will need to
adjust the `scenePosition` values in `kAnimalConfigs`.

```dart
// In lib/models/animal_config.dart
'fish': AnimalConfig(
  scenePosition: Offset(0.38, 0.58),  // ← change these numbers
  //                    ↑              ↑
  //               left %         top %
  //            (0.0=left,     (0.0=top,
  //             1.0=right)     1.0=bottom)
  ...
),
```

To find the right coordinates:
1. Open the Stage 2 background image in any image viewer
2. Find where the fish should appear in the water
3. Measure its position as a percentage of the image width/height
4. Set those percentages as the Offset values (e.g., 35% from left = 0.35)

---

## Common Errors and Fixes

**Error: `Unable to load asset 'assets/backgrounds/day/stage1_water_low.png'`**
→ You haven't copied the asset files yet. Run `setup_assets.sh`

**Error: `Could not find the correct Provider`**
→ You forgot to wrap the app in `ProviderScope` in main.dart

**Error: `setState() called after dispose()`**
→ An AnimationController is being used after its widget was removed.
Make sure all controllers are disposed in `dispose()`.

**App runs but shows dark/black background**
→ Assets are missing. The background widget shows black on error.
Check that the PNG files are in the correct asset folders.

**Animals don't appear even though wildlife.fish == true**
→ The score might not be in stage 2 or 3 yet (needs score ≥ 31).
Use the Slider tab to set score to 50 and check again.

**Bonsai doesn't appear**
→ Meditation points must be > 0. Use the Activities tab to log
"Meditate 10min" and the bonsai_small should appear.

---

## Moving to the Real Backend

When you are ready to connect to the real Node.js server,
replace the mock service calls in `lake_provider.dart` with real HTTP calls.

The JSON shape stays EXACTLY the same — the real backend returns
the same `ecosystemState` structure that `MockApiService` returns.

Install the `http` package:
```yaml
# pubspec.yaml
dependencies:
  http: ^1.2.0
```

Then in `lake_provider.dart`, replace:
```dart
final response = await _api.getLakeState();
```

With a real HTTP call:
```dart
final response = await http.get(
  Uri.parse('https://your-server.com/v1/lake'),
  headers: {'Authorization': 'Bearer $accessToken'},
);
final json = jsonDecode(response.body) as Map<String, dynamic>;
final newState = EcosystemState.fromJson(json['ecosystemState']);
```

Everything else — the providers, widgets, animations — stays exactly the same.
Only the data source changes.