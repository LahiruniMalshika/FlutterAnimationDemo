#!/bin/bash
# setup_assets.sh
#
# Run this script from the ROOT of your Flutter project folder.
# It creates all asset directories and copies the files from your
# extracted zip folder into the correct locations.
#
# USAGE:
#   1. Extract the zip: "Baseline app assets (1).zip"
#   2. Note where it was extracted — set ASSETS_SOURCE below
#   3. Run this script from your Flutter project root:
#      chmod +x setup_assets.sh
#      ./setup_assets.sh
#
# ─────────────────────────────────────────────────────────────

# WHERE YOUR EXTRACTED ASSETS ARE
# Change this path to wherever you extracted the zip
ASSETS_SOURCE="./app_assets"

echo "🌊 Baseline — Setting up asset folders..."

# ─── Create all asset directories ────────────────────────────
mkdir -p assets/backgrounds/day
mkdir -p assets/backgrounds/dusk
mkdir -p assets/backgrounds/night

mkdir -p assets/animals/awake/day
mkdir -p assets/animals/awake/dusk
mkdir -p assets/animals/sleeping/day
mkdir -p assets/animals/sleeping/night

mkdir -p assets/shimmer/day
mkdir -p assets/shimmer/dusk
mkdir -p assets/shimmer/night

mkdir -p assets/bonsai/day
mkdir -p assets/bonsai/dusk
mkdir -p assets/bonsai/night

echo "✅ Directories created"

echo "Copying background images..."

cp "$ASSETS_SOURCE/Background New/Day/stage1_water_low.png"  assets/backgrounds/day/
cp "$ASSETS_SOURCE/Background New/Day/stage1_water_mid.png"  assets/backgrounds/day/
cp "$ASSETS_SOURCE/Background New/Day/stage1_water_high.png" assets/backgrounds/day/
cp "$ASSETS_SOURCE/Background New/Day/stage2_water_low.png"  assets/backgrounds/day/
cp "$ASSETS_SOURCE/Background New/Day/stage2_water_mid.png"  assets/backgrounds/day/
cp "$ASSETS_SOURCE/Background New/Day/stage2_water_high.png" assets/backgrounds/day/
cp "$ASSETS_SOURCE/Background New/Day/stage3_water_low.png"  assets/backgrounds/day/
cp "$ASSETS_SOURCE/Background New/Day/stage3_water_mid.png"  assets/backgrounds/day/
cp "$ASSETS_SOURCE/Background New/Day/stage3_water_high.png" assets/backgrounds/day/

cp "$ASSETS_SOURCE/Background New/Dusk/stage1_water_low.png"  assets/backgrounds/dusk/
cp "$ASSETS_SOURCE/Background New/Dusk/stage1_water_mid.png"  assets/backgrounds/dusk/
cp "$ASSETS_SOURCE/Background New/Dusk/stage1_water_high.png" assets/backgrounds/dusk/
cp "$ASSETS_SOURCE/Background New/Dusk/stage2_water_low.png"  assets/backgrounds/dusk/
cp "$ASSETS_SOURCE/Background New/Dusk/stage2_water_mid.png"  assets/backgrounds/dusk/
cp "$ASSETS_SOURCE/Background New/Dusk/stage2_water_high.png" assets/backgrounds/dusk/
cp "$ASSETS_SOURCE/Background New/Dusk/stage3_water_low.png"  assets/backgrounds/dusk/
cp "$ASSETS_SOURCE/Background New/Dusk/stage3_water_mid.png"  assets/backgrounds/dusk/
cp "$ASSETS_SOURCE/Background New/Dusk/stage3_water_high.png" assets/backgrounds/dusk/

cp "$ASSETS_SOURCE/Background New/Night/stage1_water_low.png"  assets/backgrounds/night/
cp "$ASSETS_SOURCE/Background New/Night/stage1_water_mid.png"  assets/backgrounds/night/
cp "$ASSETS_SOURCE/Background New/Night/stage1_water_high.png" assets/backgrounds/night/
cp "$ASSETS_SOURCE/Background New/Night/stage2_water_low.png"  assets/backgrounds/night/
cp "$ASSETS_SOURCE/Background New/Night/stage2_water_mid.png"  assets/backgrounds/night/
cp "$ASSETS_SOURCE/Background New/Night/stage2_water_high.png" assets/backgrounds/night/
cp "$ASSETS_SOURCE/Background New/Night/stage3_water_low.png"  assets/backgrounds/night/
cp "$ASSETS_SOURCE/Background New/Night/stage3_water_mid.png"  assets/backgrounds/night/
cp "$ASSETS_SOURCE/Background New/Night/stage3_water_high.png" assets/backgrounds/night/

echo "Copying animal awake sheets..."

cp "$ASSETS_SOURCE/Animals New/Awake/Day/fish1_awake_sheet.png" assets/animals/awake/day/
cp "$ASSETS_SOURCE/Animals New/Awake/Day/otter_awake_sheet.png" assets/animals/awake/day/

cp "$ASSETS_SOURCE/Animals New/Awake/Dusk/bird_awake_sheet_dusk.png" assets/animals/awake/dusk/

echo "Copying animal sleeping sheets..."

cp "$ASSETS_SOURCE/Animals New/Sleeping/Day/bird_sleeping_sheet.png"   assets/animals/sleeping/day/
cp "$ASSETS_SOURCE/Animals New/Sleeping/Day/deer_sleeping_sheet.png"   assets/animals/sleeping/day/
cp "$ASSETS_SOURCE/Animals New/Sleeping/Day/duck_sleeping_sheet.png"   assets/animals/sleeping/day/
cp "$ASSETS_SOURCE/Animals New/Sleeping/Day/fish2_sleeping_sheet.png"  assets/animals/sleeping/day/
cp "$ASSETS_SOURCE/Animals New/Sleeping/Day/fish3_sleeping_sheet.png"  assets/animals/sleeping/day/
cp "$ASSETS_SOURCE/Animals New/Sleeping/Day/otter_sleeping_sheet.png"  assets/animals/sleeping/day/
cp "$ASSETS_SOURCE/Animals New/Sleeping/Day/rabbit_sleeping_sheet.png" assets/animals/sleeping/day/

cp "$ASSETS_SOURCE/Animals New/Sleeping/Night/bird_sleeping_sheet_night.png"   assets/animals/sleeping/night/
cp "$ASSETS_SOURCE/Animals New/Sleeping/Night/deer_sleeping_sheet_night.png"   assets/animals/sleeping/night/
cp "$ASSETS_SOURCE/Animals New/Sleeping/Night/duck_sleeping_sheet_night.png"   assets/animals/sleeping/night/
cp "$ASSETS_SOURCE/Animals New/Sleeping/Night/fish1_sleeping_sheet_night.png"  assets/animals/sleeping/night/
cp "$ASSETS_SOURCE/Animals New/Sleeping/Night/fish2_sleeping_sheet_night.png"  assets/animals/sleeping/night/
cp "$ASSETS_SOURCE/Animals New/Sleeping/Night/fish3_sleeping_sheet_night.png"  assets/animals/sleeping/night/
cp "$ASSETS_SOURCE/Animals New/Sleeping/Night/otter_sleeping_sheet_night.png"  assets/animals/sleeping/night/
cp "$ASSETS_SOURCE/Animals New/Sleeping/Night/rabbit_sleeping_sheet_night.png" assets/animals/sleeping/night/

echo "Copying shimmer strips..."

cp "$ASSETS_SOURCE/Water shimmer strip/Day/water_shimmer_strip_1.png"      assets/shimmer/day/
cp "$ASSETS_SOURCE/Water shimmer strip/Day/water_shimmer_strip_2.png"      assets/shimmer/day/
cp "$ASSETS_SOURCE/Water shimmer strip/Dusk/water_shimmer_strip_1_dusk.png" assets/shimmer/dusk/
cp "$ASSETS_SOURCE/Water shimmer strip/Dusk/water_shimmer_strip_2_dusk.png" assets/shimmer/dusk/
cp "$ASSETS_SOURCE/Water shimmer strip/Night/water_shimmer_strip_1_night.png" assets/shimmer/night/
cp "$ASSETS_SOURCE/Water shimmer strip/Night/water_shimmer_strip_2_night.png" assets/shimmer/night/

echo "Copying bonsai images..."

cp "$ASSETS_SOURCE/Bonsai/Day/bonsai_small.png"        assets/bonsai/day/
cp "$ASSETS_SOURCE/Bonsai/Day/bonsai_large.png"        assets/bonsai/day/
cp "$ASSETS_SOURCE/Bonsai/Dusk/bonsai_small_dusk.png"  assets/bonsai/dusk/
cp "$ASSETS_SOURCE/Bonsai/Dusk/bonsai_large_dusk.png"  assets/bonsai/dusk/
cp "$ASSETS_SOURCE/Bonsai/Night/bonsai_small_night.png" assets/bonsai/night/
cp "$ASSETS_SOURCE/Bonsai/Night/bonsai_large_night.png" assets/bonsai/night/

echo ""
echo "All assets copied successfully!"
echo ""