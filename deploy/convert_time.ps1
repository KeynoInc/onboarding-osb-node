param(
    [int]$secs,
    [string]$stage
)

$hours = [math]::Floor($secs / 3600)
$minutes = [math]::Floor(($secs % 3600) / 60)
$seconds = $secs % 60

Write-Host ("{0} took: {1}h:{2}m:{3}s" -f $stage, $hours, $minutes, $seconds)
