#!/usr/bin/env bash
set -euo pipefail

mode="${1:---check}"
course_dir="${AI_GRAD_COURSE_DIR:-$HOME/ai-for-grad-students-workspace}"
agent="${AI_GRAD_AGENT:-}"
log() { printf '[ai-grad] %s\n' "$*"; }
have() { command -v "$1" >/dev/null 2>&1; }
check() {
  [[ "$(uname -s)" == Darwin ]] || { log 'FAIL This script requires macOS.'; return 2; }
  log "macos=$(sw_vers -productVersion) arch=$(uname -m)"
  for cmd in code node npm codex claude agy uv pandoc xelatex; do
    if have "$cmd"; then log "PASS $cmd=$($cmd --version 2>/dev/null | head -n 1)"; else log "MISSING $cmd"; fi
  done
  df -Pk "$HOME" | awk 'NR==2 {printf "[ai-grad] free_disk_gb=%.1f\n", $4/1024/1024}'
}
make_workspace() {
  mkdir -p "$course_dir/input" "$course_dir/output"
  [[ -e "$course_dir/content.md" ]] || printf '# My AI Research Workspace\n\nDescribe the research task here.\n' > "$course_dir/content.md"
  [[ -e "$course_dir/README.md" ]] || printf '# AI for Grad Students\n\nKeep permitted inputs in `input/` and generated work in `output/`.\n' > "$course_dir/README.md"
  log "workspace=$course_dir"
}
install_system_tools() {
  [[ "$(uname -s)" == Darwin ]] || { log 'This installer requires macOS.'; exit 2; }
  have brew || { log 'Homebrew is required but will not be installed silently. Install it from https://brew.sh/ and rerun.'; exit 2; }
  log 'This uses Homebrew to install VS Code, Node.js, uv, Pandoc and BasicTeX. It does not install Rosetta.'
  read -r -p 'Continue? [y/N] ' answer
  [[ "$answer" =~ ^[Yy]$ ]] || exit 0
  brew install node uv pandoc
  brew install --cask visual-studio-code basictex
  log 'System installation finished. Close this terminal, open Terminal normally, then run --setup-user.'
}
setup_user() {
  if [[ -z "$agent" ]]; then read -r -p 'Choose agent [codex/claude/antigravity]: ' agent; fi
  case "$agent" in
    codex) have codex || npm install -g @openai/codex ;;
    claude) have claude || npm install -g @anthropic-ai/claude-code ;;
    antigravity) have agy || curl -fsSL https://antigravity.google/cli/install.sh | bash ;;
    *) log 'Agent must be codex, claude, or antigravity.'; exit 2 ;;
  esac
  make_workspace
}
case "$mode" in
  --check) check ;;
  --install-system) install_system_tools ;;
  --setup-user) setup_user; check ;;
  --repair) install_system_tools; setup_user; check ;;
  *) echo "Usage: $0 [--check|--install-system|--setup-user|--repair]" >&2; exit 2 ;;
esac
