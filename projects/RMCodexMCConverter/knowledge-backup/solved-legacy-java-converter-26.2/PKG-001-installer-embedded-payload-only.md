# PKG-001 — Installer must use embedded payload only

## Symptom

Running a new Setup EXE beside an older `RB-Legacy-Java-Converter-Portable.zip` installs stale tools.

## Solution

Setup `ExtractEmbeddedPayloadZip()` uses **only** the embedded resource `portable-payload.zip`. Sibling zips and `dist\` fallbacks are ignored.

Product: `MC-Java-1.20.1-to-26.2-Converter` → `dist\RB-Legacy-Java-Converter-Setup.exe`

## Verify

Setup assembly manifest resources include `portable-payload.zip`; source has no `FindPayloadZip` sibling preference.
