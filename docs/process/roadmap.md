# Roadmap

FocusGlass развивается без смены идеи проекта. Это не облачный task-manager и не календарь, а локальный macOS focus cockpit.

Главный цикл:

```text
подготовка -> фокус -> защита -> результат
```

## Ближайший фокус

### 1. Таймеры как полноценная система

- Найти и связать с поведением все поля, которые уже есть в UI/моделях, но используются слабо.
- Частично готово: `FocusTask.estimate` влияет на прогресс timed-задачи после
  завершённой сессии; выбранная на старте задача получает honest focus time.
  Готово: первый post-session outcome flow показывает planned vs honest,
  отвлечения, задачу и действия complete/continue/start next.
  Осталось решить, достаточно ли редактирования встроенных пресетов или нужны
  отдельные пользовательские пресеты.
- Добавить пользовательские таймеры в рамках существующих режимов.
- Готово: добавить описания базовых режимов в пользовательском UI:
  - Pomodoro;
  - Countdown;
  - Stopwatch;
  - Flow;
  - Timebox;
  - Intervals.

### 2. Session outcome

- Готов первый implementation pass: после завершения сессии Focus Today
  показывает итог:
  - проект;
  - задачу;
  - planned time;
  - honest focus time;
  - отвлечения;
  - действие с задачей: завершить, продолжить, запустить следующий блок.
- Готово: Build macOS Apps proof для attached timed/checklist задач:
  timed-задача показывает прогресс, checklist-задача не получает время,
  действия завершить/продолжить/запустить следующий блок проверены в live
  `.app`.
- Осталось: Product Design polish при изменении UX.

### 3. Strict mode end-to-end

- Полностью проверить действия `warn`, `hide`, `pauseSession`, `quitAfterOptIn`.
- Убедиться, что `warn` не скрывает приложение, но возвращает пользователя к FocusGlass.
- Убедиться, что `hide` скрывает приложение и показывает понятное сообщение.
- Готово: реально связать `pauseSession` с таймером.
- Готово: добавить настройку strict-mode enforcement во время перерывов.
- Добавить историю отвлечений.

### 4. UI interactive layer

- Единый hover/pressed/selected/focus state.
- Частично готово: увеличен hit area для project/task edit-кнопок. Осталось
  пройти sidebar, project cards, mode chips, settings tabs и strict rows.
- Единый визуальный checkbox/toggle.
- Проверка light/dark и пользовательских тем.

### 5. Аналитика

- Planned vs actual по сессиям, задачам и проектам.
- История последних сессий.
- Эффективность режимов.
- Отвлечения по проектам и режимам.

## Позже

- Наборы strict-rule presets.
- Улучшенный menu bar HUD.
- Улучшенный fullscreen task flow. Частично начато: добавлен skip segment и
  выбор активной задачи в fullscreen.
- Проверка читаемости Theme Studio. Частично начато: advanced color tokens
  получили живой preview.
- Подготовка подписанного/notarized релиза.

## Пока вне зоны

- Аккаунты.
- Cloud sync.
- Командная работа.
- Billing.
- Полноценная календарная система.
- Network Extension/hosts-file blocking.
- Сложные внешние task-manager integrations.
