param([Parameter(Mandatory=$true)][string]$Action)
$Base = Split-Path -Parent $MyInvocation.MyCommand.Path
$Registry = Get-Content (Join-Path $Base 'actions.json') -Raw | ConvertFrom-Json
$LogFile = Join-Path $Base 'history.log'
Add-Type @'
using System;
using System.Runtime.InteropServices;
public class Win32 {
 [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
 [DllImport("user32.dll")] public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);
 [DllImport("user32.dll")] public static extern bool SetWindowPos(IntPtr hWnd, IntPtr hWndInsertAfter, int X, int Y, int cx, int cy, uint uFlags);
}
'@
function Write-Log([string]$Name,[string]$Result){
  Add-Content -Path $LogFile -Value ("{0}`t{1}`t{2}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'),$Name,$Result)
}
function Focus-Chrome {
  $p = Get-Process chrome -ErrorAction SilentlyContinue | Where-Object {$_.MainWindowHandle -ne 0} | Sort-Object StartTime -Descending | Select-Object -First 1
  if($p){
    [Win32]::ShowWindowAsync($p.MainWindowHandle,3) | Out-Null
    [Win32]::SetWindowPos($p.MainWindowHandle,[IntPtr](-1),0,0,0,0,0x0001 -bor 0x0002 -bor 0x0040) | Out-Null
    Start-Sleep -Milliseconds 250
    [Win32]::SetForegroundWindow($p.MainWindowHandle) | Out-Null
    [Win32]::SetWindowPos($p.MainWindowHandle,[IntPtr](-2),0,0,0,0,0x0001 -bor 0x0002 -bor 0x0040) | Out-Null
    return $true
  }
  return $false
}
function Open-Url([string]$Url){
  $Chrome = @("$env:ProgramFiles\Google\Chrome\Application\chrome.exe","${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe","$env:LOCALAPPDATA\Google\Chrome\Application\chrome.exe") | Where-Object {Test-Path $_} | Select-Object -First 1
  if($Chrome){ Start-Process $Chrome -ArgumentList $Url } else { Start-Process $Url }
  Start-Sleep -Milliseconds 900
  Focus-Chrome | Out-Null
}
function Run-Action([string]$Name){
  $item = $Registry.PSObject.Properties[$Name].Value
  if($null -eq $item){ throw "Unknown action: $Name" }
  switch($item.type){
    'url' { Open-Url $item.value }
    'folder' { Start-Process explorer.exe -ArgumentList ('"'+$item.value+'"') }
    'focus' { if($item.value -eq 'chrome'){ Focus-Chrome | Out-Null } }
    'sequence' { foreach($child in $item.value){ Run-Action $child } }
    default { throw "Unsupported action type: $($item.type)" }
  }
}
try { Run-Action $Action; Write-Log $Action 'OK'; Write-Output "SMF_REMOTE_OK=$Action" }
catch { Write-Log $Action ("ERROR: "+$_.Exception.Message); Write-Error $_; exit 1 }
