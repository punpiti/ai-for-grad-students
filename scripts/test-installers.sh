#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
bash -n "$root/downloads/setup-linux.sh"
bash -n "$root/downloads/setup-macos.sh"
bash -n "$root/downloads/import-documents.sh"
grep -q -- '--install-system|--setup-user' "$root/downloads/setup-linux.sh"
grep -q -- '--install-system|--setup-user' "$root/downloads/setup-macos.sh"
grep -q "ValidateSet('Check','InstallSystem','SetupUser','Repair')" "$root/downloads/setup-windows.ps1"
grep -q "SetupUser must run in a normal, non-Administrator PowerShell" "$root/downloads/setup-windows.ps1"
grep -q "InstallSystem requires -Agent codex, claude, or antigravity" "$root/downloads/setup-windows.ps1"
grep -q -- '-Mode InstallSystem -Agent {agent}' "$root/prepare.html"
[[ "$(grep -c 'AI_GRAD_AGENT={agent}.*--install-system' "$root/prepare.html")" -eq 2 ]]
grep -q 'setPreference("ai-research-platform"' "$root/assets/app.js"
grep -q 'setPreference("ai-research-agent"' "$root/assets/app.js"
grep -q 'return getCookie(name) || localStorage.getItem(name)' "$root/assets/app.js"
grep -q 'cd.*ai-for-research-workspace' "$root/prepare.html"
grep -q 'data-workspace-app' "$root/assets/app.js"
grep -q 'data-workspace-open-command' "$root/assets/app.js"
grep -q 'data-agent-panel' "$root/assets/app.js"
grep -q 'mainfont: THSarabunNew' "$root/downloads/modern-thai.yaml"
grep -q 'Path=templates/fonts/' "$root/downloads/modern-thai.yaml"
grep -q 'always allow the exact `pandoc` executable' "$root/downloads/starter-AGENTS.md"
for font_file in THSarabunNew.ttf THSarabunNew-Bold.ttf TH-Sarabun-New-License.pdf; do
  [[ -s "$root/downloads/fonts/$font_file" ]]
done
grep -q 'pdf-engine: xelatex' "$root/downloads/modern-thai.yaml"
grep -q 'BrandBlue' "$root/downloads/modern-thai.lua"
grep -q 'BrandTeal' "$root/downloads/modern-thai.tex"
grep -q -- '--defaults templates/modern-thai.yaml' "$root/downloads/starter-AGENTS.md"
grep -q 'input/original/' "$root/downloads/starter-AGENTS.md"
grep -q 'input/markdown/' "$root/downloads/starter-AGENTS.md"
grep -q 'tesseract.*tha+eng' "$root/downloads/import-documents.sh"
grep -q 'pdftotext' "$root/downloads/import-documents.sh"
grep -q 'L1–L4' "$root/module-2.html"
grep -q 'first-ai-research-task.pdf' "$root/module-2.html"
if grep -q 'data-agent-launch' "$root/prepare.html"; then
  echo 'Primary readiness flow must use the in-editor AI panel, not launch a CLI.' >&2
  exit 1
fi
for installer in "$root/downloads/setup-windows.ps1" "$root/downloads/setup-macos.sh" "$root/downloads/setup-linux.sh"; do
  grep -q '@openai/codex' "$installer"
  grep -q '@anthropic-ai/claude-code' "$installer"
  grep -q 'antigravity.google/download#antigravity-ide' "$installer"
  grep -q 'agy-ide' "$installer"
  grep -q 'openai.chatgpt' "$installer"
  grep -q 'anthropic.claude-code' "$installer"
  grep -q 'mathematic.vscode-pdf' "$installer"
  grep -q 'modern-thai.yaml' "$installer"
  grep -q 'modern-thai.tex' "$installer"
  grep -q 'THSarabunNew.ttf' "$installer"
  grep -q 'THSarabunNew-Bold.ttf' "$installer"
  grep -q 'starter-AGENTS.md' "$installer"
  grep -q 'import-documents.sh' "$installer"
  grep -q 'import-documents.ps1' "$installer"
  grep -qi 'tesseract' "$installer"
  grep -qi 'poppler\|pdftotext' "$installer"
  grep -q 'AI for Research - ' "$installer"
  grep -q 'extensions.json' "$installer"
  grep -q 'AI_FRONTENDS available=' "$installer"
  grep -q 'FINAL_RESULT PASS' "$installer"
  grep -q 'FINAL_RESULT FAIL' "$installer"
  grep -q 'INSTALL_STOPPED' "$installer"
  grep -q 'REUSE' "$installer"
  grep -q 'INSTALL' "$installer"
done
if rg -n --glob '!test-installers.sh' 'gemini|Gemini CLI|@google/gemini-cli' "$root"; then
  echo 'Obsolete Gemini CLI reference found.' >&2
  exit 1
fi
echo 'Installer static checks passed.'
