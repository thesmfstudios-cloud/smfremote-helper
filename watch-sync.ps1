$ErrorActionPreference = 'SilentlyContinue'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$sync = Join-Path $root 'sync.ps1'
$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = $root
$watcher.IncludeSubdirectories = $true
$watcher.EnableRaisingEvents = $true
$watcher.NotifyFilter = [IO.NotifyFilters]'FileName, DirectoryName, LastWrite, Size'
$lastRun = [datetime]::MinValue
$action = {
  $path = $Event.SourceEventArgs.FullPath
  if ($path -match '\\.git\\' -or $path -match 'history\.log$' -or $path -match '\.log$') { return }
  $now = Get-Date
  if (($now - $script:lastRun).TotalSeconds -lt 5) { return }
  $script:lastRun = $now
  Start-Sleep -Seconds 2
  & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $using:sync | Out-Null
}
Register-ObjectEvent $watcher Changed -Action $action | Out-Null
Register-ObjectEvent $watcher Created -Action $action | Out-Null
Register-ObjectEvent $watcher Deleted -Action $action | Out-Null
Register-ObjectEvent $watcher Renamed -Action $action | Out-Null
while ($true) { Start-Sleep -Seconds 30 }
