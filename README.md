# FocusGlass

> Нативный macOS focus cockpit для людей, которые хотят не просто включить таймер, а спокойно пройти весь цикл работы: подготовиться, сфокусироваться, защитить сессию и увидеть честный результат.

FocusGlass создаётся как локальное приложение с уважением к пользователю: без аккаунтов, облака и лишней суеты. Оно должно открываться сразу в рабочий экран, помогать выбрать режим, проект и задачу, а затем удерживать внимание через полноэкранный фокус, menu bar HUD и мягкий strict mode.

![Главное окно FocusGlass](docs/design/concepts/main-window.png)

## Что уже есть

- Нативное SwiftUI-приложение для macOS.
- Главное окно-cockpit для текущей фокус-сессии.
- Menu bar панель для быстрого контроля.
- Полноэкранный focus mode.
- Редактируемые проекты, задачи и таймерные пресеты.
- Strict mode для приложений и сайтов через macOS Accessibility/Automation.
- Локальное JSON-хранилище без аккаунтов и синхронизации.
- RU/EN локализация.
- Theme Studio с адаптацией под light/dark.
- Тестируемое ядро таймера и аналитики.

## Зачем это приложение

Обычный таймер отвечает только на вопрос “сколько осталось?”. FocusGlass должен отвечать на более полезные вопросы:

- над чем я сейчас работаю;
- сколько времени я планировал потратить;
- сколько честного фокуса получилось;
- что меня отвлекало;
- стоит ли продолжить задачу, завершить её или сменить режим.

Главная идея проекта: сделать фокус-сессию видимой и управляемой, но не превращать приложение в тяжёлый task-manager.

## Основной цикл

1. Выбрать режим: Pomodoro, Countdown, Stopwatch, Flow, Timebox или Intervals.
2. Указать намерение на сессию.
3. Выбрать проект и задачу.
4. Запустить таймер.
5. При необходимости перейти в fullscreen focus.
6. Дать strict mode вернуть внимание при отвлечении.
7. После сессии посмотреть честный результат.

## Скриншоты дизайна

| Главное окно | Menu bar | Fullscreen focus |
| --- | --- | --- |
| ![Главное окно](docs/design/concepts/main-window.png) | ![Menu bar](docs/design/concepts/menu-bar-panel.png) | ![Fullscreen focus](docs/design/concepts/fullscreen-focus.png) |

## Технологии

- Swift 6
- SwiftUI
- AppKit integrations
- Swift Package Manager
- Testing framework
- Local JSON persistence
- UserNotifications
- Accessibility
- Apple Events / Automation
- ServiceManagement для Launch at Login

## Требования

- macOS 14 или новее.
- Xcode рекомендуется для полноценной сборки и отладки.
- Для проверки Notifications, Accessibility и Automation нужно запускать именно `.app`, а не только `swift run`.

## Сборка и тесты

```sh
swift build --disable-sandbox
swift test --disable-sandbox --scratch-path /tmp/FocusGlassApp_MacOS-swift-test
```

Быстрый запуск как SwiftPM executable:

```sh
swift run FocusGlass
```

Сборка локального `.app` для ручного тестирования:

```sh
./Scripts/package-app.sh
open build/FocusGlass.app
```

`swift run` полезен для быстрых UI-проверок, но macOS не считает такой процесс полноценным приложением. Для permissions QA используй `build/FocusGlass.app`.

## Структура проекта

```text
Sources/
  FocusGlassCore/      # чистое ядро таймера, аналитики и strict-rule типов
  FocusGlassApp/       # SwiftUI/AppKit приложение, сервисы, ViewModel, ресурсы
Tests/                 # тесты ядра и app persistence
docs/                  # архитектура, продукт, дизайн и QA
docs/process/          # правила GitHub, релизов и разработки
Scripts/               # упаковка .app и генерация иконки
archive/               # безопасный архив вынесенных неиспользуемых файлов
```

## Документация

- [Product Context](docs/product-context.md) - зачем существует FocusGlass и что сейчас в зоне продукта.
- [Architecture](docs/architecture.md) - устройство приложения, persistence, permissions, strict mode, темы.
- [Assistant Context](docs/assistant-context.md) - первый файл для будущих AI-сессий.
- [Design Source](docs/design/design-source.md) - локальный источник визуальной системы.
- [QA Checklist](docs/qa-checklist.md) - ручная и автоматическая проверка.
- [GitHub Workflow](docs/process/github-workflow.md) - ветки, коммиты, теги, релизы и правила работы.
- [Roadmap](docs/process/roadmap.md) - ближайшее развитие без смены идеи проекта.

Документация считается частью реализации. Если меняется поведение, структура данных, permissions, UI, сборка или QA, соответствующий документ обновляется в том же изменении.

## Как ведётся разработка

Проект ведётся по аккуратному GitHub-процессу:

- `main` - стабильная ветка.
- `feature/...` - новые возможности.
- `fix/...` - исправления.
- `chore/...` - инфраструктура и уборка.
- `docs/...` - документация.
- коммиты пишутся на русском в формате `тип: краткое действие`;
- релизы отмечаются тегами `vMAJOR.MINOR.PATCH`;
- изменения для пользователей фиксируются в [CHANGELOG.md](CHANGELOG.md).

Подробные правила: [docs/process/github-workflow.md](docs/process/github-workflow.md).

## Текущий статус

Проект находится в активной разработке. Это уже не пустой MVP, но ещё не финальный публичный релиз. Ближайший фокус:

- довести таймеры и task estimate до полноценного поведения;
- усилить strict mode end-to-end;
- сделать session outcome;
- выровнять интерактивность UI;
- улучшить аналитику planned vs honest focus.

## Принципы проекта

- Локальность важнее облачной сложности.
- Фокус важнее количества функций.
- UI должен быть красивым, но рабочим.
- Пользовательские данные нельзя терять молча.
- Permissions должны объясняться честно.
- Каждый видимый элемент должен иметь реальное поведение.

## Лицензия

Лицензия ещё не выбрана. До выбора лицензии код считается закрытым для переиспользования вне личного разрешения автора.
