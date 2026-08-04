#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
page="$root/prepare.html"

for agent in codex claude antigravity; do
  grep -q "name=\"agent\" value=\"$agent\"" "$page"
done
grep -q -- '-Agent {agent}' "$page"

for platform in windows macos linux; do
  grep -q "data-platform-button=\"$platform\"" "$page"
  grep -q "data-platform-panel=\"$platform\"" "$page"
done

grep -q 'SETUP_VERSION 2026.08.05.5' "$page"
grep -q 'FONT_READY' "$page"
grep -q 'CREATE VS_CODE_PROFILE' "$page"
grep -q 'โหลด Script ในข้อ 1 ใหม่ก่อนเสมอ' "$page"
grep -q 'always allow “pandoc”' "$page"
grep -q 'ไม่เลือกอนุญาต shell หรือทุกคำสั่งแบบกว้าง' "$page"
grep -q 'mainfont: Sarabun' "$root/downloads/modern-thai.yaml"
grep -q 'Path=templates/fonts/' "$root/downloads/modern-thai.yaml"

echo 'Prepare page learner-flow checks passed.'
