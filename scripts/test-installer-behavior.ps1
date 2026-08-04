param(
  [Parameter(Mandatory)][ValidateSet('codex','claude','antigravity')][string]$Agent,
  [Parameter(Mandatory)][ValidateSet('present','missing')][string]$State
)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$installer = Join-Path $root 'downloads/setup-windows.ps1'
$selectedCommand = if ($Agent -eq 'antigravity') { 'agy-ide' } else { $Agent }
$commands = @('npm','code','uv')
if ($State -eq 'present') { $commands += $selectedCommand }
$env:AI_RESEARCH_DRY_RUN = '1'
$env:AI_RESEARCH_TEST_COMMANDS = $commands -join ','

$failed = $false
try {
  $output = (& $installer -Mode SetupUser -Agent $Agent 2>&1 6>&1 | Out-String)
} catch {
  $failed = $true
  $output = ($_ | Out-String)
}

function Require([bool]$Condition, [string]$Message) {
  if (-not $Condition) { throw "$Message`n$output" }
}
switch ("${Agent}:${State}") {
  'codex:missing' {
    Require (!$failed -and $output.Contains('DRY_RUN npm install -g @openai/codex') -and $output.Contains('openai.chatgpt')) 'Codex missing behavior failed.'
    Require (!$output.Contains('@anthropic-ai/claude-code')) 'Codex selected but Claude was touched.'
  }
  'codex:present' { Require (!$failed -and $output.Contains('REUSE codex') -and !$output.Contains('DRY_RUN npm install')) 'Codex reuse behavior failed.' }
  'claude:missing' {
    Require (!$failed -and $output.Contains('DRY_RUN npm install -g @anthropic-ai/claude-code') -and $output.Contains('anthropic.claude-code')) 'Claude missing behavior failed.'
    Require (!$output.Contains('@openai/codex')) 'Claude selected but Codex was touched.'
  }
  'claude:present' { Require (!$failed -and $output.Contains('REUSE claude') -and !$output.Contains('DRY_RUN npm install')) 'Claude reuse behavior failed.' }
  'antigravity:missing' { Require (!$failed -and $output.Contains('ANTIGRAVITY_GUI_SETUP') -and !$output.Contains('VS_CODE_EXTENSION')) 'Antigravity missing behavior failed.' }
  'antigravity:present' { Require (!$failed -and $output.Contains('ANTIGRAVITY_EXTENSION mathematic.vscode-pdf') -and !$output.Contains('npm install') -and !$output.Contains('openai.chatgpt') -and !$output.Contains('anthropic.claude-code')) 'Antigravity present behavior failed.' }
}
if (!$failed -and $State -eq 'present') { Require ($output.Contains('mathematic.vscode-pdf')) 'PDF viewer was not installed.' }
Write-Host "PASS installer=windows agent=$Agent state=$State"
