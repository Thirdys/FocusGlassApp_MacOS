# FocusGlass 0.0.3 tester build

Дата сборки: 2026-06-19

## Файлы

- `FocusGlass-0.0.3.zip` - архив приложения для тестирования.
- `FocusGlass-0.0.3.zip.sha256` - checksum для проверки архива.
- `build-info.md` - источник сборки и параметры пакета.
- `tester-report-template.md` - шаблон отчёта: как описывать проблемы,
  прикладывать скриншоты и давать шаги воспроизведения.

## Проверка checksum

```bash
shasum -a 256 -c FocusGlass-0.0.3.zip.sha256
```

Ожидаемый результат:

```text
FocusGlass-0.0.3.zip: OK
```

## Установка

1. Распакуй `FocusGlass-0.0.3.zip`.
2. Запусти `FocusGlass.app`.
3. Если macOS предупредит о приложении из интернета, открой через правый клик -> Open.

## Что тестировать

- Первый запуск и permission banner.
- Settings, особенно хранение данных, таймеры, строгий режим и оформление.
- Fullscreen focus window.
- Strict Mode overview.
- Таймеры, задачи и checklist/timed task behavior.

Strict warn/hide/pause на реальных заблокированных приложениях/сайтах требует отдельной проверки с настроенными правилами и системными permissions.

## Как прислать отчёт

1. Скопируй `tester-report-template.md` рядом со своими скриншотами.
2. Заполни один раздел на каждую проблему или UX-наблюдение.
3. Положи изображения в папку `screenshots/` и вставь их в Markdown по примеру
   из шаблона.
4. Отправь заполненный Markdown-файл и папку `screenshots/`.
