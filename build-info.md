# Build info

- Version: `0.0.4`
- Git tag: `v0.0.4`
- Source commit: `1b113b55f64ed6db51b0ceeea935cebd8f035d12`
- Tag object: `ebc7ba17f1479424396b670003229d88ab483dc9`
- Bundle version: `34`
- Bundle identifier: `local.focusglass.app`
- Bundle short version: `0.0.4`
- Release directory: `build/releases/0.0.4`
- Archive: `FocusGlass-0.0.4.zip`
- Archive size: `4.3M`
- SHA-256: `29ed162bf5f952934c993d597f0feefb41b538148f11f208b253b32dffa41864`

## Validation

- `swift build` passed.
- `swift test --disable-sandbox --scratch-path /tmp/FocusGlassApp_MacOS-swift-test` passed: 58/58.
- `./Scripts/package-release.sh` created `FocusGlass.app`, zip, and checksum.
- `shasum -a 256 -c FocusGlass-0.0.4.zip.sha256` passed.
- `codesign --verify --deep --strict build/releases/0.0.4/FocusGlass.app` passed.
- `build/releases/0.0.4/FocusGlass.app/Contents/Info.plist` reports:
  - `CFBundleShortVersionString=0.0.4`
  - `CFBundleVersion=34`
  - `CFBundleIdentifier=local.focusglass.app`

## Scope

This is a cumulative tester build. The previous tester package was not fully
tested, so this package should be used for the first full external QA pass.

No GitHub Release was created in this step.
