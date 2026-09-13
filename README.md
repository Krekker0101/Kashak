# Scetch

Локальная студия для срисовывания: импорт фотографии, подготовка изображения и управляемый референс поверх камеры. Без регистрации, backend и аналитики. Phase 2 не входит в проект.

## Требования

- Flutter **3.47.4 stable**, Dart **3.13.3** — версия из официального манифеста на 13 сентября 2026 года.
- Android: JDK 17, Android SDK, устройство API 24+; compile/target SDK определяются Flutter.
- iOS: macOS, совместимый с Flutter Xcode, CocoaPods; deployment target 13.0. Windows не собирает iOS.
- Реальное устройство для проверки камеры, фонарика, разрешений и производительности.

Источники: [Flutter SDK archive](https://docs.flutter.dev/install/archive), [camera](https://pub.dev/packages/camera), [image_picker](https://pub.dev/packages/image_picker), [Drift](https://drift.simonbinder.eu/).

## Запуск

```sh
flutter --version
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

Freezed, JSON и Drift используют генерацию кода. Запускайте build_runner после изменения моделей или таблиц. `pubspec.lock` фиксируется после успешного разрешения зависимостей; не используйте непроверенное обновление пакетов в релизе.

Если Gradle wrapper ещё не создан инструментами Flutter:

```sh
flutter create --empty --platforms=android,ios --org com.scetch --project-name scetch --no-pub .
```

Не используйте `--overwrite`: нативные настройки приватности и разрешений уже находятся в репозитории.

## Android

Установите Android SDK и JDK, выполните `flutter doctor -v` и `flutter doctor --android-licenses`. `android/local.properties` создаётся Flutter и не хранится в репозитории. Для проверки:

```sh
flutter build apk --debug
flutter run -d <device-id>
```

Release signing нужно настроить собственным keystore перед распространением. Приложение запрашивает только камеру; галерея открывается через системный picker. В release-манифесте отсутствует INTERNET. Разрешение INTERNET в debug/profile нужно для Flutter tooling. Cloud backup и device transfer исключены настройками приложения.

## iOS

```sh
flutter pub get
cd ios
pod install
cd ..
flutter build ios --no-codesign
open ios/Runner.xcworkspace
```

Выберите собственный bundle identifier и signing team в Xcode. Включены usage descriptions камеры и библиотеки фотографий, scene lifecycle и `PERMISSION_CAMERA=1`. Аудиозапись выключена, доступ к микрофону не запрашивается. AppDelegate исключает Application Support из iCloud backup. Privacy manifest не заявляет сбор данных; required-reason API manifests зависимостей проверяются в собранном архиве перед публикацией.

## Использование

1. New Drawing / Import From Gallery — системный выбор изображения.
2. Crop: горизонтальные и вертикальные границы; затем rotate/mirror/reset.
3. Image Preparation: Original, Grayscale, High Contrast, Outline, Sketch. Последние два режима дают линии на прозрачном фоне. Настройки details, edge strength и line width доступны для этих режимов.
4. Start tracing — pan, pinch и rotation. Double tap по preview ставит focus/exposure point, если камера поддерживает их.
5. Кнопки управления: прозрачность, обе оси отражения, center, fit, reset, grid, blink, flashlight, zoom и exposure.
6. Lock reference скрывает инструменты и блокирует transform/grid. Для разблокировки удерживайте кнопку. Системная кнопка «Назад» в locked mode также требует разблокировки.

Трансформации сохраняются с debounce 300 мс, при уходе в фон и при выходе. При ошибке сохранения показан Retry; выход со страницы не теряет несохранённые изменения молча. Recent Projects и Projects восстанавливают работу из SQLite.

## Архитектура

`lib/app` — bootstrap, Riverpod composition root, router и темы.

`lib/core` — камера, координаты, CV, файлы, Drift, permissions, failures, logging и лимиты кэша.

`lib/features` — home, projects, import_image, image_editor, tracing, settings, onboarding. Слои data/domain/presentation выделены там, где есть соответствующая ответственность. Пустые repository/use-case слои для статических экранов намеренно не создаются.

`lib/shared/widgets` — общие элементы управления и ошибки.

- Доменные Freezed-модели immutable. Repository отделяет хранение проектов от UI.
- Drift хранит versioned schema и JSON-снимок проекта; изображения лежат отдельными файлами. Пути относительны к Application Support, поэтому смена абсолютного пути iOS sandbox не ломает проекты.
- `ImageProcessor` — точка замены реализации. Phase 1 использует пакет `image` в Dart isolate. OpenCV не подключён и не импортируется в UI; нативный adapter может реализовать тот же контракт.
- Декодирование, EXIF normalization, crop, фильтры и кодирование происходят в isolate. До фильтров длинная сторона уменьшается до 1600 px. Вход ограничен 40 MiB и 48 MP; полное декодирование исходника всё ещё требует памяти, что проверяется на минимальном целевом устройстве.
- Кэш обработанных изображений ограничен 96 MiB; decoded Flutter cache — 64 MiB. Сохранённые processed images копируются из временного кэша в проект. Старые preview очищаются после сохранения новой версии.
- `TraceTransform` содержит единую матрицу: fit → scale/rotation/mirror → normalized translation. Gesture anchor удерживает выбранную точку референса под пальцами.
- `CameraCoordinateMapper` учитывает cover/contain, sensor/device rotation, front mirror и physical/logical pixels. CameraPreview и focus используют одинаковую геометрию crop. Это экранный overlay, не AR world tracking: телефон должен стоять неподвижно.
- `CameraSession` сериализует native operations и dispose. Generation token запрещает публикацию устаревшего контроллера после ухода с экрана.
- Blink управляет render opacity через AnimationController/FadeTransition. Layout и декодирование изображения не запускаются на каждую смену видимости.
- Логи с техническими деталями доступны только вне release. Изображения и пользовательские имена не отправляются наружу.

## Проверки

```sh
dart format lib test integration_test
flutter analyze --fatal-infos
flutter test --coverage
flutter test integration_test -d <device-id>
flutter build apk --debug
# Только macOS:
flutter build ios --no-codesign
```

PowerShell: `./tool/verify.ps1`. Unix/macOS: `bash tool/verify.sh` или `bash tool/verify.sh ios`.

Unit tests покрывают transform, focal anchor, координаты, opacity, lock, JSON settings, обработку изображений, content cache и восстановление SQLite после закрытия. Camera lifecycle test моделирует уход с экрана во время initialize. Widget tests проверяют slider и golden сетки. Integration test проходит onboarding, home, projects и settings на устройстве.

Golden baseline создаётся и визуально проверяется на закреплённом Flutter/OS:

```sh
flutter test --tags golden --update-goldens
flutter test --tags golden
```

Не обновляйте baseline автоматически в CI. До первого подтверждённого baseline остальные тесты можно диагностически запускать с `--exclude-tags golden`; это не эквивалент полной проверке.

`python tool/verify_structure.py` проверяет XML/plist/assets, ссылки Xcode, относительные Dart imports и Android release network/backup policy. Это отдельная статическая проверка, не замена сборке.

Актуальный статус выполненных проверок и оставшихся ограничений: [VALIDATION.md](VALIDATION.md).

## Проверка на устройствах перед релизом

- Разрешить / отклонить / отклонить навсегда; вернуться из Settings.
- Быстро открыть/закрыть tracing, свернуть при запросе разрешения и во время initialization, повторить foreground/background.
- Portrait/landscape, задняя камера с sensor 90/270, различные aspect ratio, экран с большим размером текста.
- Закрепить телефон, проверить фокус по краям cover preview и устойчивость overlay при rotation/pinch/mirror.
- Перезапустить приложение после редактирования, lock, grid и opacity; сравнить восстановленный проект.
- 12/48 MP JPEG с EXIF, PNG/WebP, повреждённый файл, недостаток места, interrupted Android picker.
- Profile на минимальном устройстве: Flutter DevTools frame chart, p95 frame time, memory, 20 минут tracing/blink. 60 FPS — критерий приёмки, а не заявленное измерение.

## Troubleshooting

- `Target of URI hasn't been generated`: выполните build_runner.
- `Camera permission required`: Retry или Open Settings; ограничения родительского контроля снимаются вне приложения.
- `Camera unavailable`: закройте другое приложение камеры; используйте физическое устройство.
- `Unsupported format`: выберите JPEG, PNG или WebP. HEIC не поддерживается Dart processor напрямую; если системный picker не преобразовал файл, экспортируйте JPEG.
- `Processing failed`: попробуйте меньший файл, проверьте свободное место.
- Пустые/неработающие тесты на Windows: проверьте загрузку Flutter test engine и нативной SQLite library через `flutter pub get`.
- Проблемы CocoaPods: запускайте из macOS после `flutter pub get`, открывайте `.xcworkspace`.

Удаление приложения удаляет локальные проекты. Экспорт/синхронизация не входят в Phase 1.
