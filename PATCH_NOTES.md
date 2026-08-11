# FocusGlass 0.0.4 tester patch notes

Дата подготовки: 2026-06-27

> Исторический снимок tester-сборки `0.0.4`. Текущая ветка `codex/next`
> содержит более новые изменения, перечисленные в `CHANGELOG.md` в секции
> `Unreleased`; эти notes нельзя переиспользовать для следующей tester-версии
> без повторной генерации пакета и документов.

Ветка разработки: `codex/next`

Tester branch: `tester/0.0.4`

Commit/tag сборки: `v0.0.4`

## Что важно

Тестер ещё не проходил предыдущий пакет, поэтому `0.0.4` надо проверять как
накопительную tester-сборку. В неё входят изменения из `0.0.2/0.0.3` и новые
изменения после них: outcome screen, полный UI/UX audit pass, Theme Studio
polish и Cockpit First polish.

## Главное, что нужно проверить

1. Первый запуск `.app`, permission banner, Notifications, Accessibility и
   Automation prompts.
2. Таймеры: Pomodoro, Countdown, Stopwatch, Flow, Timebox, Intervals.
3. Задачи:
   - задачи без проекта;
   - больше трёх задач в проекте;
   - timed-задача получает прогресс после сессии;
   - checklist-задача не получает время и закрывается вручную;
   - активная задача сохраняется как выбранная задача сессии.
4. Post-session outcome:
   - planned vs honest time;
   - distraction count;
   - `Закрыть задачу`;
   - `Продолжить`;
   - `Следующая сессия`.
5. Cockpit UI:
   - таймер остаётся в центре;
   - проект и заметки проекта слева;
   - активная задача и задачи справа;
   - старое поле `Текущее намерение` не показывается;
   - длинные RU task titles читаются в 2-3 строки.
6. Project notes:
   - заметки открываются в cockpit;
   - заметки редактируются в Project Editor;
   - legacy intention мигрирует в notes активного проекта при старых данных.
7. Theme Studio:
   - цвет выбирается через macOS ColorPicker, а не ручной ввод hex;
   - один live preview, без дублирующего preview/explanation блока;
   - glass/motion, accent/status, foundations/readability sliders работают;
   - смена темы не ломает light/dark/custom readability.
8. Strict Mode:
   - app rules;
   - site rules;
   - warn/hide/pause;
   - strict rules во время break по настройке;
   - fullscreen strict flow.
9. Fullscreen focus:
   - timer;
   - task rail;
   - skip/reset/pause controls;
   - strict warning;
   - старое intention не показывается.
10. Menu bar HUD:
    - timer/progress;
    - strict toggle/status;
    - fullscreen/reset/skip/main-window actions;
    - старое intention не показывается.

## Правила отчёта

- Один пункт отчёта = одна проблема или одно UX-наблюдение.
- Для каждого пункта нужны: экран/путь, что ожидалось, что произошло, шаги,
  серьёзность и screenshot.
- Номер пункта должен совпадать с номером screenshot.
- Screenshot names: латиница, без пробелов, с номером:
  `01-cockpit-long-task.png`, `02-theme-picker.png`.
- Если к одному пункту несколько screenshot, добавлять suffix:
  `08-strict-warn-1.png`, `08-strict-warn-2.png`.
- Если баг связан с permissions/strict mode, указать macOS permission state.
- Если баг связан с данными, указать был ли запуск с чистым профилем или с
  уже существующим `~/Library/Application Support/FocusGlass`.

## Известные ограничения

- Сборка локальная/ad-hoc signed, без notarization. macOS может показать
  предупреждение при первом запуске архива.
- Strict site-rules зависят от macOS Automation permissions и браузера.
- GitHub Release не создаётся автоматически; tester branch содержит архив,
  checksum и документы для ручной передачи.
- На момент сборки `0.0.4` strict distraction history ещё не входила в пакет.
  В текущей ветке разработки она уже реализована и будет включена только в
  следующую tester-сборку после отдельной команды владельца.

## Проверки перед передачей

- `swift build`
- `swift test --disable-sandbox --scratch-path /tmp/FocusGlassApp_MacOS-swift-test`
- `./Scripts/package-release.sh`
- `shasum -a 256 -c FocusGlass-0.0.4.zip.sha256`
- `codesign --verify --deep --strict build/releases/0.0.4/FocusGlass.app`
- `plutil -p build/releases/0.0.4/FocusGlass.app/Contents/Info.plist`
