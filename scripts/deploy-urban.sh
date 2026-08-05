#!/usr/bin/env bash
set -Eeuo pipefail
site_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
remote_host="${REMOTE_HOST:-punpiti@urban.cpe.ku.ac.th}"
remote_base="${REMOTE_BASE:-/home/punpiti/ai_for_research_site}"
ssh_config_file="${SSH_CONFIG_FILE:-/dev/null}"
connect_timeout="${SSH_CONNECT_TIMEOUT:-10}"
timestamp="$(date +%Y%m%d_%H%M%S)"
release_dir="${remote_base}/releases/${timestamp}"
ssh_opts=(-F "$ssh_config_file" -o StrictHostKeyChecking=accept-new -o BatchMode=yes -o ConnectTimeout="$connect_timeout")
for item in ssh rsync curl node git tar; do command -v "$item" >/dev/null 2>&1 || { echo "ERROR: missing $item" >&2; exit 1; }; done
cd "$site_root"
bash scripts/audit-public.sh
bash scripts/test-learner-content.sh
bash scripts/test-prepare-page.sh
node --check assets/site-shell.js
node --check assets/course-cart.js
node --check assets/checkout.js
stage_dir="$(mktemp -d)"
trap 'rm -rf "$stage_dir"' EXIT
git archive --format=tar HEAD | tar -xf - -C "$stage_dir"
ssh "${ssh_opts[@]}" "$remote_host" "mkdir -p '$remote_base/releases' '$release_dir'"
rsync -avz --delete -e "ssh -F $ssh_config_file -o StrictHostKeyChecking=accept-new -o BatchMode=yes -o ConnectTimeout=$connect_timeout" "$stage_dir/" "$remote_host:$release_dir/"
ssh "${ssh_opts[@]}" "$remote_host" "test -f '$release_dir/index.html' && test -f '$release_dir/checkout.html' && test -f '$release_dir/downloads/setup-windows.ps1' && ln -sfn '$release_dir' '$remote_base/current'"
echo "Static release active: $release_dir"
