# Roadmap

FocusGlass развивается без смены идеи проекта. Это не облачный task-manager и не календарь, а локальный macOS focus cockpit.

Главный цикл:

```text
подготовка -> фокус -> защита -> результат
```

## Ближайший фокус

### 1. Таймеры как полноценная система

- Найти и связать с поведением все поля, которые уже есть в UI/моделях, но используются слабо.
- Довести `FocusTask.estimate` до реального влияния на planned time, прогресс задачи и итог сессии.
- Добавить пользовательские таймеры в рамках существующих режимов.
- Добавить описания базовых режимов:
  - Pomodoro;
  - Countdown;
  - Stopwatch;
  - Flow;
  - Timebox;
  - Intervals.

### 2. Session outcome

- После сессии показывать результат:
  - проект;
  - задачу;
  - planned time;
  - honest focus time;
  - отвлечения;
  - действие с задачей: завершить, продолжить, запустить следующий блок.

### 3. Strict mode end-to-end

- Полностью проверить действия `warn`, `hide`, `pauseSession`, `quitAfterOptIn`.
- Убедиться, что `warn` не скрывает приложение, но возвращает пользователя к FocusGlass.
- Убедиться, что `hide` скрывает приложение и показывает понятное сообщение.
- Реально связать `pauseSession` с таймером.
- Добавить историю отвлечений.

### 4. UI interactive layer

- Единый hover/pressed/selected/focus state.
- Полный hit area для sidebar, project cards, mode chips, settings tabs и strict rows.
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
- Улучшенный fullscreen task flow.
- Проверка читаемости Theme Studio.
- Подготовка подписанного/notarized релиза.

## Пока вне зоны

- Аккаунты.
- Cloud sync.
- Командная работа.
- Billing.
- Полноценная календарная система.
- Network Extension/hosts-file blocking.
- Сложные внешние task-manager integrations.
