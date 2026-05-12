# PluginVault

PluginVault is a beta macOS app for scanning and managing installed DAW plug-ins with a deliberately classic Macintosh System 7-style interface.

It scans common AU, VST, VST3, and AAX plug-in folders, lets you tag plug-ins using Finder tags, and can vault plug-ins by renaming their bundle directories with a `.vaulted` suffix. Most DAWs ignore the renamed bundles, which makes vaulting useful for temporarily removing plug-ins without deleting them.

## Beta Notes

This is an early beta intended for careful local use.

- Back up `/Library/Audio/Plug-Ins` and `~/Library/Audio/Plug-Ins` before bulk vaulting.
- Vaulting changes plug-in bundle names on disk. Use `Unvault All` before deleting the app if you want every discovered plug-in restored.
- The app is intentionally unsandboxed so it can manage system and user plug-in folders.
- The current project deployment target is macOS 26.2.
- The beta package is development signed and not notarized.

## Features

- Scans these default folders:
  - `/Library/Audio/Plug-Ins/Components`
  - `/Library/Audio/Plug-Ins/VST`
  - `/Library/Audio/Plug-Ins/VST3`
  - `/Library/Audio/Plug-Ins/AAX`
  - `~/Library/Audio/Plug-Ins/Components`
  - `~/Library/Audio/Plug-Ins/VST`
  - `~/Library/Audio/Plug-Ins/VST3`
- Shows active, vaulted, tagged, and collection filters in a compact classic sidebar.
- Syncs app tags with macOS Finder tags where permissions allow.
- Vaults untagged plug-ins in bulk.
- Restores all vaulted plug-ins in bulk.
- Builds custom collections from the in-window toolbar.
- Keeps the primary controls inside the app window instead of relying on the macOS menu bar.

## Data

PluginVault stores its local database in:

```text
~/Library/Application Support/PluginVault/database.json
~/Library/Application Support/PluginVault/collections.json
```

Appearance settings are stored in standard macOS user defaults for the app bundle identifier `pluginvault.PluginVault`.

## Development

Run the classic UI guard before shipping UI changes:

```sh
./script/verify_classic_ui.sh
```

Build from Xcode or the command line:

```sh
xcodebuild -project PluginVault.xcodeproj -scheme PluginVault -configuration Debug build
```

Release packaging is currently a local `.app` bundle zipped with `ditto --keepParent`.
