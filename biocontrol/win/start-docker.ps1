$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot
  $fixedPort = 18080
  function Set-EnvValue($key, $value) {
    if (Select-String -Path .env -Pattern "^$key=" -Quiet) {
      (Get-Content .env) -replace "^$key=.*", "$key=$value" | Set-Content .env
    } else {
      Add-Content .env "`n$key=$value"
    }
  }
if (!(Test-Path .env)) {
  $dbPass = -join ((48..57) + (65..90) + (97..122) | Get-Random -Count 24 | ForEach-Object {[char]$_})
  $rootPass = -join ((48..57) + (65..90) + (97..122) | Get-Random -Count 24 | ForEach-Object {[char]$_})
  (Get-Content .env.example).Replace('BIOCONTROL_DB_PASSWORD=AUTO_GENERATED', "BIOCONTROL_DB_PASSWORD=$dbPass").Replace('BIOCONTROL_MYSQL_ROOT_PASSWORD=AUTO_GENERATED', "BIOCONTROL_MYSQL_ROOT_PASSWORD=$rootPass") | Set-Content .env
}
  Set-EnvValue 'BIOCONTROL_FRONTEND_PUBLISHED_PORT' $fixedPort
$physical = (Select-String -Path .env -Pattern '^BIOCONTROL_LICENSE_PHYSICAL_ADDRESS=' -ErrorAction SilentlyContinue | Select-Object -Last 1).Line
if (!$physical) {
  Add-Content .env "`nBIOCONTROL_LICENSE_PHYSICAL_ADDRESS="
  $physical = 'BIOCONTROL_LICENSE_PHYSICAL_ADDRESS='
}
$mac = ($physical -replace '^BIOCONTROL_LICENSE_PHYSICAL_ADDRESS=', '').Trim().ToUpper()
if ($mac -notmatch '^([0-9A-F]{2}:){5}[0-9A-F]{2}$' -or $mac -eq '00:00:00:00:00:00') {
  try {
    $detected = Get-NetAdapter -Physical -ErrorAction Stop |
      Where-Object {$_.Status -eq 'Up' -and $_.MacAddress} |
      Select-Object -First 1 -ExpandProperty MacAddress
    if ($detected) {
      $detected = $detected.Replace('-', ':').ToUpper()
      (Get-Content .env) -replace '^BIOCONTROL_LICENSE_PHYSICAL_ADDRESS=.*', "BIOCONTROL_LICENSE_PHYSICAL_ADDRESS=$detected" | Set-Content .env
    }
  } catch {}
}
docker compose down --remove-orphans | Out-Null
try {
  docker ps -q --filter "publish=$fixedPort" | ForEach-Object {
    if ($_){ docker rm -f $_ | Out-Null }
  }
} catch {}
try {
  Get-NetTCPConnection -LocalPort $fixedPort -ErrorAction Stop |
    Select-Object -ExpandProperty OwningProcess -Unique |
    ForEach-Object { Stop-Process -Id $_ -Force -ErrorAction SilentlyContinue }
} catch {}
docker compose up --build -d --remove-orphans
docker compose ps
