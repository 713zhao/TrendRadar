# Run TrendRadar in a loop and print timestamps
# Usage examples:
#   powershell -NoProfile -ExecutionPolicy Bypass -File scripts\run_trendradar_loop.ps1        # default 30 minutes
#   powershell -NoProfile -ExecutionPolicy Bypass -File scripts\run_trendradar_loop.ps1 -IntervalMinutes 10
# You can also set environment variable RUN_INTERVAL_MINUTES to override the interval.

# Accept an optional interval parameter (minutes)
param(
    [int]$IntervalMinutes = 30,
    [switch]$Once
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
# Project root is parent of scripts directory
$projectRoot = Resolve-Path (Join-Path $scriptDir "..")
Set-Location $projectRoot

# If env var RUN_INTERVAL_MINUTES is set and valid, override the parameter
if ($env:RUN_INTERVAL_MINUTES) {
    try {
        $envVal = [int]$env:RUN_INTERVAL_MINUTES
        if ($envVal -gt 0) {
            $IntervalMinutes = $envVal
        }
    } catch {
        Write-Warning "Invalid RUN_INTERVAL_MINUTES value: $env:RUN_INTERVAL_MINUTES"
    }
}

Write-Output "Using interval: $IntervalMinutes minutes"

# log file for troubleshooting
$logFile = Join-Path $projectRoot "scripts\run_trendradar_loop.log"
"`n----- $(Get-Date -Format o) -----`n" | Out-File -FilePath $logFile -Encoding utf8 -Append

while ($true) {
    $ts = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    Write-Output "[$ts] Starting TrendRadar run..."
    try {
        $python = Join-Path $projectRoot ".venv\Scripts\python.exe"
        $resolved = Resolve-Path $python -ErrorAction SilentlyContinue
        if ($resolved) {
            # Invoke python using the full resolved path and capture output
            $cmd = "`"$($resolved.Path)`" -m trendradar"
            "[$ts] Executing: $cmd" | Out-File -FilePath $logFile -Encoding utf8 -Append
            try {
                & $resolved.Path -m trendradar 2>&1 | Out-File -FilePath $logFile -Encoding utf8 -Append
            } catch {
                "[$ts] Execution error: $_" | Out-File -FilePath $logFile -Encoding utf8 -Append
            }
        } else {
            $msg = "[$ts] Python executable not found at $python"
            Write-Error $msg
            $msg | Out-File -FilePath $logFile -Encoding utf8 -Append
        }
    } catch {
        $err = "[$ts] TrendRadar run failed: $_"
        Write-Error $err
        $err | Out-File -FilePath $logFile -Encoding utf8 -Append
    }
    $ts2 = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    Write-Output "[$ts2] Run finished - sleeping $IntervalMinutes minutes..."
    "[$ts2] Run finished - sleeping $IntervalMinutes minutes..." | Out-File -FilePath $logFile -Encoding utf8 -Append
    if ($Once) {
        Write-Output "Once flag set - exiting loop."
        break
    }
    Start-Sleep -Seconds ($IntervalMinutes * 60)
}
