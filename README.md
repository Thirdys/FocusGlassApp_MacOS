# FocusGlass тестовая сборка dev-c9a78ff

Эта ветка содержит только тестовую сборку FocusGlass. Это не ветка с исходным
кодом, её не нужно мержить в `main` или `codex/next`.

## Файлы

- `FocusGlass-dev-c9a78ff.zip` - архив с `FocusGlass.app` для тестирования.
- `FocusGlass-dev-c9a78ff.zip.sha256` - контрольная сумма архива.

## Как запустить

1. Скачать `FocusGlass-dev-c9a78ff.zip`.
2. По желанию проверить архив:

   ```sh
   shasum -a 256 -c FocusGlass-dev-c9a78ff.zip.sha256
   ```

   Если всё хорошо, команда напишет `FocusGlass-dev-c9a78ff.zip: OK`.

3. Распаковать архив.
4. Запустить `FocusGlass.app`.

Сборка создана локально через `./Scripts/package-release.sh`.

## Если macOS предупреждает о приложении

Это тестовая unsigned-сборка. macOS может показать предупреждение при первом
запуске. Это ожидаемо для текущего тестового handoff.
