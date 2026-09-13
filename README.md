# Scetch — Flutter Camera Tracing & Drawing App

**English** | [Русский](README.ru.md) | [Тоҷикӣ](README.tg.md)

Scetch is a local-first **camera tracing app for Android and iOS**, built with Flutter. Import a photo, prepare a sketch or outline, and overlay the reference image on a live camera preview to draw on paper. Adjust opacity, position, scale and rotation, then lock the reference and draw by hand.

No account, backend or analytics. Images stay on your device. Scetch uses a screen overlay; it does not provide AR world tracking. Phase 2 is outside the current scope.

**Project status:** Phase 1 source code is implemented, but production readiness has **not** been verified. Freezed/Drift code generation, golden baselines, Flutter analysis, tests and native builds still need to be completed. See [validation status](VALIDATION.md) for the recorded checks and limitations.

## Features

- Import photos with the system image picker and normalize EXIF orientation.
- Crop, rotate, mirror and reset images.
- Prepare Original, Grayscale, High Contrast, Outline or Sketch references.
- Adjust brightness, contrast, smoothing, details, edge strength and line width.
- Trace over a live camera preview with opacity, pan, pinch zoom, rotation and two-axis mirroring.
- Lock the reference; hold the button to unlock it.
- Use screen-bound or reference-bound grids and adjustable blink comparison.
- Control camera zoom, focus, exposure and flashlight where supported.
- Save drawing projects locally with Drift/SQLite and reopen them later.
- Choose a light, dark or system theme.

## Requirements

- **Flutter 3.47.4 stable / Dart 3.13.3**, selected from the official release manifest on September 13, 2026.
- **Android:** JDK 17, Android SDK and an API 24+ device. Flutter determines compile/target SDK versions.
- **iOS:** macOS, Flutter-compatible Xcode and CocoaPods. Deployment target: iOS 13.0. Windows cannot build iOS applications.
- A physical device to validate camera behavior, flashlight, permissions and performance.

References: [Flutter SDK archive](https://docs.flutter.dev/install/archive), [camera plugin](https://pub.dev/packages/camera), [image_picker](https://pub.dev/packages/image_picker), [Drift documentation](https://drift.simonbinder.eu/).

## Getting started

```sh
flutter --version
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

Freezed, JSON serialization and Drift require generated code. Run build_runner after changing models or database tables. Commit `pubspec.lock` after successfully resolving dependencies; verify dependency updates before shipping a release.

If Flutter tooling has not yet created the Gradle wrapper:

```sh
flutter create --empty --platforms=android,ios --org com.scetch --project-name scetch --no-pub .
```

Do not add `--overwrite`: the repository already contains native privacy and permission settings.

## Android setup

Install Android SDK and JDK, then run `flutter doctor -v` and `flutter doctor --android-licenses`. Flutter creates `android/local.properties`; this machine-specific file is not committed.

```sh
flutter build apk --debug
flutter run -d <device-id>
```

Configure release signing with your own keystore before distribution. The app requests camera access and opens the gallery through the system picker. The release manifest has no INTERNET permission; debug/profile manifests include it for Flutter tooling. App settings exclude cloud backup and device transfer.

## iOS setup

```sh
flutter pub get
cd ios
pod install
cd ..
flutter build ios --no-codesign
open ios/Runner.xcworkspace
```

Set your own bundle identifier and signing team in Xcode. Camera/photo-library usage descriptions, scene lifecycle configuration and `PERMISSION_CAMERA=1` are included. Audio recording is disabled, and microphone access is not requested.

AppDelegate excludes Application Support from iCloud backup. The app's privacy manifest declares no data collection. Review dependencies' required-reason API manifests in the built archive before publishing.

## How to trace a drawing

1. Select **New Drawing** or **Import From Gallery** to choose a reference image.
2. Set horizontal and vertical crop bounds, then rotate, mirror or reset.
3. Open **Image Preparation** and select Original, Grayscale, High Contrast, Outline or Sketch. Outline and Sketch produce lines on a transparent background; details, edge strength and line width controls are available in those modes.
4. Select **Start tracing**. Pan, pinch and rotate the reference. Double-tap the preview to set focus/exposure points if the camera supports them.
5. Adjust opacity, horizontal/vertical mirror, center, fit, reset, grid, blink, flashlight, camera zoom and exposure.
6. Select **Lock reference** to hide the main controls and prevent transform/grid changes. Hold the button to unlock. The system Back action also requires unlocking first.

Secure the phone on a stable stand above your paper. Look through the screen and draw by hand.

Transforms save after a 300 ms debounce, when the app enters the background, and on exit. Save failures show Retry; leaving the screen requires a successful save. Recent Projects and Projects restore drawings from SQLite.

## Architecture

The app uses a feature-first structure, immutable Freezed models, Riverpod 3, go_router, the official camera/image_picker plugins and Drift/SQLite.

| Directory | Responsibility |
|---|---|
| `lib/app` | Bootstrap, Riverpod composition root, routing and themes |
| `lib/core` | Camera, coordinates, image processing, files, Drift, permissions, failures, logging and cache limits |
| `lib/features` | Home, projects, image import, editor, tracing, settings and onboarding |
| `lib/shared/widgets` | Shared controls and error presentation |

Data/domain/presentation layers have concrete responsibilities. Static screens do not have empty repository or use-case layers.

- **Persistence:** a repository separates storage from UI. Drift stores a versioned schema and a JSON project snapshot; images are separate files. Paths are relative to Application Support so an iOS sandbox path change does not break projects.
- **Image processing:** `ImageProcessor` is the replaceable processing contract. Phase 1 uses the Dart `image` package in an isolate. OpenCV is not included or imported by UI; a native adapter can implement the same contract.
- **Memory:** decoding, EXIF normalization, cropping, filtering and encoding run in an isolate. The longest image side is reduced to 1600 px before filtering. Input limits are 40 MiB and 48 MP. Full source decoding still consumes memory and must be validated on the minimum target device.
- **Caching:** processed-image cache is capped at 96 MiB; Flutter's decoded-image cache at 64 MiB. Saved processed images are copied into the project directory. Old previews are removed after saving a new version.
- **Transforms:** `TraceTransform` provides one matrix for fit, scale, rotation, mirroring and normalized translation. The gesture anchor keeps the touched reference point beneath the user's fingers.
- **Coordinates:** `CameraCoordinateMapper` accounts for cover/contain, sensor/device rotation, front-camera mirroring and physical/logical pixels. CameraPreview and focus share crop geometry. This is a screen reference, not AR world tracking; keep the phone stationary.
- **Camera lifecycle:** `CameraSession` serializes native operations and disposal. A generation token prevents publishing an outdated controller after leaving the screen.
- **Blink:** AnimationController/FadeTransition changes render opacity without repeating layout or image decoding on every visibility change.
- **Privacy:** technical logging is limited to non-release builds. Images and user-provided names are not sent to external services.

## Testing and validation

```sh
dart format lib test integration_test
flutter analyze --fatal-infos
flutter test --coverage
flutter test integration_test -d <device-id>
flutter build apk --debug
# macOS only:
flutter build ios --no-codesign
```

PowerShell: `./tool/verify.ps1`. Unix/macOS: `bash tool/verify.sh` or `bash tool/verify.sh ios`.

Test sources cover transforms, focal anchors, coordinate mapping, opacity, lock state, JSON settings, image processing, content caching and SQLite restoration after closing the database. A camera lifecycle test simulates leaving during initialization. Widget tests cover controls and lock behavior; golden tests target light/dark Home and the reference grid. The integration test navigates onboarding, Home, Projects and Settings on a device. These Flutter tests have not yet been executed in the recorded environment.

Create and visually review golden baselines on a pinned Flutter/OS combination:

```sh
flutter test --tags golden --update-goldens
flutter test --tags golden
```

Do not automatically update baselines in CI. Before the first reviewed baseline exists, `--exclude-tags golden` can help diagnose other tests, but it does not constitute a full test pass.

`python tool/verify_structure.py` checks XML/plist/assets, Xcode references, relative Dart imports and Android release network/backup settings. It is a static check, not a native build.

**Recorded verification:** the source was formatted using a WASM port of dart_style, parsed without syntax errors, and checked for native structure consistency. Flutter analysis, code generation, tests and builds remain unverified because SDK installation failed in the available environment. Golden baseline PNGs and generated Freezed/Drift files are still missing. Full details: [VALIDATION.md](VALIDATION.md) (Russian).

## Device checks before release

- Allow, deny and permanently deny permission; return from system Settings.
- Open/close tracing quickly, background the app during permission requests and initialization, and repeat foreground/background transitions.
- Test portrait/landscape, rear cameras with 90°/270° sensor orientation, different aspect ratios and large text settings.
- Secure the phone; check focus near cropped preview edges and overlay behavior during rotation, pinch and mirroring.
- Restart after editing, locking, changing grids and opacity; compare the restored project.
- Test 12/48 MP JPEGs with EXIF, PNG/WebP, corrupt files, low disk space and an interrupted Android picker.
- Profile the minimum target device using Flutter DevTools: frame chart, p95 frame time, memory and 20 minutes of tracing/blink. **60 FPS is an acceptance target, not a measured result.**

## Troubleshooting

| Issue | Suggested action |
|---|---|
| `Target of URI hasn't been generated` | Run build_runner. |
| `Camera permission required` | Retry or open Settings. Parental restrictions must be changed outside the app. |
| `Camera unavailable` | Close other camera apps and use a physical device. |
| `Unsupported format` | Choose JPEG, PNG or WebP. The Dart processor does not directly support HEIC; export JPEG if the system picker did not convert it. |
| `Processing failed` | Try a smaller file and check available storage. |
| Tests fail to start on Windows | Check that Flutter's test engine and the native SQLite library were downloaded during SDK/package setup. |
| CocoaPods issues | Run on macOS after `flutter pub get` and open the `.xcworkspace`. |

Uninstalling the app removes local projects. Export and synchronization are outside Phase 1.
