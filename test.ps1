$startTime = Get-Date
Start-Sleep -Seconds 5
$endTime = Get-Date

& ./deploy/convert_time.ps1 -secs (($endTime - $startTime).TotalSeconds) -stage "build"