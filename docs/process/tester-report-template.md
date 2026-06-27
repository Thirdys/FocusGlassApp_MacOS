# FocusGlass tester report

- Версия: 0.0.4
- macOS:
- Дата:
- Сборка/ссылка: ветка `tester/0.0.4`
- Тестер:

## Правила отчёта

- Один пункт отчёта = одна проблема или одно UX-наблюдение.
- Если проблема блокирует дальнейший тест, поставить `Severity: blocker`.
- Если проблема только визуальная/копирайтинг, но сценарий работает, поставить
  `Severity: low` или `medium`.
- Номер пункта должен совпадать с номером скриншота.
- Скриншоты класть рядом с отчётом в папку `screenshots/`.
- Имена файлов делать латиницей, без пробелов, с номером пункта: `01-theme-background.png`, `02-timer-stepper-before.png`.
- В Markdown вставлять скриншоты так: `![01-theme-background](screenshots/01-theme-background.png)`.
- Если к одному пункту несколько скриншотов, добавлять suffix: `08-project-tasks-1.png`, `08-project-tasks-2.png`.
- Если баг зависит от permissions, указать состояние macOS permissions.
- Если баг зависит от данных, указать чистый запуск это был или уже
  существующее хранилище FocusGlass.

## Что приложить вместе с отчётом

- Заполненный Markdown.
- Папку `screenshots/`.
- Если приложение не запускается: screenshot macOS warning/error и текст из
  Console/logs, если он доступен.
- Если баг про strict mode: какие rules были включены и какое приложение/сайт
  использовались.

## 1. Краткое название проблемы

- Severity: blocker / high / medium / low
- Тип: crash / баг / UX / текст / визуал / strict mode / permissions / fullscreen / другое
- Где: экран или путь
- Данные: чистый запуск / существующее хранилище / неизвестно
- Permissions state:
- Что ожидалось:
- Что произошло:
- Шаги:
  1. ...
  2. ...
  3. ...
- Насколько мешает: высокий / средний / низкий
- Скриншоты:

![01-theme-background](screenshots/01-theme-background.png)

## 2. Следующая проблема

- Severity:
- Тип:
- Где:
- Данные:
- Permissions state:
- Что ожидалось:
- Что произошло:
- Шаги:
  1. ...
  2. ...
  3. ...
- Насколько мешает:
- Скриншоты:

![02-timer-stepper-before](screenshots/02-timer-stepper-before.png)
![02-timer-stepper-after](screenshots/02-timer-stepper-after.png)

## Дополнительные заметки

- ...
