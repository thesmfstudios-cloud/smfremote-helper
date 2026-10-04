$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $root
$remote = 'https://github.com/thesmfstudios-cloud/smfremote-helper.git'
if (-not (Test-Path '.git')) { git init | Out-Null; git branch -M main }
if (-not (git remote 2>$null | Select-String '^origin$')) { git remote add origin $remote }
git add -A
$changes = git status --porcelain
if ($changes) {
  $stamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
  git commit -m "Utility update $stamp" | Out-Null
}
try {
  git push -u origin main
  Write-Output 'UTILITY_SYNC_OK'
} catch {
  Write-Output 'UTILITY_SYNC_PENDING_REMOTE_OR_AUTH'
  exit 2
}

