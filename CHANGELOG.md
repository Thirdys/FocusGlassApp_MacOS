# История изменений

Формат основан на идее Keep a Changelog, но записи ведутся на русском. Версии тегируются как `vMAJOR.MINOR.PATCH`.

## [Unreleased]

### Добавлено

- Правила ведения GitHub-проекта, веток, коммитов, тегов и релизов.
- GitHub-шаблоны для багов, фич и pull request.
- Публичный README с описанием продукта, сборки, структуры и текущего направления.
- Описания режимов таймера в настройках для Pomodoro, Countdown, Stopwatch, Flow, Timebox и Intervals.
- Скрипт подготовки release zip и SHA-256 checksum для ручного tester handoff или GitHub Releases.

### Изменено

- Handoff используется как долговременная память проекта между сессиями.
- Главный cockpit больше не дублирует активный проект и задачи в правой контекстной панели.
- Скрипт упаковки поддерживает настраиваемые scratch/app пути через переменные окружения.
- Скрипт упаковки хранит Clang module cache внутри package work dir, чтобы packaging проходил в ограниченных средах без записи в `~/.cache`.
- `build/` закреплён как локальный generated output; тестовые `.app` сборки передаются вручную или через GitHub Release assets, а не через git.
- GitHub Release описан как ручная страница раздачи уже собранного zip/checksum, а не как обязательная автоматизация сборки.

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
