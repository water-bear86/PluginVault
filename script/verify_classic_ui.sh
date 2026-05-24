#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

failures=0

check_absent() {
  local file="$1"
  local pattern="$2"
  local reason="$3"

  if [[ -f "$file" ]] && rg --quiet "$pattern" "$file"; then
    printf 'FAIL: %s contains %s (%s)\n' "$file" "$pattern" "$reason"
    failures=$((failures + 1))
  fi
}

check_present() {
  local file="$1"
  local pattern="$2"
  local reason="$3"

  if ! rg --quiet "$pattern" "$file"; then
    printf 'FAIL: %s is missing %s (%s)\n' "$file" "$pattern" "$reason"
    failures=$((failures + 1))
  fi
}

check_absent "PluginVault/Views/DetailView.swift" "struct InsetBorder|TagFlowLayout|(^|[^A-Za-z])TextField\\(|Menu \\{|(^|[^A-Za-z])Button\\(" "detail view should use shared classic controls"
check_absent "PluginVault/Views/TagBadge.swift" "Capsule|RoundedRectangle|Color\\.secondary|foregroundStyle" "tag badges should not use modern capsule styling"
check_absent "PluginVault/Views/SidebarView.swift" "struct ClassicTagBadge" "tag badge implementation should not be duplicated in the sidebar"
check_absent "PluginVault/Views/CreateCollectionView.swift" "Picker\\(" "collection dialog should not use native modern picker chrome"
check_absent "PluginVault/Views/CreateCollectionView.swift" "HSplitView" "collection dialog should not use native split-view chrome"
check_absent "PluginVault/Views/CreateCollectionView.swift" "ClassicCheckbox\\(isOn: \\.constant" "collection rows should not nest checkbox buttons inside row buttons"
check_absent "PluginVault/Views/CreateCollectionView.swift" "Text\\(\"No plugins\"\\)|\\.italic\\(\\)" "collection dialog should not render a decorative empty-state overlay"
check_absent "PluginVault/PluginVaultApp.swift" "Picker\\(" "settings dialog should not use native modern picker chrome"
check_absent "PluginVault/PluginVaultApp.swift" "\\.alert\\(" "settings confirmations should use the shared classic alert"
check_absent "PluginVault/Views/ContentView.swift" "\\.alert\\(" "app alerts should use the shared classic alert"
check_absent "PluginVault/Views/ContentView.swift" "\\.sheet\\(" "plugin detail and collection dialogs should stay in-window with classic chrome"
check_absent "PluginVault/PluginVaultApp.swift" "CommandMenu\\(\"Collections\"\\)|Create Collection\\.\\.\\." "collection creation should live in the in-window toolbar, not the macOS menu bar"
check_absent "PluginVault.xcodeproj/project.pbxproj" "ENABLE_APP_SANDBOX = YES" "packaged beta must match the app's full-access plug-in management model"
check_absent "PluginVault/Views/ContentView.swift" "Color\\.yellow|Color\\.green|Circle\\(" "status should not rely on modern color-only dots"
check_absent "PluginVault/Styles/ClassicMacStyles.swift" "ClassicButtonBorder\\(isPressed: isExpanded\\)" "popup button should not reuse bulky push-button bevel"
check_absent "PluginVault/Styles/ClassicMacStyles.swift" "\\.shadow\\(" "classic modal surfaces should draw a hard backplate instead of shadowing every child"
check_absent "PluginVault/Styles/ClassicMacStyles.swift" "Color\\.black\\.opacity\\(0\\.001\\)" "classic modal hit-testing should not render a visible black backdrop"
check_absent "PluginVault/Models/PluginManager.swift" "FileManager\\.default\\.moveItem" "vaulting should use the guarded rename-only path"

check_present "PluginVault/Views/ContentView.swift" "ClassicButton\\(\"Create Collection\"" "create collection action should be in the classic window toolbar"
check_present "PluginVault/Styles/ClassicMacStyles.swift" "struct ClassicPopupButton" "classic pop-up control should be centralized"
check_present "PluginVault/Styles/ClassicMacStyles.swift" "struct ClassicPopupBorder" "classic pop-up border should be square and purpose-built"
check_present "PluginVault/Styles/ClassicMacStyles.swift" "struct ClassicAlertDialog" "classic alert dialog should be centralized"
check_present "PluginVault/Styles/ClassicMacStyles.swift" "struct ClassicTagBadge" "classic tag badge should be centralized"
check_present "PluginVault/Styles/ClassicMacStyles.swift" "struct ClassicStatusIndicator" "status indicator should be centralized"
check_present "PluginVault/Models/PluginManager.swift" "clearFinderTagsForLoadedPlugins\\(\\)" "reset should clear Finder tags before deleting local app data"
check_present "PluginVault/Models/Plugin.swift" "static let vaultSuffix = \"\\.vault\"" "new vault suffix should be .vault"
check_present "PluginVault/Models/Plugin.swift" "legacyVaultSuffixes = \\[\"\\.vaulted\"\\]" "older .vaulted plug-ins should remain restorable"
check_present "PluginVault/Models/PluginManager.swift" "validateVaultRename" "vaulting should validate same-folder suffix-only renames"
check_present "PluginVault/Models/PluginManager.swift" "Darwin\\.rename" "normal vaulting should use filesystem rename semantics"
check_present "PluginVault/Models/PluginManager.swift" "with administrator privileges" "protected system plug-ins should offer an admin-authorized rename"
check_present "PluginVault.xcodeproj/project.pbxproj" "MACOSX_DEPLOYMENT_TARGET = 11\\.0;" "the app should be backported to macOS 11"

if (( failures > 0 )); then
  printf '\n%d classic UI verification check(s) failed.\n' "$failures"
  exit 1
fi

printf 'Classic UI verification passed.\n'
