#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
bash -n "$root/downloads/setup-linux.sh"
bash -n "$root/downloads/setup-macos.sh"
grep -q "ValidateSet('Check','InstallSystem','SetupUser','Repair')" "$root/downloads/setup-windows.ps1"
grep -q "SetupUser must run in a normal, non-Administrator PowerShell" "$root/downloads/setup-windows.ps1"
for installer in "$root/downloads/setup-windows.ps1" "$root/downloads/setup-macos.sh" "$root/downloads/setup-linux.sh"; do
  grep -q '@openai/codex' "$installer"
  grep -q '@anthropic-ai/claude-code' "$installer"
  grep -q 'antigravity.google/cli/install' "$installer"
done
echo 'Installer static checks passed.'
