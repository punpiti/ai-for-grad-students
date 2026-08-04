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
grep -q 'mainfont: Sarabun' "$root/downloads/modern-thai.yaml"
grep -q 'Path=templates/fonts/' "$root/downloads/modern-thai.yaml"
grep -q 'always allow the exact `pandoc` executable' "$root/downloads/starter-AGENTS.md"
for font_file in Sarabun-Regular.ttf Sarabun-Bold.ttf OFL.txt; do
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
grep -q 'OPEN ANTIGRAVITY_WORKSPACE' "$root/downloads/setup-macos.sh"
grep -q 'คำตอบเปลี่ยนอย่างไรเมื่อกำหนดหลักฐานให้ชัด' "$root/module-2.html"
grep -q 'ช่วงที่ 1 · ดูคำตอบก่อนกำหนดกติกา' "$root/module-2.html"
grep -q 'ช่วงที่ 2 · ตรวจคำตอบกับต้นฉบับ' "$root/module-2.html"
grep -q 'ช่วงที่ 3 · ปรับคำสั่งแล้วเปรียบเทียบผล' "$root/module-2.html"
grep -q 'ขั้นนี้ไม่มี Prompt ให้คัดลอก' "$root/module-2.html"
grep -q 'ข้อความด้านล่างเป็นคำสั่งสร้างชิ้นงาน' "$root/module-2.html"
if grep -q 'อย่าเพิ่งใช้ Prompt ที่ดี' "$root/module-2.html"; then
  echo 'Module 2 activity must use learner-facing language.' >&2
  exit 1
fi
grep -q 'Recommended 2–3 hours' "$root/module-3.html"
grep -q 'Evidence Boundary' "$root/module-3.html"
grep -q 'Candidate Gap' "$root/module-3.html"
grep -q 'Gap Prosecutor' "$root/module-3.html"
grep -q 'หิว → กิน → อิ่ม' "$root/module-3.html"
grep -q 'ลองหักล้างตัวอย่าง' "$root/module-3.html"
[[ "$(grep -o 'ตัวอย่างหิว–กิน–อิ่ม:' "$root/module-3.html" | wc -l)" -ge 12 ]]
grep -q 'href="hunger-research-methodology.html"' "$root/module-3.html"
grep -q 'Research Methodology Review' "$root/hunger-research-methodology.html"
grep -q 'Problem Definition' "$root/hunger-research-methodology.html"
grep -q 'Constraint &amp; Scope' "$root/hunger-research-methodology.html"
grep -q 'Variable, Indicator &amp; Decision' "$root/hunger-research-methodology.html"
grep -q 'สร้างแล้วต้องพยายามหักล้าง' "$root/hunger-research-methodology.html"
grep -q 'output/problem-gap-rq.md' "$root/module-3.html"
grep -q 'การเตรียมตัวก่อนเรียน' "$root/module-3.html"
grep -q 'สิ่งที่ต้องเตรียมก่อนเรียน' "$root/module-3.html"
if grep -q 'Standalone แต่ต่อยอดได้' "$root/module-3.html"; then
  echo 'Module 3 preparation must use learner-facing language.' >&2
  exit 1
fi
grep -q 'ทาง A · เรียนต่อจาก Module 2' "$root/module-3.html"
grep -q 'ทาง B · เริ่มจาก Module 3' "$root/module-3.html"
grep -q 'ขั้นที่ 2 · จุดนัดพบ' "$root/module-3.html"
grep -q 'ขั้นที่ 3 · กิจกรรมร่วม' "$root/module-3.html"
grep -q 'href="module-3.html"' "$root/index.html"
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
  grep -q 'Sarabun-Regular.ttf' "$installer"
  grep -q 'Sarabun-Bold.ttf' "$installer"
  grep -q 'FONT_READY Sarabun Regular/Bold bundled in workspace' "$installer"
  grep -q 'FONT_SETUP_FAILED' "$installer"
  grep -q 'CREATE VS_CODE_PROFILE' "$installer"
  grep -q 'SETUP_VERSION' "$installer"
  grep -q 'PREREQUISITE_MISSING' "$installer"
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
bash "$root/scripts/test-prepare-page.sh"
if rg -n --glob '!test-installers.sh' 'gemini|Gemini CLI|@google/gemini-cli' "$root"; then
  echo 'Obsolete Gemini CLI reference found.' >&2
  exit 1
fi
echo 'Installer static checks passed.'
