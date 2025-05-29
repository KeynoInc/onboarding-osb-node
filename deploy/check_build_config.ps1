$ConfigFile = "deploy/build.config.properties"

# Helper to get value by key from properties file
function Get-PropValuePutOnEnv($file, $key) {
    $match = Select-String -Path $file -Pattern "^$key=" | Select-Object -First 1
    if ($match) {
        $value = $match.Line.Split('=')[1].Trim()
        Set-Item -Path "Env:$key" -Value $value
        return $value
    }
    return ""
}

$BROKER_ICR_NAMESPACE_URL = Get-PropValuePutOnEnv $ConfigFile "BROKER_ICR_NAMESPACE_URL"
$GC_OBJECT_ID = Get-PropValuePutOnEnv $ConfigFile "GC_OBJECT_ID"
$ICR_IMAGE = Get-PropValuePutOnEnv $ConfigFile "ICR_IMAGE"
$ONBOARDING_ENV = Get-PropValuePutOnEnv $ConfigFile "ONBOARDING_ENV"
$ICR_NAMESPACE_REGION = Get-PropValuePutOnEnv $ConfigFile "ICR_NAMESPACE_REGION"

$EMPTY = '""'
Write-Host ""
Write-Host "---------- Checking configuration ----------"

if ([string]::IsNullOrEmpty($ICR_NAMESPACE_REGION) -or $ICR_NAMESPACE_REGION -eq $EMPTY -or
    [string]::IsNullOrEmpty($ONBOARDING_ENV) -or $ONBOARDING_ENV -eq $EMPTY -or
    [string]::IsNullOrEmpty($ICR_IMAGE) -or $ICR_IMAGE -eq $EMPTY -or
    [string]::IsNullOrEmpty($GC_OBJECT_ID) -or $GC_OBJECT_ID -eq $EMPTY -or
    [string]::IsNullOrEmpty($BROKER_ICR_NAMESPACE_URL) -or $BROKER_ICR_NAMESPACE_URL -eq $EMPTY) {

    Write-Host ""
    Write-Host "*******************************************************************************"
    Write-Host "build config properties not set !"
    Write-Host "refer README to set values"
    Write-Host "Exiting..."
    Write-Host "*******************************************************************************"
    Write-Host ""
    exit 1
} else {
    Write-Host "Ok"
}

Write-Host ""
Write-Host "---------- Checking secrets ----------"

if ([string]::IsNullOrEmpty($env:DEPLOYMENT_IAM_API_KEY) -or $env:DEPLOYMENT_IAM_API_KEY -eq $EMPTY -or
    [string]::IsNullOrEmpty($env:ONBOARDING_IAM_API_KEY) -or $env:ONBOARDING_IAM_API_KEY -eq $EMPTY) {

    Write-Host ""
    Write-Host "*******************************************************************************"
    Write-Host "secrets not set !"
    Write-Host "make sure these values are provided!"
    Write-Host "DEPLOYMENT_IAM_API_KEY, ONBOARDING_IAM_API_KEY"
    Write-Host "refer README to set values"
    Write-Host "Exiting..."
    Write-Host "*******************************************************************************"
    Write-Host ""
    exit 1
} else {
    Write-Host "Ok"
}
