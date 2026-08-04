#!/usr/bin/env bash
set -euo pipefail

installer="${1:?installer path required}"
agent="${2:?agent required}"
state="${3:?state required}"
commands='npm,code,uv'
selected_command="$agent"
[[ "$agent" == antigravity ]] && selected_command=agy-ide
[[ "$state" == present ]] && commands="$commands,$selected_command"

set +e
output="$(AI_RESEARCH_DRY_RUN=1 AI_RESEARCH_TEST_COMMANDS="$commands" AI_GRAD_AGENT="$agent" \
  AI_RESEARCH_COURSE_DIR="${TMPDIR:-/tmp}/ai-research-behavior-test" \
  bash "$installer" --setup-user 2>&1)"
status=$?
set -e
workspace_line="$(grep -n -m1 'DRY_RUN workspace=' <<<"$output" | cut -d: -f1)"
agent_line="$(grep -n -m1 -E 'REUSE (codex|claude)|INSTALL (codex|claude)|Install Antigravity IDE|INSTALL ANTIGRAVITY_EXTENSION' <<<"$output" | cut -d: -f1)"
[[ -n "$workspace_line" && -n "$agent_line" && $workspace_line -lt $agent_line ]]
if [[ "$state" == present || "$agent" != antigravity ]]; then
  [[ "$output" == *'mathematic.vscode-pdf'* ]]
fi

case "$agent:$state" in
  codex:missing)
    [[ $status -eq 0 && "$output" == *'DRY_RUN npm install -g @openai/codex'* && "$output" == *'openai.chatgpt'* ]]
    [[ "$output" != *'@anthropic-ai/claude-code'* ]]
    ;;
  codex:present) [[ $status -eq 0 && "$output" == *'REUSE codex'* && "$output" != *'DRY_RUN npm install'* ]] ;;
  claude:missing)
    [[ $status -eq 0 && "$output" == *'DRY_RUN npm install -g @anthropic-ai/claude-code'* && "$output" == *'anthropic.claude-code'* ]]
    [[ "$output" != *'@openai/codex'* ]]
    ;;
  claude:present) [[ $status -eq 0 && "$output" == *'REUSE claude'* && "$output" != *'DRY_RUN npm install'* ]] ;;
  antigravity:missing) [[ $status -ne 0 && "$output" == *'Install Antigravity IDE'* && "$output" != *'VS_CODE_EXTENSION'* ]] ;;
  antigravity:present) [[ $status -eq 0 && "$output" == *'ANTIGRAVITY_EXTENSION mathematic.vscode-pdf'* && "$output" != *'npm install'* && "$output" != *'openai.chatgpt'* && "$output" != *'anthropic.claude-code'* ]] ;;
  *) echo "Unknown case: $agent/$state" >&2; exit 2 ;;
esac

printf 'PASS installer=%s agent=%s state=%s\n' "$installer" "$agent" "$state"
