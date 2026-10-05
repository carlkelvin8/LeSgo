# Install git hooks for the LeSGo project
# Run this once after cloning the repo: .\scripts\install-hooks.ps1

$HooksDir = Join-Path $PSScriptRoot "..\.git\hooks"
$SourceHook = Join-Path $PSScriptRoot "..\git-hooks\pre-commit"

if (-not (Test-Path $HooksDir)) {
    New-Item -ItemType Directory -Path $HooksDir -Force | Out-Null
}

# Copy pre-commit hook
$PreCommitSource = @"
#!/bin/sh
# LeSGo Pre-commit Hook - Checks for secrets and common issues

echo "Running pre-commit checks..."

STAGED_FILES=`$(git diff --cached --name-only --diff-filter=ACM)

# Block .env files
if echo "`$STAGED_FILES" | grep -E '\.env`$' | grep -v '.example'; then
    echo "ERROR: .env file in commit! Use .env.example instead."
    exit 1
fi

# Block obvious secrets
if echo "`$STAGED_FILES" | xargs grep -l -E '(TWILIO_AUTH_TOKEN|AWS_SECRET|DB_PASSWORD)=[A-Za-z0-9]' 2>/dev/null | grep -v '.example'; then
    echo "ERROR: Secrets detected in staged files!"
    exit 1
fi

echo "Pre-commit checks passed."
exit 0
"@

Set-Content -Path (Join-Path $HooksDir "pre-commit") -Value $PreCommitSource -NoNewline
Write-Host "Git hooks installed successfully." -ForegroundColor Green
