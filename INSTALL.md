# Installing PluginVault Beta

## Install

1. Download `PluginVault-v1.0-beta.1.zip` from the beta release.
2. Double-click the zip file to expand it.
3. Drag `PluginVault.app` into `/Applications`.
4. Launch it from Finder.

If macOS blocks the first launch because the app is not notarized, Control-click `PluginVault.app`, choose `Open`, then confirm the launch.

## Permissions

PluginVault needs file access to the plug-in folders it manages. macOS may ask for permission when the app scans or reveals plug-ins.

The app is not sandboxed. This is intentional for the beta because system plug-in folders live outside a normal sandbox container.

## Before Bulk Vaulting

Back up these folders before using `Vault Untagged` or other bulk vault operations:

```text
/Library/Audio/Plug-Ins
~/Library/Audio/Plug-Ins
```

Vaulting renames plug-in bundle directories by appending `.vaulted`. Unvaulting removes that suffix.

## Uninstall

1. Open PluginVault.
2. Use `Unvault All` if you want every discovered vaulted plug-in restored.
3. Quit the app.
4. Move `PluginVault.app` from `/Applications` to the Trash.

To remove local app data, delete:

```text
~/Library/Application Support/PluginVault
```

You can also clear the app's user defaults:

```sh
defaults delete pluginvault.PluginVault
```
