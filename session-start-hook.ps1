# SessionStart hook helper - outputs bootstrap as additionalContext JSON
$bootstrapDir = "$env:USERPROFILE\SmartBrain\bootstrap"
if (-not (Test-Path $bootstrapDir)) { exit 0 }

$latest = Get-ChildItem $bootstrapDir -Filter "session-bootstrap.md" -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1

if (-not $latest) { exit 0 }

$content = [string](Get-Content $latest.FullName -Raw -Encoding UTF8)

@{
    hookSpecificOutput = @{
        hookEventName = "SessionStart"
        additionalContext = $content
    }
} | ConvertTo-Json -Compress -Depth 2
