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

- Готово: кнопка управления из cockpit открывает сразу
  Settings -> Strict Mode; счётчики приложений и сайтов используют одинаковые
  enabled-правила в cockpit и Settings.
- Готово: `quitAfterOptIn` требует отдельного опасного подтверждения. Старое
  правило без сохранённого opt-in безопасно выполняется как `hide`.
- Готово: история отвлечений сохраняет цель, время, правило, действие,
  сессию, проект, задачу и режим; Strict Mode показывает историю и позволяет
  очистить её.
- Готово: live `.app` proof для `warn`, `hide` и `pauseSession` на реальном
  приложении. Для site-rule также проверен реальный Safari Automation URL-path
  на безопасной локальной странице `127.0.0.1`: браузер скрыт, событие
  записано в историю.
- Готово: destructive confirmation для `quitAfterOptIn` проверен в live
  `.app`; отмена сохраняет предыдущее безопасное действие и не закрывает
  целевое приложение.
- Готово: реально связать `pauseSession` с таймером.
- Готово: добавить настройку strict-mode enforcement во время перерывов.

### 4. UI interactive layer

- Готово в первом полном implementation pass: единые
  hover/pressed/selected/focus states, увеличенные hit areas, keyboard-focusable
  project cards, responsive strict rows, адаптивные mode chips и
  accessibility selected traits.
- Готово: новый cockpit сохраняет таймер в центре, скрывает контекстный rail на
  medium-layout и возвращает его только при ширине от 1680 pt.
- Готово: усилен контраст вторичного текста в light/dark/custom themes;
  проверены light и dark Theme Studio состояния.
- Готово: live compact-layout proof ниже 980 pt, длинные RU/EN названия,
  light/dark/custom themes и Tab traversal с временно включённой macOS
  Keyboard Navigation. Найденное сжатие compact-nav labels исправлено.
- Осталось: точечный Product Design polish по реальным накопленным данным и
  отдельный VoiceOver-аудит, если он понадобится перед более широкой поставкой.

### 5. Аналитика

- Готов первый implementation pass: planned vs actual/effectiveness,
  последние сессии, эффективность режимов, сводка по проектам и отвлечения по
  проектам/режимам.
- Осталось: Product Design polish на реальных накопленных данных и решение,
  нужны ли отдельные task-level срезы сверх текущих session/project summaries.

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
