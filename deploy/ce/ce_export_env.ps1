# Path to config file
$configFile = "deploy/ce/ce.config.properties"

# Function to read a property value from the config file
function Get-PropValue {
    param(
        [string]$file,
        [string]$key
    )
    $match = Select-String -Path $file -Pattern "^$key=" | Select-Object -First 1
    if ($match) {
        return $match.Line.Split('=')[1].Trim()
    }
    return ""
}

# List of config keys
$keys = @(
    "APP_NAME",
    "BROKER_USERNAME",
    "BROKER_PASSWORD",
    "BROKER_ICR_NAMESPACE_URL",
    "ICR_IMAGE",
    "CE_PROJECT",
    "CE_REGION",
    "CE_RESOURCE_GROUP",
    "CE_REGISTRY_SECRET_NAME",
    "ONBOARDING_ENV",
    "PC_URL",
    "DB_HOST",
    "DB_PORT",
    "DB_USER",
    "DB_USER_PWD",
    "DB_NAME",
    "DB_CERT",
    "BROKER_BEARER_IDENTITIES"
)

# Build final export values
$exportLines = @()
foreach ($key in $keys) {
    $envValue = [Environment]::GetEnvironmentVariable($key)
    if (-not $envValue -or $envValue -eq '""') {
        $fileValue = Get-PropValue $configFile $key
        $exportLines += "$key=$fileValue"
    } else {
        $exportLines += "$key=$envValue"
    }
}

# Ensure the file is not read-only
if (Test-Path $ConfigFile) {
    Set-ItemProperty -Path $ConfigFile -Name IsReadOnly -Value $false
}

# Write back to the config file
$exportText = $exportLines -join "`n"
Set-Content -Path $configFile -Value $exportText -Encoding utf8
