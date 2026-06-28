# FocusGlass 0.0.4 tester build

Дата сборки: 2026-06-27

Эта сборка заменяет непроверенную `0.0.3` для первого полного tester pass.
Проверять нужно накопительно: таймеры, задачи, outcome, Theme Studio, cockpit,
fullscreen, menu bar и strict mode.

## Файлы

- `FocusGlass-0.0.4.zip` - архив приложения для тестирования.
- `FocusGlass-0.0.4.zip.sha256` - checksum для проверки архива.
- `build-info.md` - источник сборки, tag, commit и результаты validation.
- `TESTER_CHECKLIST.md` - полный чеклист ручной проверки.
- `TESTER_RULES.md` - правила запуска, отчёта и severity.
- `tester-report-template.md` - шаблон отчёта с примерами screenshots.

## Проверка checksum

```bash
shasum -a 256 -c FocusGlass-0.0.4.zip.sha256
```

Ожидаемый результат:

```text
FocusGlass-0.0.4.zip: OK
```

## Установка

1. Распакуй `FocusGlass-0.0.4.zip`.
2. Запусти `FocusGlass.app`.
3. Если macOS предупредит о приложении из интернета, открой через правый клик
   -> Open. Это ожидаемо для local/ad-hoc signed tester build.

## С чего начать

1. Прочитай `TESTER_RULES.md`.
2. Иди по `TESTER_CHECKLIST.md`.
3. Заполняй `tester-report-template.md`.
4. Для каждого найденного пункта добавляй screenshot в папку `screenshots/`.

## Главное для проверки

- Первый запуск и permissions.
- Cockpit: timer center, project notes left, active task/tasks right.
- Project notes и migration старого intention.
- Timed/checklist tasks и post-session outcome.
- Theme Studio picker-first editor.
- Strict Mode warn/hide/pause, apps/sites, break setting.
- Fullscreen focus и menu bar HUD без старого intention.

## Известные ограничения

- Сборка ad-hoc signed и не notarized.
- Strict site rules зависят от macOS Automation permissions и браузера.
- Если проверяешь на реальных пользовательских данных, сначала сделай backup
  `~/Library/Application Support/FocusGlass`.

## Как прислать отчёт

1. Заполни `tester-report-template.md`.
2. Приложи папку `screenshots/`.
3. Если есть blocker/crash, поставь severity `blocker` и отправь его первым.
