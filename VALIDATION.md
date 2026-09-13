# Phase 1 — статус проверки

Дата: 13 сентября 2026. Среда: Windows, PowerShell. Исходно рабочая папка была пустой.

**Реализация создана, но Phase 1 пока нельзя считать проверенной production-ready сборкой.** Flutter/Dart SDK не установлен. Сетевые попытки установить SDK не завершились: GitHub clone/archive, полный stable-архив и выборочная загрузка завершались EOF, ECONNRESET, timeout и DNS errors. Приложение на устройстве не запускалось. Phase 2 не начата.

## Выполнено

| Проверка | Фактический результат |
|---|---|
| `node tool/format_dart.mjs` | Успешно: 51 Dart-файл отформатирован через `@wasm-fmt/dart_fmt 0.4.0`, WASM-порт dart_style. Архив formatter проверен по опубликованной SHA-1. Повторный запуск не меняет файлы. |
| `python tool/parse_dart.py` | Успешно: 51 Dart-файл разобран tree-sitter без синтаксических ошибок. Это не проверка типов. |
| `python tool/check_dart_delimiters.py` | Успешно: парные разделители в 51 Dart-файле. |
| `python tool/verify_structure.py` | Успешно: 16 XML/plist/assets-файлов, связи Xcode, относительные Dart imports, отсутствие INTERNET в Android release и запрет backup. |
| `python tool/generate_icons.py` | Успешно: 18 iOS icon entries; Android использует vector drawable. |

## Не выполнено / заблокировано

| Команда / критерий | Причина |
|---|---|
| `dart format lib test integration_test` | Команда `dart` не найдена. Выполнен отдельный WASM formatter; штатную команду нужно повторить на закреплённом SDK. |
| `flutter pub get` и build_runner | Нет Flutter/Dart. `pubspec.lock`, `.freezed.dart` и `.g.dart` пока не сгенерированы. |
| `flutter analyze --fatal-infos` | Команда `flutter` не найдена. Нельзя утверждать отсутствие analyzer warnings или type errors. |
| `flutter test --coverage` | Команда `flutter` не найдена. Unit/widget tests написаны, но не исполнялись. |
| Golden tests | Написаны для light/dark Home и reference grid; baseline PNG ещё не сгенерированы и не проверены визуально. Без baseline полный `flutter test` не пройдёт. |
| `flutter test integration_test -d …` | Нет SDK и подключённого устройства. |
| `flutter build apk --debug` | Команда `flutter` не найдена; Android SDK/JDK в PATH также не обнаружены. Gradle wrapper должен быть подготовлен Flutter tooling. APK не создан. |
| `flutter build ios --no-codesign` | Нет Flutter; Windows не поддерживает сборку iOS. Xcode project проверен только структурно, не через xcodebuild. |
| 60 FPS, память, аппаратная камера | Требуют profile-запуска на физических Android/iOS устройствах. Измерений нет. |

## Самопроверка кода

- Убраны операции CV из UI thread; обработка сериализуется редактором, устаревшие результаты не заменяют новый preview.
- Добавлены EXIF normalization, ограничения размера, bounded cache и постоянные копии processed images вне временного кэша.
- Исправлено восстановление Android picker на неподдерживаемых платформах; неудачный импорт очищает созданные файлы.
- Убрана зависимость сохранённых файлов и transforms от абсолютного sandbox path и screen pixels.
- Все native camera operations и dispose сериализованы; generation token проверяется перед публикацией контроллера.
- После permission prompt проверяется lifecycle, чтобы не открыть камеру в фоне.
- Ошибка отдельного camera control больше не отключает preview; пользователь получает сообщение.
- Lock запрещает transform и grid changes, скрывает инструменты, требует long press для unlock.
- Запись состояния упорядочена; ошибки сохранения видимы, выход требует успешного flush.
- Исправлены обращения к WidgetRef после потенциального закрытия редактора/диалога.
- Добавлены braces для flow-control blocks; исходники повторно разобраны и отформатированы.
- Android release не имеет INTERNET; cloud backup/device transfer отключены. iOS Application Support исключается из backup.

## Чтобы закрыть Phase 1

1. Установить Flutter 3.47.4 / Dart 3.13.3, JDK и Android SDK; выполнить `flutter doctor -v`.
2. Подготовить недостающие generated native files командой из README, выполнить pub get и build_runner.
3. Запустить стандартное форматирование и analyzer, исправить любые обнаруженные ошибки типов/API.
4. Создать и визуально проверить golden baseline, выполнить unit/widget tests, затем integration tests на устройстве.
5. Собрать Android APK и iOS без codesign на macOS, пройти аппаратную матрицу из README.
6. Измерить profile performance; только после этого отмечать Phase 1 стабильной.

Вспомогательные parser/formatter установлены только в игнорируемой `.tooling/`. Для повторного parser-check без Flutter: `python -m pip install --target .tooling/python tree-sitter==0.26.0 tree-sitter-dart==0.1.0`. Основной путь проверки — штатные Flutter/Dart команды из README.
