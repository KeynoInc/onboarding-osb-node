$ConfigFile = "deploy/build.config.properties"

# Read key-value pairs into a hashtable
$props = @{}
Get-Content $ConfigFile | ForEach-Object {
    if ($_ -match "^\s*([^=]+)=(.*)$") {
        $props[$matches[1].Trim()] = $matches[2].Trim()
    }
}

function Get-Var($key) {
    $envValue = (Get-Item -Path "Env:$key" -ErrorAction SilentlyContinue).Value
    $defaultValue = $props[$key]
    if (![string]::IsNullOrEmpty($envValue) -and $envValue -ne '""') {
        return $envValue
    } else {
        return $defaultValue
    }
}

$export = @"
ONBOARDING_ENV=$(Get-Var 'ONBOARDING_ENV')
GC_OBJECT_ID=$(Get-Var 'GC_OBJECT_ID')
BROKER_ICR_NAMESPACE_URL=$(Get-Var 'BROKER_ICR_NAMESPACE_URL')
ICR_IMAGE=$(Get-Var 'ICR_IMAGE')
ICR_NAMESPACE_REGION=$(Get-Var 'ICR_NAMESPACE_REGION')
ICR_RESOURCE_GROUP=$(Get-Var 'ICR_RESOURCE_GROUP')
"@

# Ensure the file is not read-only
if (Test-Path $ConfigFile) {
    Set-ItemProperty -Path $ConfigFile -Name IsReadOnly -Value $false
}

# Write back to file (overwrite)
$export | Set-Content $ConfigFile -Encoding utf8
