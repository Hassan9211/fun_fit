param(
  [string]$DeviceId,
  [int]$Port = 8000,
  [string]$ApiBaseUrl,
  [switch]$UseLan,
  [switch]$NoReverse,
  [switch]$StartMockApi,
  [string]$MockApiScriptPath = 'tool/mock_signup_server.dart',
  [switch]$DryRun,
  [string[]]$ExtraFlutterArgs
)

$ErrorActionPreference = 'Stop'

function Fail([string]$Message) {
  Write-Error $Message
  exit 1
}

function Get-ConnectedAndroidDevices {
  $lines = (& adb devices) | Select-Object -Skip 1
  $devices = @()
  foreach ($line in $lines) {
    if ($line -match '^\s*$') { continue }
    if ($line -match '^(\S+)\s+device$') {
      $devices += $matches[1]
    }
  }
  return @($devices)
}

function Get-LocalIPv4Address {
  try {
    $ip = Get-NetIPAddress -AddressFamily IPv4 |
      Where-Object {
        $_.IPAddress -notlike '127.*' -and
        $_.IPAddress -notlike '169.254.*' -and
        $_.PrefixOrigin -ne 'WellKnown'
      } |
      Sort-Object -Property InterfaceMetric |
      Select-Object -ExpandProperty IPAddress -First 1
    if ($ip) { return $ip }
  } catch {
    # Fallback below if Get-NetIPAddress is unavailable.
  }

  $raw = ipconfig | Select-String 'IPv4 Address'
  foreach ($entry in $raw) {
    if ($entry.Line -match ':\s*([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)\s*$') {
      $candidate = $matches[1]
      if ($candidate -notlike '127.*' -and $candidate -notlike '169.254.*') {
        return $candidate
      }
    }
  }
  return $null
}

function Test-PortListening([int]$LocalPort) {
  $conn = Get-NetTCPConnection -State Listen -LocalPort $LocalPort -ErrorAction SilentlyContinue
  return $null -ne $conn
}

if (-not (Get-Command adb -ErrorAction SilentlyContinue)) {
  Fail 'adb not found in PATH. Install Android platform-tools and retry.'
}

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
  Fail 'flutter not found in PATH. Install Flutter SDK and retry.'
}

if ($StartMockApi -and -not (Get-Command dart -ErrorAction SilentlyContinue)) {
  Fail 'dart not found in PATH. Flutter installs Dart; ensure PATH is configured.'
}

$devices = @(Get-ConnectedAndroidDevices)
if ($devices.Count -eq 0) {
  Fail 'No connected Android device found.'
}

if ([string]::IsNullOrWhiteSpace($DeviceId)) {
  if ($devices.Count -eq 1) {
    $DeviceId = $devices[0]
  } else {
    Write-Host 'Multiple devices found:'
    $devices | ForEach-Object { Write-Host " - $_" }
    Fail 'Pass -DeviceId to choose one device.'
  }
}

if ($devices -notcontains $DeviceId) {
  Fail "Device '$DeviceId' is not connected."
}

if ([string]::IsNullOrWhiteSpace($ApiBaseUrl)) {
  if ($UseLan) {
    $localIp = Get-LocalIPv4Address
    if (-not $localIp) {
      Fail 'Could not detect local IPv4 address for LAN mode.'
    }
    $ApiBaseUrl = "http://$localIp`:$Port"
  } else {
    $ApiBaseUrl = "http://127.0.0.1`:$Port"
  }
}

if ($StartMockApi) {
  if (Test-PortListening -LocalPort $Port) {
    Write-Host "API port $Port already in use. Reusing existing server."
  } else {
    if (-not (Test-Path $MockApiScriptPath)) {
      Fail "Mock API script not found at '$MockApiScriptPath'."
    }

    if ($DryRun) {
      Write-Host "DryRun: would start mock API via: dart run $MockApiScriptPath"
    } else {
      Write-Host "Starting mock API: dart run $MockApiScriptPath"
      Start-Process -FilePath dart -ArgumentList @('run', $MockApiScriptPath) -WindowStyle Hidden | Out-Null
      $ready = $false
      for ($i = 0; $i -lt 15; $i++) {
        Start-Sleep -Milliseconds 400
        if (Test-PortListening -LocalPort $Port) {
          $ready = $true
          break
        }
      }
      if (-not $ready) {
        Fail "Mock API did not start on port $Port."
      }
    }
  }
}

if (-not $UseLan -and -not $NoReverse) {
  if ($DryRun) {
    Write-Host "DryRun: would set adb reverse tcp:$Port -> tcp:$Port on device $DeviceId"
  } else {
    Write-Host "Setting adb reverse: tcp:$Port -> tcp:$Port on device $DeviceId"
    & adb -s $DeviceId reverse "tcp:$Port" "tcp:$Port" | Out-Null
  }
}

$flutterArgs = @(
  'run',
  '-d', $DeviceId,
  '--dart-define', "API_BASE_URL=$ApiBaseUrl"
)

if ($ExtraFlutterArgs) {
  $flutterArgs += $ExtraFlutterArgs
}

Write-Host "Device: $DeviceId"
Write-Host "API_BASE_URL: $ApiBaseUrl"
Write-Host ("Command: flutter " + ($flutterArgs -join ' '))

if ($DryRun) {
  exit 0
}

& flutter @flutterArgs
