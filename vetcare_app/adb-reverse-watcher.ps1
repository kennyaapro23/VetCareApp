param(
    [int]$Port = 8000,
    [int]$IntervalSeconds = 5,
    [int]$MaxAttempts = 3,
    [string]$LogFile = "$PSScriptRoot\adb-reverse-watcher.log"
)

function Find-Adb {
    if ($env:ANDROID_SDK_ROOT) {
        $p = Join-Path $env:ANDROID_SDK_ROOT 'platform-tools\adb.exe'
        if (Test-Path $p) { return $p }
    }
    if ($env:ANDROID_HOME) {
        $p = Join-Path $env:ANDROID_HOME 'platform-tools\adb.exe'
        if (Test-Path $p) { return $p }
    }
    try {
        $where = (where.exe adb) 2>$null
        if ($where) { return $where.Split("`n")[0].Trim() }
    } catch { }
    return $null
}

function Log($text) {
    $line = "[$(Get-Date -Format o)] $text"
    Add-Content -Path $LogFile -Value $line
}

$adb = Find-Adb
if (-not $adb) {
    Log "ERROR: adb not found. Please install Android platform-tools or set ANDROID_SDK_ROOT/ANDROID_HOME."
    Write-Error "adb not found. Please install platform-tools or set ANDROID_SDK_ROOT/ANDROID_HOME."
    exit 1
}

Log "Starting adb reverse watcher (Port=$Port, Interval=${IntervalSeconds}s) using adb: $adb"

while ($true) {
    try {
        $out = & $adb devices 2>&1
    } catch {
        Log "adb devices failed: $_"
        Start-Sleep -Seconds $IntervalSeconds
        continue
    }

    $devices = @()
    foreach ($line in $out -split "`n") {
        $trim = $line.Trim()
        if ($trim -match '^(\S+)\s+device$') { $devices += $Matches[1] }
    }

    if ($devices.Count -eq 0) {
        Log "No devices found."
        Start-Sleep -Seconds $IntervalSeconds
        continue
    }

    foreach ($d in $devices) {
        # Check existing reverse entries for this device
        $exists = $false
        try {
            $rlist = & $adb -s $d reverse --list 2>&1
            foreach ($rl in $rlist -split "`n") {
                if ($rl -match "tcp:$Port") { $exists = $true; break }
            }
        } catch {
            Log "Failed to query reverse list for $d: $_"
        }

        if (-not $exists) {
            Log "Applying reverse tcp:$Port -> tcp:$Port for $d"
            $attempt = 0
            $success = $false
            while (($attempt -lt $MaxAttempts) -and (-not $success)) {
                try {
                    $res = & $adb -s $d reverse "tcp:$Port" "tcp:$Port" 2>&1
                    if ($LASTEXITCODE -eq 0) { $success = $true; Log "Reverse applied to $d" }
                    else { Log "adb reverse attempt failed for $d: $res" }
                } catch {
                    Log "adb reverse exception for $d: $_"
                }
                $attempt++
                if (-not $success) { Start-Sleep -Seconds 1 }
            }
            if (-not $success) { Log "Failed to apply reverse for $d after $MaxAttempts attempts." }
        } else {
            Log "Reverse already present for $d (tcp:$Port)"
        }
    }

    Start-Sleep -Seconds $IntervalSeconds
}
