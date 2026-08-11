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

Решение принято: на текущем этапе достаточно редактирования встроенных
presets. Отдельные пользовательские presets возвращаются в план только если
tester feedback покажет потребность хранить несколько вариантов одного режима.

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

Решение принято: strict-rule presets пока не нужны. Текущий поштучный flow
достаточен для небольшого локального набора правил. Если повторяющиеся наборы
появятся в tester feedback, проектировать только безопасные suggestions:
предпросмотр всех правил, disabled по умолчанию и без `quitAfterOptIn`.

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

Product Design polish на реальных накопленных данных завершён. Открыт отдельный
VoiceOver/accessibility audit.

### Аналитика

- Реализованы daily summary, focus score, planned vs actual/effectiveness,
  recent sessions, mode effectiveness, project summaries и distraction
  analytics по проектам/режимам.
- Task-level analytics группирует связанные session records по `taskID` и
  показывает project, sessions, honest focus, distractions и last focus.
- Актуальные timed-задачи показывают planned vs honest и effectiveness;
  checklist и удалённые исторические задачи не получают time-progress.
- Первый task analytics pass встроен в текущий Analytics screen без новой
  sidebar route и без изменения persistence schema.

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
   Продолжение performance-pass также завершено:
   - все app scroll surfaces используют общий scroll-phase-aware wrapper,
     ленивые стеки и подавление hover/shadow/material cost во время движения;
   - Theme Studio advanced-группы раскрываются отдельно, а непрерывные
     slider/color edits не запускают app-wide transition на каждом шаге;
   - fullscreen task metadata больше не сжимается рядом с длинным заголовком;
   - proof:
     `/private/tmp/focusglass-scroll-performance-20260726-044203`.
   Нулевой unified motion/performance pass также завершён:
   - `FocusGlassMotion` задаёт bounded timing families, calm easing и Reduce
     Motion policy для всех основных surfaces;
   - Theme Studio slider commits throttled до 30 Hz, route/list/status motion
     value-scoped, timer digits не анимируются каждую секунду;
   - scroll surfaces отключают material compositing во время движения, а
     legacy AppKit fallback не устанавливается на macOS 15;
   - добавлены Instruments signposts для route, settings, theme commit, Menu
     Bar и outcome;
   - полный Xcode Instruments pass выполнен. Финальный 55.124 s trace не
     показал hangs или широкую AttributeGraph invalidation; hitch lane был
     загрязнён Computer Use screenshot capture, поэтому zero-hitch claim не
     делается;
   - proof и ограничения:
     `/private/tmp/focusglass-motion-performance-20260811-154559/audit-notes.md`.
1. Получить и разобрать обратную связь по tester-сборке. `tester/0.0.4` является
   историческим снимком; следующая tester delivery создаётся только по команде
   владельца и получает новую версию, cumulative checklist и новые документы.
2. Product Design polish на реальных накопленных session/history data завершён
   без перестройки outcome, Strict history и analytics. Proof:
   `/private/tmp/focusglass-real-data-polish-20260727-010950`.
3. Продуктовые решения по custom timer presets, strict-rule presets и
   task-level analytics приняты. Decision audit:
   `/private/tmp/focusglass-product-decisions-20260727-022057`.
4. Первый task-level analytics pass завершён: summary по задаче, session count,
   planned/honest time, distractions, timed-task effectiveness, last focus
   date и корректное отображение удалённых/checklist задач. Product
   Design/packaged-app proof:
   `/private/tmp/focusglass-task-analytics-20260727-030240`.
5. Провести отдельный VoiceOver/accessibility audit всех основных surfaces.
6. Подготовить Developer ID signing/notarization для более широкого
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
