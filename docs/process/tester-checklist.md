# FocusGlass tester checklist

Версия для текущей передачи: `0.0.4`

Этот чеклист нужен для первого полного прохода тестера. Предыдущие изменения
ещё не тестировались, поэтому проверять надо весь пользовательский путь, а не
только последние UI-правки.

## 0. Подготовка

- Скачать `FocusGlass-0.0.4.zip`.
- Проверить checksum:

```sh
shasum -a 256 -c FocusGlass-0.0.4.zip.sha256
```

- Распаковать zip.
- Запустить `FocusGlass.app`.
- Записать macOS version и способ запуска в отчёт.
- Для чистого теста можно временно убрать или переименовать
  `~/Library/Application Support/FocusGlass`.

## 1. Первый запуск и permissions

- Приложение открывается сразу в cockpit.
- Нет demo-проектов и demo-задач в чистом состоянии.
- Permission banner объясняет, зачем нужны Notifications и Accessibility.
- `Запросить уведомления` вызывает macOS prompt или понятное сообщение.
- `Запросить Accessibility` открывает нужный системный раздел.
- Automation checks не ломают приложение, если permission ещё не выдан.
- Повторный запуск не показывает бесконечно один и тот же prompt.

## 2. Cockpit

- Таймер визуально находится в центре wide-layout.
- Слева виден активный проект и `Заметки проекта`.
- Справа видна featured `Активная задача сессии` и список задач.
- Верхнего поля `Текущее намерение` нет.
- В карточке активного проекта нет постоянных edit project, task count и add
  project controls.
- Длинное название active timed task читается в 2-3 строки.
- Обычная task row выглядит как одна широкая карточка, а не как три
  раздельные колонки checkbox/card/edit.
- Compact/medium ширина окна не ломает порядок: timer, project context, tasks.

## 3. Проекты и заметки

- Создать проект.
- Выбрать проект в cockpit dropdown.
- Добавить project notes в cockpit disclosure.
- Закрыть и открыть приложение, notes должны сохраниться.
- Открыть Project Editor и изменить notes там.
- Переименовать проект: задачи остаются привязанными к нему.
- Удалить проект: задачи становятся `Без проекта`.

## 4. Задачи

- Создать задачу без проекта.
- Создать больше трёх задач в одном проекте: список должен scroll-иться.
- Выбрать active task, запустить timer, затем выбрать другую task до конца
  сессии: время должно записаться в task, выбранную на старте.
- Timed task показывает progress.
- Checklist task не получает time progress.
- Редактирование title/project/type/estimate/done работает.
- Ручной ввод минут работает рядом со steppers.

## 5. Таймеры

- Проверить Pomodoro, Countdown, Stopwatch, Flow, Timebox, Intervals.
- Start/pause/resume/reset работают.
- Skip disabled для single-segment preset.
- Skip работает для multi-segment preset.
- Stepper minutes snap: `1 -> 5 -> 10`, `6 -> 10`, `5 -> 1`, `0 -> 5` где
  zero разрешён.
- Настройки пресетов сохраняются после relaunch.

## 6. Outcome screen

- Завершить timed task session.
- Проверить planned vs honest time.
- Проверить distraction count.
- `Закрыть задачу` закрывает captured task.
- `Продолжить` оставляет captured task active.
- `Следующая сессия` запускает новый timer с той же task.
- Checklist outcome не показывает timed progress и закрывается вручную.

## 7. Theme Studio

- Открыть Settings -> Appearance.
- Выбрать built-in theme.
- Создать копию темы.
- Изменить цвета через ColorPicker, не вводя hex вручную.
- Проверить live preview.
- Проверить sliders glass/motion, accent/status, foundations/readability.
- Проверить light/dark/system appearance.
- Убедиться, что нет двух одинаковых live preview/explanation блоков.
- Удалить custom theme; built-in theme удалить нельзя.

## 8. Strict Mode

- Добавить app rule из running apps.
- Добавить app rule вручную по bundle id.
- Добавить site rule `youtube.com`.
- Добавить wildcard site rule `*.reddit.com`.
- Проверить warn action.
- Проверить hide action.
- Проверить pause action: running timer становится paused.
- Проверить, что strict rules не работают на break по умолчанию.
- Включить strict during breaks и проверить, что rules работают на break.
- Проверить strict status в cockpit, menu bar и fullscreen.

## 9. Fullscreen focus

- Открыть fullscreen mode.
- Проверить timer, phase, progress.
- Проверить task rail.
- Проверить hover controls: pause/resume/reset/skip/close.
- Проверить strict warning в fullscreen.
- Убедиться, что старое intention не показывается.

## 10. Menu bar HUD

- Открыть menu bar panel.
- Проверить timer/progress.
- Проверить start/pause.
- Проверить strict toggle/status.
- Проверить fullscreen/reset/skip/open-main actions.
- Убедиться, что старое intention не показывается.

## 11. Отчёт

- Заполнять `tester-report-template.md`.
- Один пункт = одна проблема или UX-наблюдение.
- Для каждого пункта приложить screenshots.
- Отдельно отметить blockers, которые мешают дальше тестировать.
