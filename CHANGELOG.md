# История изменений

Формат основан на идее Keep a Changelog, но записи ведутся на русском. Версии тегируются как `vMAJOR.MINOR.PATCH`.

## [Unreleased]

Эти изменения находятся в текущей ветке разработки и не входят в историческую
tester-сборку `0.0.4`.

### Добавлено

- Persistent Strict Mode history с целью, временем, фактическим действием,
  сессией, проектом, задачей и режимом таймера.
- Analytics первого прохода: planned vs actual, последние сессии,
  эффективность режимов, сводки проектов и отвлечения по проектам/режимам.
- Task-level analytics: сводки по `taskID`, planned/honest focus,
  distractions, last focus, актуальный контекст существующих задач и
  исторический fallback удалённых задач.
- Общая `FocusGlassMarkGeometry` для AppIcon и launch animation.
- Явные Light/Dark палитры пользовательских тем и проверка импортируемых
  theme-файлов.
- Общие интерактивные зоны `FocusGlassHitTarget` и disclosure surface, у
  которых работает вся визуально выделенная область.
- Единая `FocusGlassMotion` policy для micro feedback, selection, disclosure,
  navigation, emphasis и progress с bounded Theme Studio scale и Reduce Motion.
- Instruments signposts для route/settings changes, theme commit, Menu Bar
  presentation и outcome presentation.

### Изменено

- Launch animation переработана в цельную последовательность tile, arc, timer
  hand, focus confirmation и wordmark с адаптивным размером и Reduce Motion.
- Theme Studio использует одно preview с режимами Main Window, Menu Bar и
  Fullscreen; `glassOpacity`, `density` и `motion` влияют на реальный UI.
- Menu Bar HUD переведён с `NSPopover` на lifecycle-managed `NSPanel`, чтобы
  открываться поверх других приложений и fullscreen Spaces.
- Fullscreen task flow адаптирован для узких окон и длинных RU/EN названий.
- Cockpit открывает Settings сразу на Strict Mode, а счётчики enabled app/site
  rules согласованы между поверхностями.
- Compact navigation, длинные подписи, вторичный текст и keyboard focus
  проверены и доработаны для Light, Dark и custom themes.
- Секундный snapshot таймера вынесен в отдельное presentation state, а
  task/analytics summaries кэшируются по изменению исходных коллекций: тик
  больше не инвалидирует весь cockpit и несвязанные экраны.
- Project grid использует полную selectable surface с внутренними отступами,
  отдельной зоной редактирования и адаптивной шириной для длинных RU/EN
  названий.
- Все scrollable surfaces используют общий scroll-phase-aware wrapper:
  ленивые стеки, hover/shadow suppression во время движения и совместимый с
  macOS 14 fallback через `NSScrollView` live-scroll notifications.
- Theme Studio открывает advanced-группы отдельно, не держит все ColorPicker и
  slider surfaces одновременно и не запускает app-wide transition animation
  на каждом шаге непрерывного редактирования.
- Theme Studio throttles интерактивные slider commits до 30 Hz и делает один
  финальный commit при завершении drag; route/list/status transitions используют
  value-scoped motion без spring/bounce и секундной анимации timer digits.
- На macOS 15 scroll tracking использует только системную scroll phase, а
  AppKit live-scroll fallback остаётся только для macOS 14. Во время прокрутки
  glass сохраняет статическую глубину без дорогого material compositing.

### Исправлено

- Все найденные кнопки, disclosure-заголовки, строки навигации, карточки и
  компактные icon actions реагируют на нажатие по полной видимой области, а не
  только по тексту или SF Symbol.
- `quitAfterOptIn` не выполняет опасное действие без сохранённого подтверждения.
- Dev-loop изолирует SwiftPM scratch-пути разных toolchain и не переиспользует
  несовместимую `.build`.
- Fullscreen checklist metadata больше не сжимается в вертикальную колонку
  букв рядом с длинным названием задачи.

### Проверено

- Полный набор SwiftPM-тестов: 79/79.
- Packaged-app QA главного окна, Settings, Theme Studio, Menu Bar, fullscreen,
  Strict Mode, launch animation, performance/UI-card и scroll-performance
  passes.
- Product Design/Build macOS Apps motion audit и Instruments traces:
  `/private/tmp/focusglass-motion-performance-20260811-154559`.
- `codesign --verify --deep --strict build/FocusGlass.app`.

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
