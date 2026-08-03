#!/usr/bin/env bash
set -euo pipefail

mode="${1:---check}"
course_dir="${AI_GRAD_COURSE_DIR:-$HOME/ai-for-grad-students-workspace}"
agent="${AI_GRAD_AGENT:-}"

log() { printf '[ai-grad] %s\n' "$*"; }
have() { command -v "$1" >/dev/null 2>&1; }
check() {
  log "platform=$(uname -s) arch=$(uname -m)"
  for cmd in code node npm codex claude agy uv pandoc xelatex; do
    if have "$cmd"; then log "PASS $cmd=$($cmd --version 2>/dev/null | head -n 1)"; else log "MISSING $cmd"; fi
  done
  df -Pk "$HOME" | awk 'NR==2 {printf "[ai-grad] free_disk_gb=%.1f\n", $4/1024/1024}'
}
make_workspace() {
  mkdir -p "$course_dir/input" "$course_dir/output"
  if [[ ! -e "$course_dir/content.md" ]]; then
    printf '# My AI Research Workspace\n\nDescribe the research task here.\n' > "$course_dir/content.md"
  fi
  if [[ ! -e "$course_dir/README.md" ]]; then
    printf '# AI for Grad Students\n\nKeep permitted inputs in `input/` and generated work in `output/`.\n' > "$course_dir/README.md"
  fi
  log "workspace=$course_dir"
}
install_tools() {
  [[ "$(uname -s)" == Linux ]] || { log 'This installer requires Linux.'; exit 2; }
  have apt-get || { log 'Only Ubuntu/Debian apt systems are currently supported.'; exit 2; }
  log 'This installs Git, Node.js/npm, Pandoc, XeLaTeX, curl and VS Code (via snap when available).'
  read -r -p 'Continue? [y/N] ' answer
  [[ "$answer" =~ ^[Yy]$ ]] || exit 0
  sudo apt-get update
  sudo apt-get install -y git curl nodejs npm pandoc texlive-xetex
  if ! have code; then
    if have snap; then sudo snap install code --classic; else log 'VS Code still missing: install it from https://code.visualstudio.com/'; fi
  fi
  have uv || curl -LsSf https://astral.sh/uv/install.sh | sh
  if [[ -z "$agent" ]]; then read -r -p 'Choose agent [codex/claude/antigravity]: ' agent; fi
  mkdir -p "$HOME/.local"
  npm config set prefix "$HOME/.local"
  export PATH="$HOME/.local/bin:$PATH"
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
  --install|--repair) install_tools; check ;;
  *) echo "Usage: $0 [--check|--install|--repair]" >&2; exit 2 ;;
esac
