#!/usr/bin/env bash
# Run the app on an arm64 iOS simulator (ML Kit has no simulator build, so it is stubbed).
# Usage: tools/run_sim.sh [flutter run args]   e.g. tools/run_sim.sh -d <simulator-udid>
# All temporary changes are reverted on exit, so normal device/release builds are unaffected.
set -euo pipefail
cd "$(dirname "$0")/.."

BACKUP="$(mktemp -d)"
FILES=(ios/Flutter/Debug.xcconfig ios/Podfile.lock pubspec.lock)
for f in "${FILES[@]}"; do cp "$f" "$BACKUP/$(echo "$f" | tr / _)"; done

cleanup() {
  rm -f pubspec_overrides.yaml
  for f in "${FILES[@]}"; do cp "$BACKUP/$(echo "$f" | tr / _)" "$f"; done
  rm -rf "$BACKUP"
  flutter pub get >/dev/null 2>&1 || true
  echo "Restored real ML Kit setup."
}
trap cleanup EXIT

cat > pubspec_overrides.yaml <<'YAML'
dependency_overrides:
  google_mlkit_commons:
    path: tools/mlkit_sim_stubs/google_mlkit_commons
  google_mlkit_face_detection:
    path: tools/mlkit_sim_stubs/google_mlkit_face_detection
  google_mlkit_text_recognition:
    path: tools/mlkit_sim_stubs/google_mlkit_text_recognition
YAML
printf '#include "SimulatorArch.xcconfig"\n' >> ios/Flutter/Debug.xcconfig
flutter pub get

if [ $# -eq 0 ]; then
  set -- -d "$(xcrun simctl list devices booted | grep -Eo '[0-9A-F-]{36}' | head -1)"
fi
flutter run "$@"
