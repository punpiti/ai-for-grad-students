[CmdletBinding()]
param(
  [ValidateSet('Check','InstallSystem','SetupUser','Repair')][string]$Mode = 'Check',
  [ValidateSet('codex','claude','antigravity')][string]$Agent,
  [string]$CourseDir = (Join-Path $HOME 'ai-for-grad-students-workspace')
)
$ErrorActionPreference = 'Stop'
function Log([string]$Message) { Write-Host "[ai-grad] $Message" }
function Has([string]$Command) { return [bool](Get-Command $Command -ErrorAction SilentlyContinue) }
function Is-Admin {
  $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
  $principal = [Security.Principal.WindowsPrincipal]::new($identity)
  return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}
function Check-Tools {
  $os = Get-CimInstance Win32_OperatingSystem
  Log "windows=$($os.Version) arch=$env:PROCESSOR_ARCHITECTURE"
  foreach ($tool in @('code','node','npm','codex','claude','agy','uv','pandoc','xelatex')) {
    if (Has $tool) { $version = (& $tool --version 2>$null | Select-Object -First 1); Log "PASS $tool=$version" }
    else { Log "MISSING $tool" }
  }
  $drive = Get-PSDrive -Name ([IO.Path]::GetPathRoot($CourseDir).TrimEnd(':\'))
  Log ('free_disk_gb={0:N1}' -f ($drive.Free / 1GB))
}
function New-CourseWorkspace {
  New-Item -ItemType Directory -Force -Path $CourseDir,(Join-Path $CourseDir 'input'),(Join-Path $CourseDir 'output') | Out-Null
  $content = Join-Path $CourseDir 'content.md'
  $readme = Join-Path $CourseDir 'README.md'
  if (-not (Test-Path $content)) { Set-Content -Encoding utf8 $content "# My AI Research Workspace`n`nDescribe the research task here.`n" }
  if (-not (Test-Path $readme)) { Set-Content -Encoding utf8 $readme "# AI for Grad Students`n`nKeep permitted inputs in input/ and generated work in output/.`n" }
  Log "workspace=$CourseDir"
}
function Install-SystemTools {
  if (-not (Is-Admin)) { throw 'InstallSystem requires PowerShell opened with Run as administrator.' }
  if (-not (Has 'winget')) { throw 'WinGet is required. Update App Installer from Microsoft Store and rerun.' }
  Log 'ADMIN PHASE: installs VS Code, Git, Node.js LTS, uv, Pandoc and MiKTeX using WinGet.'
  $answer = Read-Host 'Continue? [y/N]'
  if ($answer -notmatch '^[Yy]$') { return }
  $packages = @(
    'Microsoft.VisualStudioCode', 'Git.Git', 'OpenJS.NodeJS.LTS',
    'astral-sh.uv', 'JohnMacFarlane.Pandoc', 'MiKTeX.MiKTeX'
  )
  foreach ($id in $packages) {
    winget install --id $id --exact --accept-package-agreements --accept-source-agreements --silent
  }
  Log 'System installation finished. This Administrator terminal will close in 5 seconds.'
  Log 'Next: open a normal PowerShell window and run SetupUser. Do not run agents as Administrator.'
  Start-Sleep -Seconds 5
  exit 0
}
function Install-UserTools {
  if (Is-Admin) { throw 'SetupUser must run in a normal, non-Administrator PowerShell. Close this window and open PowerShell normally.' }
  if (-not $Agent) { $Agent = Read-Host 'Choose agent [codex/claude/antigravity]' }
  if (Has 'npm') {
    switch ($Agent) {
      'codex' { if (-not (Has 'codex')) { npm install -g '@openai/codex' } }
      'claude' { if (-not (Has 'claude')) { npm install -g '@anthropic-ai/claude-code' } }
      'antigravity' {
        if (-not (Has 'agy')) {
          $installer = Join-Path $env:TEMP 'antigravity-install.ps1'
          Invoke-WebRequest 'https://antigravity.google/cli/install.ps1' -OutFile $installer
          & $installer
          Remove-Item $installer
        }
      }
    }
  }
  else { Log 'Node/npm was installed but this shell has not refreshed PATH. Reopen PowerShell and rerun with -Mode Repair.' }
  New-CourseWorkspace
}
switch ($Mode) {
  'InstallSystem' { Install-SystemTools }
  'SetupUser' { Install-UserTools }
  'Repair' { if (Is-Admin) { Install-SystemTools } else { Install-UserTools } }
}
Check-Tools
