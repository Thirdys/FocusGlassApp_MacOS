# Roadmap

FocusGlass развивается без смены идеи проекта. Это не облачный task-manager и
не календарь, а локальный macOS focus cockpit.

Главный цикл:

```text
подготовка -> фокус -> защита -> результат
```

## Текущее состояние

### Таймеры и задачи

- Реализованы Pomodoro, Countdown, Stopwatch, Flow, Timebox и Intervals.
- Встроенные presets редактируются и сбрасываются по одному.
- Timed-задачи получают honest focus time задачи, захваченной на старте
  сессии; checklist-задачи закрываются вручную и не получают time progress.
- Post-session outcome показывает planned vs honest, отвлечения, контекст
  проекта/задачи и действия complete/continue/start next.
- Project notes заменили глобальное поле intention.

Открытое решение: достаточно ли редактирования встроенных presets или нужны
отдельные пользовательские timer presets.

### Strict Mode

- App/site rules поддерживают `warn`, `hide`, `pauseSession` и безопасный
  `quitAfterOptIn`.
- Cockpit открывает Settings сразу на Strict Mode; enabled app/site counts
  согласованы между поверхностями.
- Strict protection работает во время активной сессии в normal и fullscreen
  flows, а enforcement во время break включается отдельно.
- Persistent distraction history хранит цель, время, правило, фактическое
  действие, сессию, проект, задачу и режим таймера.
- Packaged-app proof покрывает реальные app rules, Safari Automation site rule
  и отмену опасного quit.

Открытое решение: нужны ли пользователю наборы strict-rule presets.

### UI, темы и системные поверхности

- Wide cockpit сохраняет проект слева, таймер в центре и задачи справа;
  medium/compact layouts, длинные RU/EN подписи и keyboard focus проверены.
- Общий visual control layer покрывает hover, pressed, selected, focus и полные
  pointer targets для выделенных surface.
- Theme Studio хранит явные Light/Dark palettes, использует один preview с
  режимами Main Window/Menu Bar/Fullscreen и подключает `glassOpacity`,
  `density` и `motion` к runtime UI.
- AppIcon и launch animation используют общую `FocusGlassMarkGeometry`;
  последовательность адаптивна и уважает Reduce Motion.
- Menu Bar HUD работает через lifecycle-managed `NSPanel` поверх других
  приложений и fullscreen Spaces.
- Fullscreen адаптирован для узких окон и длинных названий задач.
- Секундный timer snapshot изолирован от общего app state; project/task counts,
  analytics summaries и heatmap не пересчитываются на каждом тике. Project
  cards держат длинные RU/EN названия внутри полной selectable surface.

Открыто: отдельный VoiceOver-аудит и точечный Product Design polish на реальных
пользовательских данных.

### Аналитика

- Реализованы daily summary, focus score, planned vs actual/effectiveness,
  recent sessions, mode effectiveness, project summaries и distraction
  analytics по проектам/режимам.

Открытое решение: нужны ли отдельные task-level срезы сверх текущих session и
project summaries.

## Следующий порядок

0. Первый отдельный interface-performance pass завершён:
   - секундный `TimerEngineSnapshot` публикуется через отдельный
     `FocusTimerPresentationState`, не через весь `FocusGlassViewModel`;
   - active tasks, project task counts, analytics summaries и heatmap
     перестраиваются только при изменении исходных данных;
   - исправлены лишние `activeTaskID = nil` публикации и project-card layout,
     найденный Product Design live-аудитом;
   - packaged `.app` проверена на narrow/medium layouts, Light/Dark custom
     theme и длинных RU/EN строках; runtime timer samples держались в пределах
     `0.0...1.2% CPU`, около `119 MB` resident memory и 4 threads;
   - proof: `/private/tmp/focusglass-performance-pass-20260726-034829`.
   Полный Instruments trace остаётся optional follow-up при установленном
   полном Xcode или при появлении воспроизводимого jank.
1. Получить и разобрать обратную связь по tester-сборке. `tester/0.0.4` является
   историческим снимком; следующая tester delivery создаётся только по команде
   владельца и получает новую версию, cumulative checklist и новые документы.
2. Провести Product Design polish на реальных накопленных session/history data,
   не перестраивая уже реализованные outcome, Strict history и analytics с
   нуля.
3. Принять продуктовые решения по custom timer presets, strict-rule presets и
   task-level analytics.
4. Провести отдельный VoiceOver/accessibility audit всех основных surfaces.
5. Подготовить Developer ID signing/notarization для более широкого
   распространения.

## QA-инструменты позже

- При необходимости добавить ScreenCaptureKit-based helper для стабильной
  записи launch animation на 60/120 Hz. DEBUG launch delay остаётся только
  локальным инструментом и не влияет на release timing.
- Branch protection и GitHub Actions включать после отдельного решения о
  стабильном PR/release процессе.

## Пока вне зоны

- Аккаунты.
- Cloud sync.
- Командная работа.
- Billing.
- Полноценная календарная система.
- Network Extension/hosts-file blocking.
- Сложные внешние task-manager integrations.
