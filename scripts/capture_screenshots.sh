#!/bin/bash
# Captures the 6 App Store screenshots for both required iPad size classes
# and both required iPhone size classes, using ScreenshotDemo (see
# LetterQuest/App/ScreenshotDemo.swift) to seed realistic progress data and
# jump straight to each target screen.
#
# Usage: scripts/capture_screenshots.sh
# Requires: the LetterQuest.app build product already exists (run a normal
# `xcodebuild ... build` first) and the simulators below are available.

set -euo pipefail

BUNDLE_ID="com.letterquest.app"
APP_PATH="$(find "$HOME/Library/Developer/Xcode/DerivedData" -maxdepth 5 -path "*/Debug-iphonesimulator/LetterQuest.app" -print -quit)"

if [ -z "$APP_PATH" ]; then
    echo "error: could not find built LetterQuest.app — run a build first" >&2
    exit 1
fi

IPAD_13="302F8945-5C36-4DB9-8313-2F3E0B68AEC4"        # iPad Pro 13-inch (M5), iOS 26.5
IPAD_11="B73B1A17-1E19-493E-9FED-AA58471780C1"        # iPad Pro 11-inch (M5), iOS 26.5
IPHONE_69="9CC2C3F2-0908-4814-B50E-77C97E5383F2"      # iPhone 17 Pro Max (6.9"), iOS 26.5
IPHONE_63="F553BEC0-0365-4874-B329-D8D38E0245F8"      # iPhone 17 (6.3"), iOS 26.5

OUT_DIR="$(cd "$(dirname "$0")/.." && pwd)/AppStore/Screenshots"

# name:profile:route
SHOTS=(
    "01-home:partial:home"
    "02-practice:partial:practice"
    "03-score:partial:score"
    "04-celebration:partial:celebration"
    "05-progress:partial:progress"
    "06-words:complete:words"
)

capture_for_device() {
    local device_id="$1"
    local out_subdir="$2"

    mkdir -p "$OUT_DIR/$out_subdir"

    echo "== Booting $device_id =="
    xcrun simctl bootstatus "$device_id" -b >/dev/null 2>&1 || xcrun simctl boot "$device_id" 2>/dev/null || true
    xcrun simctl bootstatus "$device_id" -b

    echo "== Installing app on $device_id =="
    xcrun simctl install "$device_id" "$APP_PATH"

    for shot in "${SHOTS[@]}"; do
        IFS=":" read -r name profile route <<< "$shot"
        echo "== Capturing $out_subdir/$name.png (profile=$profile route=$route) =="

        xcrun simctl terminate "$device_id" "$BUNDLE_ID" >/dev/null 2>&1 || true
        # Fresh UserDefaults each shot so profiles don't bleed into each other.
        xcrun simctl uninstall "$device_id" "$BUNDLE_ID" >/dev/null 2>&1 || true
        xcrun simctl install "$device_id" "$APP_PATH"

        SIMCTL_CHILD_LQ_SCREENSHOT_DEMO=1 \
        SIMCTL_CHILD_LQ_SCREENSHOT_PROFILE="$profile" \
        SIMCTL_CHILD_LQ_SCREENSHOT_ROUTE="$route" \
        xcrun simctl launch --terminate-running-process "$device_id" "$BUNDLE_ID" >/dev/null

        # Seeding + navigation + (for the score shot) the extra 0.4s panel
        # delay all need to settle before the screenshot is taken.
        sleep 4

        xcrun simctl io "$device_id" screenshot "$OUT_DIR/$out_subdir/$name.png"
    done

    xcrun simctl terminate "$device_id" "$BUNDLE_ID" >/dev/null 2>&1 || true
}

capture_for_device "$IPAD_13" "iPad-13"
capture_for_device "$IPAD_11" "iPad-11"
capture_for_device "$IPHONE_69" "iPhone-6.9"
capture_for_device "$IPHONE_63" "iPhone-6.3"

echo "Done. Screenshots written to $OUT_DIR"
