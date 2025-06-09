$configFile = "deploy/ce/ce.config.properties"

# List of required config environment variables
$requiredConfigVars = @(
    "APP_NAME",
    "BROKER_ICR_NAMESPACE_URL",
    "CE_REGION",
    "CE_RESOURCE_GROUP",
    "CE_PROJECT",
    "CE_REGISTRY_SECRET_NAME",
    "ICR_IMAGE"
)

# List of required secret environment variables
$requiredSecretVars = @(
    "DEPLOYMENT_IAM_API_KEY",
    "DB_HOST",
    "DB_PORT",
    "DB_USER",
    "DB_USER_PWD",
    "DB_NAME",
    "DB_CERT",
    "BROKER_BASIC_USERNAME",
    "BROKER_BASIC_PASSWORD",
    "BROKER_BEARER_IDENTITIES"
)

# Optional secret environment variables (warn if missing)
$optionalSecretVars = @(
    "METERING_API_KEY"
)

# Helper to get value by key from properties file and put it on environment variable
function Get-PropValuePutOnEnv($file, $key) {
    $match = Select-String -Path $file -Pattern "^$key=" | Select-Object -First 1
    if ($match) {
        $value = $match.Line.Split('=')[1].Trim()
        Set-Item -Path "Env:$key" -Value $value
        return $value
    }
    return ""
}

# Read config values from file and set as env variables
$allVariable = $requiredSecretVars + $requiredConfigVars + $optionalSecretVars
foreach ($key in $allVariable) {
    Set-Variable -Name $key -Value (Get-PropValuePutOnEnv $configFile $key)
}

$EMPTY = '""'

Write-Host ""
Write-Host "---------- Checking configuration ----------"
Write-Host ""

# Check for missing config variables
$missingConfig = @()
foreach ($key in $requiredConfigVars) {
    $val = (Get-Item "Env:$key").Value
    if (-not $val -or $val -eq $EMPTY) {
        $missingConfig += $key
    }
}

if ($missingConfig.Count -gt 0) {
    Write-Host ""
    Write-Host "*******************************************************************************"
    Write-Host "deploy config properties not set!"
    Write-Host "Missing: $($missingConfig -join ', ')"
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
Write-Host ""

# Check for missing required secrets
$missingSecrets = @()
foreach ($key in $requiredSecretVars) {
    $val = (Get-Item "Env:$key").Value
    if (-not $val -or $val -eq $EMPTY) {
        $missingSecrets += $key
    }
}

if ($missingSecrets.Count -gt 0) {
    Write-Host ""
    Write-Host "*******************************************************************************"
    Write-Host "secrets not set!"
    Write-Host "make sure $($missingSecrets -join ', ') is provided!"
    Write-Host "refer README to set values"
    Write-Host "Exiting..."
    Write-Host "*******************************************************************************"
    Write-Host ""
    exit 1
} else {
    Write-Host "Ok"
}

Write-Host ""
Write-Host "---------- Checking optional secrets ----------"
Write-Host ""

$missingOptionalSecrets = @()
foreach ($key in $optionalSecretVars) {
    $item = Get-Item "Env:$key"    
    if (-not $item -or $item?.Value -eq $EMPTY) {
        $missingOptionalSecrets += $key
    } 
}

if ($missingOptionalSecrets.Count -gt 0) {
        Write-Host ""
        Write-Host "*******************************************************************************"
        Write-Host "$($missingOptionalSecrets -join ',') were not provided!"
        Write-Host "options will not be available"
        Write-Host "refer README to set values"
        Write-Host "*******************************************************************************"
        Write-Host ""
    } else {
        Write-Host "Ok"
    }