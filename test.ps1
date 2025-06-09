function Set-AppAction {
    param(
        [Parameter(Mandatory)][ValidateSet("Create","Update")]
        [string]$Action,

        [Parameter(Mandatory)]
        [bool]$UseMetering,

        [Parameter(Mandatory)]
        [string[]]$OtherParams
    )

    $commonParams = @(
        "--name",  $env:APP_NAME,
        "--image", $fullImage,
        "--min",   "1",
        "--env",   "BROKER_USERNAME=$($env:BROKER_USERNAME)",
        "--env",   "BROKER_PASSWORD=$($env:BROKER_PASSWORD)",
        "--env",   "BUILD_NUMBER=$BUILD_NUMBER",
        "--env",   "IAM_ENDPOINT=$IAM_ENDPOINT",
        "--env",   "USAGE_ENDPOINT=$USAGE_ENDPOINT",
        "--env",   "PC_URL=$($env:PC_URL)",
        "--rs",    $env:CE_REGISTRY_SECRET_NAME
    )

    $finalParams = New-Object -TypeName System.Collections.ArrayList
    $finalParams.AddRange($commonParams)
    $finalParams.AddRange($OtherParams)

    if ($UseMetering){
        $finalParams.Add("--env")
        $finalParams.Add("METERING_API_KEY=$($env:METERING_API_KEY)")
    }

    if ($Action -eq "Create") {
        Write-Host "✅ Creating with metering enabled." $finalParams
    }
    elseif ($Action -eq "Update") {
        Write-Host "🔄 Updating with metering enabled." $finalParams
    }
}


Set-AppAction -Action "Create" -UseMetering $false -OtherParams @("--env", "BROKER_URL=$APP_URL", "--env","DASHBOARD_URL=$APP_URL")

Set-AppAction -Action "Update" -UseMetering $true -OtherParams @("--env", "BROKER_URL=$APP_URL", "--env","DASHBOARD_URL=$APP_URL")

$params = @(
  "-n",$env:APP_NAME,
  "-o","url" 
)
$APP_URL = ibmcloud ce application get @params
Write-Host $APP_URL