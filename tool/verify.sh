#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
flutter pub get
dart run build_runner build --delete-conflicting-outputs
dart format --output=none --set-exit-if-changed lib test integration_test
flutter analyze --fatal-infos
flutter test --coverage
if [[ "${1:-}" == "ios" ]]; then
  flutter build ios --no-codesign
else
  flutter build apk --debug
fi
