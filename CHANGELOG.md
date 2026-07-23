# История изменений

Формат основан на идее Keep a Changelog, но записи ведутся на русском. Версии тегируются как `vMAJOR.MINOR.PATCH`.

## [Unreleased]

- Пока нет новых изменений после подготовки tester-сборки `0.0.4`.

## [0.0.4] - 2026-06-27

### Добавлено

- Post-session outcome screen: planned vs honest time, distraction count,
  task/no-task summary, actions `Закрыть задачу`, `Продолжить`,
  `Следующая сессия`.
- Project-scoped notes: заметки проекта доступны в cockpit disclosure и в
  Project Editor.
- Backward-compatible migration: legacy `intention` переносится в notes
  активного проекта, если notes пустые.
- Tester checklist для первого полного прохода:
  `docs/process/tester-checklist.md`.
- Более строгий `tester-report-template.md`: severity, permissions/data state,
  screenshots и правила воспроизведения.
- Build/run workflow через `script/build_and_run.sh` с `--verify`, `--logs`,
  `--telemetry`, `--debug`.

### Изменено

- Cockpit rebuilt вокруг старой предпочтительной композиции: проект/notes
  слева, таймер в центре, active task и project tasks справа.
- Top-level `Текущее намерение` больше не показывается в cockpit, menu bar и
  fullscreen; пользовательский контекст теперь живёт в project notes.
- Task rows стали одной широкой карточкой с compact completion/edit controls.
- Active task показывается featured-карточкой с полным названием, status и
  progress.
- Theme Studio стал picker-first: ColorPicker вместо ручного ввода hex,
  один live preview, grouped advanced sections и glass sliders.
- Launch overlay получил theme-aware glass reveal, timer ring/ticks animation
  и Reduce Motion fallback.
- Docs/process обновлены под branch-based tester handoff с checklist/rules.

### Исправлено

- Theme Studio больше не требует ручного ввода hex вроде `#705cf6`.
- Дублирующий Theme Studio preview/explanation block удалён.
- Смена темы из protected user folders не пытается делать persistent icon write,
  чтобы не провоцировать лишний macOS file-access prompt.
- Checklist tasks не получают timed progress от завершённой сессии.
- Timed task progress сохраняется за задачей, выбранной на старте сессии.
- Fullscreen/menu не показывают устаревшее intention поле.

### Проверено

- `swift build`
- `swift test --disable-sandbox --scratch-path /tmp/FocusGlassApp_MacOS-swift-test`
  прошёл: 58/58.
- `FOCUSGLASS_DATA_DIR=/private/tmp/focusglass-cockpit-ui-pass-20260627/data ./script/build_and_run.sh --verify`
- `codesign --verify --deep --strict build/FocusGlass.app`

### Добавлено

- Правила ведения GitHub-проекта, веток, коммитов, тегов и релизов.
- GitHub-шаблоны для багов, фич и pull request.
- Публичный README с описанием продукта, сборки, структуры и текущего направления.
- Описания режимов таймера в настройках для Pomodoro, Countdown, Stopwatch, Flow, Timebox и Intervals.
- Скрипт подготовки release zip и SHA-256 checksum для ручного tester handoff или GitHub Releases.
- Настройка `Строгий режим во время перерывов`; по умолчанию strict-правила работают только во время focus-фазы.
- Типы задач `С временем` и `Обычная`: timed-задачи получают честное focus time после сессии, checklist-задачи закрываются вручную.
- Привязка завершённой сессии к выбранной задаче через `taskID` и `taskTitle`.
- Ручной ввод минут рядом со stepper в настройке задачи и сегментов таймера.
- Отдельные `PATCH_NOTES.md` и `docs/process/tester-report-template.md` для следующего tester handoff.
- Локальный QA override `FOCUSGLASS_DATA_DIR`, чтобы запускать packaged app с временным хранилищем и не трогать реальные пользовательские данные.

### Изменено

- Handoff используется как долговременная память проекта между сессиями.
- Главный cockpit больше не дублирует активный проект и задачи в правой контекстной панели.
- Скрипт упаковки поддерживает настраиваемые scratch/app пути через переменные окружения.
- Скрипт упаковки хранит Clang module cache внутри package work dir, чтобы packaging проходил в ограниченных средах без записи в `~/.cache`.
- `build/` закреплён как локальный generated output; тестовые `.app` сборки передаются вручную или через GitHub Release assets, а не через git.
- GitHub Release описан как ручная страница раздачи уже собранного zip/checksum, а не как обязательная автоматизация сборки.
- Theme Studio показывает живой preview advanced color tokens: градиент окна, surface/elevated chips, основной и тихий текст.
- Stepper времени snap-ится к сетке по 5 минут: `1 -> 5 -> 10`, `6 -> 10`, `5 -> 1`, а для диапазона с нулём `0 -> 5`.
- Ручное поле минут в редакторе сегментов вынесено в отдельную строку рядом со stepper, чтобы точный ввод был доступен даже в плотной Settings-раскладке.
- Fullscreen top controls получили кнопку пропуска сегмента, согласованную с основным экраном.

### Исправлено

- Быстрая задача без активного проекта больше не теряется: она создаётся в списке `Без проекта`.
- Список активных задач больше не обрезается до трёх незавершённых задач.
- Edit-кнопки проекта и задач получили увеличенную область нажатия вокруг карандаша.
- Strict action `pauseSession` теперь действительно переводит running timer в paused и запускает Shortcut `FocusGlass Pause`.
- Пользовательские темы удаляются отдельной кнопкой `Удалить тему`; `Сбросить` больше не удаляет custom theme.

## [0.0.1] - 2026-05-29

### Добавлено

- Базовая исходная версия FocusGlass.
- SwiftUI macOS приложение с main cockpit, menu bar panel, fullscreen focus и Settings.
- Локальное JSON-хранилище workspace/settings.
- Ядро таймера, аналитики и strict-rule типов.
- RU/EN локализация.
- Theme Studio и runtime/static app icon generation.
- Тесты ядра, persistence, strict-rule matching и theme side effects.

### Проверено

- Xcode build прошёл.
- SwiftPM tests прошли: 37/37.
