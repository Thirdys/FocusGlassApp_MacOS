# FocusGlass tester rules

## Общие правила

- Проверять именно `FocusGlass.app` из `FocusGlass-0.0.4.zip`, не raw `swift run`.
- Перед первым запуском проверить checksum.
- Если используешь существующие данные FocusGlass, сначала сделай backup `~/Library/Application Support/FocusGlass`.
- Для чистого прогона можно временно переименовать папку данных FocusGlass.
- Один отчётный пункт = одна проблема или одно UX-наблюдение.
- Severity: `blocker`, `high`, `medium`, `low`.
- К каждому пункту прикладывать screenshot.
- Если проблема связана со Strict Mode, указать правило, action, target app/site и permissions state.
- Если проблема связана с migration/data, указать чистый это профиль или старые данные.
- macOS warning из-за ad-hoc/not-notarized сборки не считается багом FocusGlass, но его можно отметить отдельной заметкой.

## Что считать blocker

- Приложение не запускается.
- Нельзя пройти первый экран/permission path.
- Таймер не стартует или падает.
- Данные проектов/задач теряются после relaunch.
- Settings или cockpit полностью ломают основной путь.
- Strict Mode делает приложение непригодным для тестирования.

## Что прислать

- Заполненный `tester-report-template.md`.
- Папку `screenshots/`.
- Для blocker/crash: screenshot/error text и шаги воспроизведения первыми пунктами.
