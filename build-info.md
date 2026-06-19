# Build info

- Version: `0.0.3`
- Git tag: `v0.0.3`
- Source commit: `d71dc139bdcef531d067156704534b60453be7c2`
- Tag object: `991f007870d59ccddba4732b0f9b4cfae1d89531`
- Bundle version: `28`
- Bundle identifier: `local.focusglass.app`
- Bundle short version: `0.0.3`
- Release directory: `build/releases/0.0.3`
- Archive: `FocusGlass-0.0.3.zip`
- SHA-256: `1df285a2360ed60603f4c63f48c773165e5801e1ac83b33acf1df08cbc504bdf`

## Validation

- `swift build` passed.
- `swift test --disable-sandbox --scratch-path /tmp/FocusGlassApp_MacOS-swift-test` passed: 50/50.
- `./Scripts/package-release.sh` created `FocusGlass.app`, zip, and checksum.
- `shasum -a 256 -c FocusGlass-0.0.3.zip.sha256` passed.
- `codesign --verify --deep --strict build/releases/0.0.3/FocusGlass.app` passed.
- `build/releases/0.0.3/FocusGlass.app/Contents/Info.plist` reports `CFBundleShortVersionString=0.0.3` and `CFBundleVersion=28`.

No GitHub Release was created in this step.
