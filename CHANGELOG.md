# История изменений

Формат основан на идее Keep a Changelog, но записи ведутся на русском. Версии тегируются как `vMAJOR.MINOR.PATCH`.

## [Unreleased]

### Добавлено

- Правила ведения GitHub-проекта, веток, коммитов, тегов и релизов.
- GitHub-шаблоны для багов, фич и pull request.
- Публичный README с описанием продукта, сборки, структуры и текущего направления.

### Изменено

- Handoff используется как долговременная память проекта между сессиями.

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
