# Информация о сборке

- Версия: `0.0.4`
- Git tag: `v0.0.4`
- Source commit: `1b113b55f64ed6db51b0ceeea935cebd8f035d12`
- Tag object: `ebc7ba17f1479424396b670003229d88ab483dc9`
- Bundle version: `34`
- Bundle identifier: `local.focusglass.app`
- Bundle short version: `0.0.4`
- Папка релизной сборки: `build/releases/0.0.4`
- Архив: `FocusGlass-0.0.4.zip`
- Размер архива: `4.3M`
- SHA-256: `29ed162bf5f952934c993d597f0feefb41b538148f11f208b253b32dffa41864`

## Проверка перед передачей

- `swift build` прошёл.
- `swift test --disable-sandbox --scratch-path /tmp/FocusGlassApp_MacOS-swift-test` прошёл: 58/58.
- `./Scripts/package-release.sh` создал `FocusGlass.app`, zip-архив и файл
  контрольной суммы.
- `shasum -a 256 -c FocusGlass-0.0.4.zip.sha256` прошёл.
- `codesign --verify --deep --strict build/releases/0.0.4/FocusGlass.app`
  прошёл.
- `build/releases/0.0.4/FocusGlass.app/Contents/Info.plist` содержит:
  - `CFBundleShortVersionString=0.0.4`
  - `CFBundleVersion=34`
  - `CFBundleIdentifier=local.focusglass.app`

## Область проверки

Это накопительная сборка для тестера. Предыдущий tester-пакет не был полноценно
проверен, поэтому эту сборку нужно использовать для первого полного внешнего
QA-прохода.

GitHub Release на этом шаге не создавался.
