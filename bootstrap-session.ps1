# Session Bootstrap — Packs all context into SmartBrain for Claude Code cold starts
# Run: powershell -ExecutionPolicy Bypass -File bootstrap-session.ps1
# Auto-run via SessionStart hook in settings.local.json

$ErrorActionPreference = "SilentlyContinue"
$BaseDir = "$env:USERPROFILE\SmartBrain"
$BootstrapDir = "$BaseDir\bootstrap"

# Ensure directories
foreach ($d in @($BaseDir, $BootstrapDir)) {
    if (-not (Test-Path $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
}

$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$output = ""

function Write-Block($title, $content) {
    $script:output += "`n## $title`n`n$content`n"
}

# ===== 1. SYSTEM INFO =====
Write-Block "System" @"
- OS: Windows 11 Home China 10.0.26200
- Shell: Bash (Git Bash)
- Home: C:/Users/16781
- Date: $timestamp
"@

# ===== 2. GITHUB REPO =====
$repoPath = "C:/Users/16781/ggod"
if (Test-Path $repoPath) {
    $remote = (git -C $repoPath remote get-url origin 2>&1) -replace 'https://[^@]+@', 'https://***@'
    Write-Block "GitHub Repo" @"
- **Repo**: yzj070612/ggod
- **Local path**: $repoPath
- **Remote**: $remote
- **Token location**: git remote URL (stored in repo config)
- **Description**: Claude Code自动化工作区
"@
}

# ===== 3. INSTALLED PLUGINS =====
$plugins = @()
try {
    $pluginOutput = claude plugin list 2>&1
    $lines = $pluginOutput -split "`n"
    foreach ($line in $lines) {
        if ($line -match '^\s*❯\s+(\S+)') {
            $plugins += $Matches[1]
        }
    }
} catch {}
$pluginText = if ($plugins.Count -gt 0) { ($plugins | ForEach-Object { "- $_" }) -join "`n" } else { "(could not detect - run 'claude plugin list')" }
Write-Block "Installed Plugins" @"
$pluginText
"@

# ===== 4. TOOL SCRIPTS =====
$tools = @{
    "App Launcher" = "C:/Users/16781/app-launcher.ps1"
    "Auto Start" = "C:/Users/16781/setup-autostart.ps1"
    "Web Search" = "C:/Users/16781/web-search.ps1"
    "Smart Brain" = "C:/Users/16781/smart-brain.ps1"
    "Repo Manager" = "C:/Users/16781/ggod/repo-manager.ps1"
    "Bootstrap (this)" = "C:/Users/16781/bootstrap-session.ps1"
}
$toolText = ""
foreach ($kv in $tools.GetEnumerator()) {
    $exists = if (Test-Path $kv.Value) { "[OK]" } else { "[MISSING]" }
    $toolText += "- $exists **$($kv.Name)**: ``$($kv.Value)```n"
}
Write-Block "Tool Scripts" $toolText

# ===== 5. PROJECTS =====
$projects = @{
    "Cave Runner" = "C:/Users/16781/cave-runner.html"
    "Snake Game" = "C:/Users/16781/snake-game.html"
    "SVG Animation" = "C:/Users/16781/svg-animation.html"
    "Penguin Admin" = "C:/Users/16781/penguin-admin.html"
    "Algo Demos" = "C:/Users/16781/algo-demo/"
}
$projText = ""
foreach ($kv in $projects.GetEnumerator()) {
    $exists = if (Test-Path $kv.Value) { "[OK]" } else { "[MISSING]" }
    $projText += "- $exists **$($kv.Name)**: ``$($kv.Value)```n"
}
Write-Block "Projects" $projText

# ===== 6. CONFIG FILES =====
$configs = @{
    "Global Settings" = "C:/Users/16781/.claude/settings.json"
    "Local Settings" = "C:/Users/16781/.claude/settings.local.json"
    "Memory Index" = "C:/Users/16781/.claude/projects/C--Users-16781/memory/MEMORY.md"
}
$confText = ""
foreach ($kv in $configs.GetEnumerator()) {
    $exists = if (Test-Path $kv.Value) { "[OK]" } else { "[-]" }
    $confText += "- $exists **$($kv.Name)**: ``$($kv.Value)```n"
}
Write-Block "Configuration" $confText

# ===== 7. IMPORTANT PATHS =====
Write-Block "Key Paths" @"
- **Python**: C:/Users/16781/AppData/Local/Programs/Python/Python312/python.exe (v3.12.10)
- **Node.js**: available via bash
- **curl.exe**: C:/Windows/System32/curl.exe
- **Claude CLI**: C:/Users/16781/AppData/Roaming/npm/claude.cmd
- **SmartBrain**: $BaseDir
- **ggod repo**: $repoPath
"@

# ===== 8. KNOWN LIMITATIONS =====
Write-Block "Known Issues" @"
- Git clone/push to GitHub fails via git protocol (network RST) — use HTTPS with PAT token
- GitHub raw.githubusercontent.com blocked — use api.github.com for file access
- VSCode extension cannot read any image format (PNG/JPG/SVG all return [Unsupported Image])
- PowerShell encoding issues with Chinese when piped through bash curl — use Node.js for API calls with UTF-8
- `py.exe` launcher not on Git Bash PATH — use full path to python.exe
- gh CLI not installed — use curl + API token for GitHub operations
"@

# ===== WRITE BOOTSTRAP FILE =====
$bootstrapFile = Join-Path $BootstrapDir "session-bootstrap.md"
@"
---
title: "Session Bootstrap — $timestamp"
category: bootstrap
tags: [bootstrap, session-start, system-info]
source: generated-by-bootstrap-script
---

# Claude Code Session Bootstrap

> Auto-generated: $timestamp
> Next session: read this FIRST to restore context

$output
"@ | Set-Content $bootstrapFile -Encoding UTF8

# ===== UPDATE SMARTBRAIN INDEX =====
$indexFile = "$BaseDir\_index.json"
$newEntry = @{
    File = "bootstrap\session-bootstrap.md"
    Title = "Session Bootstrap — $timestamp"
    Category = "bootstrap"
    Tags = @("bootstrap", "session-start", "system-info")
    Source = "bootstrap-session.ps1"
    Created = $timestamp
}
try {
    $index = @()
    if (Test-Path $indexFile) {
        $raw = Get-Content $indexFile -Raw -Encoding UTF8
        if (-not [string]::IsNullOrWhiteSpace($raw)) {
            $data = $raw | ConvertFrom-Json
            if ($data -is [array]) { $index = [System.Collections.ArrayList]::new(); foreach ($i in $data) { $index.Add($i) | Out-Null } }
            else { $index = [System.Collections.ArrayList]::new(); $index.Add($data) | Out-Null }
        }
    }
    if ($index -isnot [System.Collections.ArrayList]) { $index = [System.Collections.ArrayList]::new() }
    # Remove old bootstrap entries
    $toRemove = @()
    for ($i = 0; $i -lt $index.Count; $i++) {
        if ($index[$i].Category -eq "bootstrap") { $toRemove += $i }
    }
    for ($i = $toRemove.Count - 1; $i -ge 0; $i--) {
        $index.RemoveAt($toRemove[$i])
    }
    $index.Add($newEntry) | Out-Null
    $index.ToArray() | ConvertTo-Json -Depth 4 | Set-Content $indexFile -Encoding UTF8
} catch {
    Write-Warning "Failed to update index: $_"
}

Write-Host "=== Bootstrap Complete ===" -ForegroundColor Green
Write-Host "File: $bootstrapFile" -ForegroundColor Cyan
Write-Host "Entries in SmartBrain: $(if($index -is [System.Collections.ArrayList]){$index.Count}else{0})" -ForegroundColor Cyan

# ===== COPY BOOTSTRAP TO GGOD FOR REDUNDANCY =====
if (Test-Path $repoPath) {
    try {
        Copy-Item $bootstrapFile (Join-Path $repoPath "bootstrap-latest.md") -Force
        Write-Host "Synced to ggod repo" -ForegroundColor Cyan
    } catch {}
}
return $bootstrapFile
