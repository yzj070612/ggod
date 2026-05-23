# ggod Repo Manager — Claude Code automated repository management
# Usage: powershell -ExecutionPolicy Bypass -File repo-manager.ps1 -Action <action> [options]

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("status","pull","push","log","describe","clone")]
    [string]$Action,

    [Parameter(Mandatory=$false)]
    [string]$Message = "Auto: update from Claude Code",

    [Parameter(Mandatory=$false)]
    [string]$Description = "",

    [Parameter(Mandatory=$false)]
    [string]$SourceUrl = "",

    [Parameter(Mandatory=$false)]
    [string]$TargetDir = ""
)

$ErrorActionPreference = "Stop"
$RepoRoot = $PSScriptRoot
$RepoOwner = "yzj070612"
$RepoName = "ggod"

# Token stored in git remote URL — extract or use embedded
function Get-Token {
    $remote = (git -C $RepoRoot remote get-url origin 2>&1)
    if ($remote -match "https://([^@]+)@github.com") {
        return $Matches[1]
    }
    return $null
}

function Invoke-RepoAction {
    switch ($Action) {
        "status" {
            Write-Host "=== ggod Repository Status ===" -ForegroundColor Cyan
            git -C $RepoRoot status
            Write-Host ""
            Write-Host "=== Recent Commits ===" -ForegroundColor Cyan
            git -C $RepoRoot log --oneline -5
            Write-Host ""
            Write-Host "=== Remote ===" -ForegroundColor Cyan
            git -C $RepoRoot remote -v
        }

        "pull" {
            Write-Host "Pulling latest from origin/main..." -ForegroundColor Cyan
            git -C $RepoRoot pull origin main
            Write-Host "Done. Working tree is up to date." -ForegroundColor Green
        }

        "push" {
            Write-Host "Staging all changes..." -ForegroundColor Cyan
            git -C $RepoRoot add -A
            $status = git -C $RepoRoot status --porcelain
            if (-not $status) {
                Write-Host "Nothing to commit." -ForegroundColor Yellow
                return
            }
            Write-Host "Committing: $Message" -ForegroundColor Cyan
            git -C $RepoRoot commit -m "$Message"
            Write-Host "Pushing to origin/main..." -ForegroundColor Cyan
            git -C $RepoRoot push origin main
            Write-Host "Push successful!" -ForegroundColor Green
        }

        "log" {
            $count = if ($Description -match '^\d+$') { [int]$Description } else { 10 }
            git -C $RepoRoot log --oneline -$count
        }

        "describe" {
            # Update repo description via GitHub API
            $token = Get-Token
            if (-not $token) {
                Write-Host "ERROR: Cannot extract token from git remote." -ForegroundColor Red
                exit 1
            }
            $desc = if ($Description) { $Description } else { "Claude Code automated workspace" }
            $body = @{ description = $desc } | ConvertTo-Json -Compress
            Write-Host "Setting repo description to: $desc" -ForegroundColor Cyan
            $result = curl.exe -s -X PATCH `
                -H "Authorization: Bearer $token" `
                -H "Accept: application/vnd.github+json" `
                -H "Content-Type: application/json" `
                -d $body `
                "https://api.github.com/repos/$RepoOwner/$RepoName" 2>&1
            $json = $result | ConvertFrom-Json
            if ($json.description -eq $desc) {
                Write-Host "Description updated successfully!" -ForegroundColor Green
            } else {
                Write-Host "Result: $result" -ForegroundColor Yellow
            }
        }

        "clone" {
            # Clone any public repo into the workspace
            if (-not $SourceUrl) {
                Write-Host "ERROR: -SourceUrl is required for clone action." -ForegroundColor Red
                Write-Host "Example: -Action clone -SourceUrl https://github.com/user/repo.git -TargetDir repo-name" -ForegroundColor Yellow
                exit 1
            }
            $dest = if ($TargetDir) { Join-Path $RepoRoot $TargetDir } else { $RepoRoot }
            Write-Host "Cloning $SourceUrl -> $dest" -ForegroundColor Cyan
            git clone $SourceUrl $dest 2>&1
            Write-Host "Clone complete." -ForegroundColor Green
        }
    }
}

try {
    Invoke-RepoAction
} catch {
    Write-Host "ERROR: $_" -ForegroundColor Red
    exit 1
}
