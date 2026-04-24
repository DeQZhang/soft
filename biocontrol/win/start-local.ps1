$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot
if (!(Test-Path .env.local)) { Copy-Item .env.local.example .env.local }
  if (Select-String -Path .env.local -Pattern '^BIOCONTROL_HTTP_PORT=' -Quiet) {
    (Get-Content .env.local) -replace '^BIOCONTROL_HTTP_PORT=.*', 'BIOCONTROL_HTTP_PORT=18080' | Set-Content .env.local
  } else {
    Add-Content .env.local "`nBIOCONTROL_HTTP_PORT=18080"
  }
  if (Test-Path biocontrol.pid) {
    $pidValue = Get-Content biocontrol.pid
    Stop-Process -Id $pidValue -Force -ErrorAction SilentlyContinue
    Remove-Item biocontrol.pid -ErrorAction SilentlyContinue
  }
  try {
    Get-NetTCPConnection -LocalPort 18080 -ErrorAction Stop |
      Select-Object -ExpandProperty OwningProcess -Unique |
      ForEach-Object { Stop-Process -Id $_ -Force -ErrorAction SilentlyContinue }
  } catch {}
New-Item -ItemType Directory -Force logs | Out-Null
$proc = Start-Process -FilePath powershell -ArgumentList '-ExecutionPolicy','Bypass','-File','.\\start-local-foreground.ps1' -RedirectStandardOutput logs/biocontrol.log -RedirectStandardError logs/biocontrol.err.log -PassThru
$proc.Id | Set-Content biocontrol.pid
Write-Host "Started BioControl locally, PID=$($proc.Id)"
