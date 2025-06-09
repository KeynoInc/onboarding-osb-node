param (
    [string]$Command = "help"
)

function Show-Help {
    Write-Host "`nAvailable commands"
    Write-Host ""
    Write-Host "  ./build.ps1 build"
    Write-Host ""
    Write-Host "      DEPLOYMENT_IAM_API_KEY=your-deployment-apikey ONBOARDING_IAM_API_KEY=your-onboarding-apikey ./build.ps1 build"
    Write-Host ""
    Write-Host "      build and push image on icr."
    Write-Host "      required env variables: "
    Write-Host "         ONBOARDING_ENV, GC_OBJECT_ID, BROKER_ICR_NAMESPACE_URL, ICR_IMAGE, ICR_NAMESPACE_REGION, ICR_RESOURCE_GROUP"
    Write-Host ""
    Write-Host "  ./build.ps1 deploy-ce"
    Write-Host ""
    Write-Host "      DEPLOYMENT_IAM_API_KEY=your-deployment-apikey METERING_API_KEY=your-metering-apikey ./build.ps1 deploy-ce"
    Write-Host ""
    Write-Host "      deploy image on code engine."
    Write-Host "      required env variables: "
    Write-Host "         APP_NAME, BROKER_USERNAME, BROKER_PASSWORD, BROKER_ICR_NAMESPACE_URL, ICR_IMAGE, CE_PROJECT, CE_REGION, CE_RESOURCE_GROUP, CE_REGISTRY_SECRET_NAME"
    Write-Host ""
    Write-Host "  ./build.ps1 build-deploy-ce"
    Write-Host ""
    Write-Host "      DEPLOYMENT_IAM_API_KEY=your-deployment-apikey ONBOARDING_IAM_API_KEY=your-onboarding-apikey METERING_API_KEY=your-metering-apikey ./build.ps1 build-deploy-ce"
    Write-Host ""
    Write-Host "      build + deploy-ce."
    Write-Host "      required env variables: all from commands build and deploy-ce "
    Write-Host ""
    Write-Host "Refer to the README for more information"
}

function Init {
    Write-Host "`n*******************************************************************************"
    Write-Host "Initializing"
    Write-Host "*******************************************************************************"
    Write-Host ""
    Get-ChildItem -Path ./deploy -Recurse -File | ForEach-Object { $_.Attributes = 'ReadOnly,Archive' }
    Get-ChildItem -Path ./deploy/ce -Recurse -File | ForEach-Object { $_.Attributes = 'ReadOnly,Archive' }
    Write-Host (Get-Location).Path
}

function Get-Catalog {
    Write-Host "`n*******************************************************************************"
    Write-Host "Getting catalog.json"
    Write-Host "*******************************************************************************"
    Write-Host ""
    & ./deploy/get_catalog_json.ps1
}

function Build {
    $startTime = Get-Date
    try {
        Init
        Build-Env
        & ./deploy/check_build_config.ps1
        Write-Host "`n*******************************************************************************"
        Write-Host "Logging to ibm container registry on docker"
        Write-Host "*******************************************************************************"
        Write-Host ""
        & ./deploy/docker_login.ps1
        Build-Job
        $endTime = Get-Date
        & ./deploy/convert_time.ps1 -secs (($endTime - $startTime).TotalSeconds) -stage "build"
    } finally {
        Remove-Item "_time_build.txt" -ErrorAction SilentlyContinue
    }
}

function Deploy-CE {
    $startTime = Get-Date
    try {
        Init
        Ce-Env
        & ./deploy/ce/check_deploy_config_ce.ps1
        & ./deploy/docker_login.ps1
        Deploy-Job-CE
        # Cleanup-Deploy-CE
        $endTime = Get-Date
        & ./deploy/convert_time.ps1 -secs (($endTime - $startTime).TotalSeconds) -stage "deploy-ce"
    } finally {
        Remove-Item "_time_deploy-ce.txt" -ErrorAction SilentlyContinue
    }
}

function Build-Deploy-CE {
    $startTime = Get-Date
    try {
        Init
        Build-Env
        Ce-Env
        & ./deploy/check_build_config.ps1
        & ./deploy/ce/check_deploy_config_ce.ps1
        & ./deploy/docker_login.ps1
        Build-Job
        Deploy-Job-CE
        # Cleanup-Deploy-CE
        $endTime = Get-Date
        Write-Host $endTime - $startTime
        & ./deploy/convert_time.ps1 -secs (($endTime - $startTime).TotalSeconds) -stage "build-deploy-ce"
    } finally {
        Remove-Item "_time_build-deploy-ce.txt" -ErrorAction SilentlyContinue
    }
}

function Build-Job {
    Write-Host "starting build..."
    Get-Catalog
    Write-Host "`n*******************************************************************************"
    Write-Host "Building docker image for environment"
    Write-Host "*******************************************************************************"
    Write-Host ""
    Write-Host "This may take a while. don't terminate process..."
    docker build -q -f deploy/Dockerfile -t osb-node-img $PWD.Path
    Write-Host "`n*******************************************************************************"
    Write-Host "Building and pushing image to ibm container registry"
    Write-Host "*******************************************************************************"
    Write-Host ""
    & ./deploy/handle_icr_namespace.ps1
    & ./deploy/build_image.ps1 "${PWD}"
}

function Deploy-Job-CE {
    Write-Host "starting deploy..."
    Write-Host "`n*******************************************************************************"
    Write-Host "Deploying image to code-engine"
    Write-Host "*******************************************************************************"
    Write-Host ""
    & ./deploy/ce/ce_export_env.ps1
    & ./deploy/ce/deploy_ce.ps1
}

function Build-Env {
    & ./deploy/build_export_env.ps1
}

function Ce-Env {
    & ./deploy/ce/ce_export_env.ps1
}

function Cleanup {
    Write-Host "`n*******************************************************************************"
    Write-Host "Cleaning up in order components created"
    Write-Host "*******************************************************************************"
    Write-Host ""
    Cleanup-Deploy-CE
    Write-Host "Full cleanup done."
}

function Cleanup-Deploy-CE {
    Write-Host "......cleaning up after ce deploy"
    try { docker container stop osb-container-deploy-ce | Out-Null } catch {}
    try { docker container rm osb-container-deploy-ce | Out-Null } catch {}
    Write-Host "Done."
}

switch ($Command.ToLower()) {
    "help" { Show-Help }
    "get-catalog" { Get-Catalog }
    "build" { Build }
    "deploy-ce" { Deploy-CE }
    "build-deploy-ce" { Build-Deploy-CE }
    "cleanup" { Cleanup }
    "init" { Init }
    default { Write-Host "Unknown command. Use ./build.ps1 help" }
}
