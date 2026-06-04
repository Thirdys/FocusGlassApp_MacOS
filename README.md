# FocusGlass tester build dev-c9a78ff

This branch contains a test build artifact only. It is not a source branch.

## Files

- `FocusGlass-dev-c9a78ff.zip` - packaged FocusGlass `.app` for testing.
- `FocusGlass-dev-c9a78ff.zip.sha256` - checksum for the zip.

## How to use

1. Download `FocusGlass-dev-c9a78ff.zip`.
2. Optionally verify it:

   ```sh
   shasum -a 256 -c FocusGlass-dev-c9a78ff.zip.sha256
   ```

3. Unzip the archive and run `FocusGlass.app`.

This build was produced locally with `./Scripts/package-release.sh`.
