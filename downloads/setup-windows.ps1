[CmdletBinding()]
param(
  [ValidateSet('Check','InstallSystem','SetupUser','Repair')][string]$Mode = 'Check',
  [ValidateSet('codex','claude','antigravity')][string]$Agent,
  [string]$CourseDir = (Join-Path $HOME 'ai-for-research-workspace')
)
$ErrorActionPreference = 'Stop'
$DryRun = $env:AI_RESEARCH_DRY_RUN -eq '1'
$TestCommands = @($env:AI_RESEARCH_TEST_COMMANDS -split ',' | Where-Object { $_ })
function Log([string]$Message) { Write-Host "[ai-grad] $Message" }
function Has([string]$Command) {
  if ($TestCommands.Count -gt 0) { return $TestCommands -contains $Command }
  return [bool](Get-Command $Command -ErrorAction SilentlyContinue)
}
function Is-Admin {
  if ($DryRun) { return $false }
  $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
  $principal = [Security.Principal.WindowsPrincipal]::new($identity)
  return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}
function Check-Tools {
  $os = Get-CimInstance Win32_OperatingSystem
  $drive = Get-PSDrive -Name ([IO.Path]::GetPathRoot($CourseDir).TrimEnd(':\'))
  $ramGb = [math]::Round($os.TotalVisibleMemorySize / 1MB, 1)
  $diskGb = [math]::Round($drive.Free / 1GB, 1)
  $network = Test-NetConnection -ComputerName github.com -Port 443 -InformationLevel Quiet -WarningAction SilentlyContinue
  $aiTargets = if ($Agent) { @($Agent) } else { @('codex','claude','antigravity') }
  $aiCommands = @{ codex = 'codex'; claude = 'claude'; antigravity = 'agy-ide' }
  $aiTargets = $aiTargets | ForEach-Object { $aiCommands[$_] }
  $availableAi = $aiTargets | Where-Object { Has $_ }
  $missingAi = $aiTargets | Where-Object { -not (Has $_) }
  $availableAiText = if ($availableAi) { $availableAi -join ',' } else { 'none' }
  $missingAiText = if ($missingAi) { $missingAi -join ',' } else { 'none' }
  Log "AI_FRONTENDS available=$availableAiText missing=$missingAiText"
  $osReady = $os.Version -like '10.*' -and [int]$os.BuildNumber -ge 22000
  $archReady = $env:PROCESSOR_ARCHITECTURE -match '64|ARM'
  $issues = @()
  if (-not $osReady) { $issues += 'Windows 11' }
  if (-not $archReady) { $issues += '64-bit architecture' }
  if ($ramGb -lt 8) { $issues += "RAM 8 GB (found $ramGb GB)" }
  if ($diskGb -lt 20) { $issues += "free disk 20 GB (found $diskGb GB)" }
  if (-not $network) { $issues += 'HTTPS network access to github.com' }
  if ($issues.Count -eq 0) { Log 'FINAL_RESULT PASS - Device is ready.'; return $true }
  Log "FINAL_RESULT FAIL - Missing: $($issues -join '; ')"
  return $false
}
function New-CourseWorkspace {
  if ($DryRun) { Log "DRY_RUN workspace=$CourseDir"; return }
  New-Item -ItemType Directory -Force -Path $CourseDir,(Join-Path $CourseDir 'input\original'),(Join-Path $CourseDir 'input\markdown'),(Join-Path $CourseDir 'output'),(Join-Path $CourseDir 'tools') | Out-Null
  $content = Join-Path $CourseDir 'content.md'
  $readme = Join-Path $CourseDir 'README.md'
  if (-not (Test-Path $content)) { Set-Content -Encoding utf8 $content "# My AI Research Workspace`n`nDescribe the research task here.`n" }
  if (-not (Test-Path $readme)) { Set-Content -Encoding utf8 $readme "# AI for Research`n`nKeep permitted inputs in input/ and generated work in output/.`n" }
  $templateDir = Join-Path $CourseDir 'templates'
  New-Item -ItemType Directory -Force -Path $templateDir | Out-Null
  $starterFiles = @(
    @{ Url = 'https://punpiti.github.io/ai-for-research/downloads/modern-thai.yaml'; Path = (Join-Path $templateDir 'modern-thai.yaml') },
    @{ Url = 'https://punpiti.github.io/ai-for-research/downloads/modern-thai.lua'; Path = (Join-Path $templateDir 'modern-thai.lua') },
    @{ Url = 'https://punpiti.github.io/ai-for-research/downloads/modern-thai.tex'; Path = (Join-Path $templateDir 'modern-thai.tex') },
    @{ Url = 'https://punpiti.github.io/ai-for-research/downloads/starter-AGENTS.md'; Path = (Join-Path $CourseDir 'AGENTS.md') },
    @{ Url = 'https://punpiti.github.io/ai-for-research/downloads/import-documents.sh'; Path = (Join-Path $CourseDir 'tools\import-documents.sh') },
    @{ Url = 'https://punpiti.github.io/ai-for-research/downloads/import-documents.ps1'; Path = (Join-Path $CourseDir 'tools\import-documents.ps1') }
  )
  $fontDir = Join-Path $templateDir 'fonts'
  New-Item -ItemType Directory -Force -Path $fontDir | Out-Null
  $starterFiles += @(
    @{ Url = 'https://punpiti.github.io/ai-for-research/downloads/fonts/THSarabunNew.ttf'; Path = (Join-Path $fontDir 'THSarabunNew.ttf') },
    @{ Url = 'https://punpiti.github.io/ai-for-research/downloads/fonts/THSarabunNew-Bold.ttf'; Path = (Join-Path $fontDir 'THSarabunNew-Bold.ttf') },
    @{ Url = 'https://punpiti.github.io/ai-for-research/downloads/fonts/TH-Sarabun-New-License.pdf'; Path = (Join-Path $fontDir 'TH-Sarabun-New-License.pdf') }
  )
  foreach ($file in $starterFiles) { Invoke-WebRequest -UseBasicParsing -Uri $file.Url -OutFile $file.Path }
  Log "workspace=$CourseDir"
}
function Configure-VSCode {
  if (-not (Has 'code')) { Log 'VS Code CLI is not on PATH; reopen PowerShell and rerun SetupUser.'; return }
  $profile = "AI for Research - $Agent"
  $aiExtension = switch ($Agent) {
    'codex' { 'openai.chatgpt' }
    'claude' { 'anthropic.claude-code' }
    'antigravity' { $null }
  }
  $extensions = @('mathematic.vscode-pdf')
  if ($aiExtension) { $extensions = @($aiExtension) + $extensions }
  foreach ($extension in $extensions) {
    Log "INSTALL VS_CODE_EXTENSION $extension profile=$profile"
    if ($DryRun) { Log "DRY_RUN code --profile $profile --install-extension $extension" } else { code --profile $profile --install-extension $extension }
  }
  $vscodeDir = Join-Path $CourseDir '.vscode'
  New-Item -ItemType Directory -Force -Path $vscodeDir | Out-Null
  @{ recommendations = $extensions } | ConvertTo-Json | Set-Content -Encoding utf8 (Join-Path $vscodeDir 'extensions.json')
}
function Configure-Antigravity {
  $extension = 'mathematic.vscode-pdf'
  if (Has 'agy-ide') {
    Log "INSTALL ANTIGRAVITY_EXTENSION $extension"
    if ($DryRun) { Log "DRY_RUN agy-ide --install-extension $extension" } else { agy-ide --install-extension $extension }
  }
  else {
    Log "ANTIGRAVITY_GUI_SETUP Open Antigravity IDE, open folder $CourseDir, then install extension $extension from Extensions. The agy-ide command is optional."
  }
  $vscodeDir = Join-Path $CourseDir '.vscode'
  if (-not $DryRun) {
    New-Item -ItemType Directory -Force -Path $vscodeDir | Out-Null
    @{ recommendations = @($extension) } | ConvertTo-Json | Set-Content -Encoding utf8 (Join-Path $vscodeDir 'extensions.json')
  }
}
function Install-SystemTools {
  if (-not (Is-Admin)) { throw 'InstallSystem requires PowerShell opened with Run as administrator.' }
  if (-not $Agent) { throw 'InstallSystem requires -Agent codex, claude, or antigravity.' }
  if (-not (Check-Tools)) { throw 'INSTALL_STOPPED System requirements did not pass. Nothing was installed.' }
  if (-not (Has 'winget')) { throw 'WinGet is required. Update App Installer from Microsoft Store and rerun.' }
  Log "ADMIN PHASE: checks the selected workspace, document, PDF and Thai-English OCR tools; installs only missing items. agent=$Agent"
  $answer = Read-Host 'Continue? [y/N]'
  if ($answer -notmatch '^[Yy]$') { return }
  $packages = @(
    @{ Command = 'git'; Package = 'Git.Git' },
    @{ Command = 'node'; Package = 'OpenJS.NodeJS.LTS' },
    @{ Command = 'uv'; Package = 'astral-sh.uv' },
    @{ Command = 'pandoc'; Package = 'JohnMacFarlane.Pandoc' },
    @{ Command = 'xelatex'; Package = 'MiKTeX.MiKTeX' },
    @{ Command = 'tesseract'; Package = 'tesseract-ocr.tesseract' },
    @{ Command = 'pdftotext'; Package = 'oschwartz10612.Poppler' }
  )
  if ($Agent -ne 'antigravity') { $packages = @(@{ Command = 'code'; Package = 'Microsoft.VisualStudioCode' }) + $packages }
  foreach ($item in $packages) {
    if (Has $item.Command) { Log "REUSE $($item.Command)"; continue }
    Log "INSTALL $($item.Package)"
    winget install --id $item.Package --exact --accept-package-agreements --accept-source-agreements --silent
  }
  $tesseractCommand = Get-Command tesseract -ErrorAction SilentlyContinue
  $tesseractRoot = if ($tesseractCommand) { Split-Path $tesseractCommand.Source } else { Join-Path $env:ProgramFiles 'Tesseract-OCR' }
  $tessdataDir = Join-Path $tesseractRoot 'tessdata'
  $thaiData = Join-Path $tessdataDir 'tha.traineddata'
  if (-not (Test-Path $thaiData)) {
    New-Item -ItemType Directory -Force -Path $tessdataDir | Out-Null
    Log 'INSTALL Tesseract Thai language data'
    Invoke-WebRequest -UseBasicParsing -Uri 'https://github.com/tesseract-ocr/tessdata_fast/raw/main/tha.traineddata' -OutFile $thaiData
  } else { Log 'REUSE Tesseract Thai language data' }
  if ($Agent -eq 'antigravity' -and -not (Has 'agy-ide')) {
    Log 'INSTALL Antigravity IDE from the official Google download page; complete its installer before SetupUser.'
    Start-Process 'https://antigravity.google/download#antigravity-ide'
  }
  Log 'System installation finished. This Administrator terminal will close in 5 seconds.'
  Log 'Next: open a normal PowerShell window and run SetupUser. Do not run agents as Administrator.'
  Start-Sleep -Seconds 5
  exit 0
}
function Install-UserTools {
  if (Is-Admin) { throw 'SetupUser must run in a normal, non-Administrator PowerShell. Close this window and open PowerShell normally.' }
  if (-not $Agent) { $Agent = Read-Host 'Choose AI frontend [codex/claude/antigravity]' }
  if (Has 'npm') {
    switch ($Agent) {
      'codex' { if (Has 'codex') { Log 'REUSE codex' } else { Log 'INSTALL codex'; if ($DryRun) { Log 'DRY_RUN npm install -g @openai/codex' } else { npm install -g '@openai/codex' } } }
      'claude' { if (Has 'claude') { Log 'REUSE claude' } else { Log 'INSTALL claude'; if ($DryRun) { Log 'DRY_RUN npm install -g @anthropic-ai/claude-code' } else { npm install -g '@anthropic-ai/claude-code' } } }
      'antigravity' { if (-not (Has 'agy-ide')) { Log 'Antigravity will be opened through its desktop IDE; agy-ide is not required for workspace setup.' } }
    }
  }
  else { Log 'Node/npm was installed but this shell has not refreshed PATH. Reopen PowerShell and rerun with -Mode Repair.' }
  New-CourseWorkspace
  if ($Agent -eq 'antigravity') { Configure-Antigravity } else { Configure-VSCode }
  Log "AI workspace=$Agent installed. Next: open the workspace, open its AI panel, and sign in with your own account. The terminal command is only a fallback."
}
switch ($Mode) {
  'InstallSystem' { Install-SystemTools }
  'SetupUser' { Install-UserTools }
  'Repair' { if (Is-Admin) { Install-SystemTools } else { Install-UserTools } }
}
if (($Mode -eq 'Check' -or $Mode -eq 'SetupUser') -and -not $DryRun) { [void](Check-Tools) }
