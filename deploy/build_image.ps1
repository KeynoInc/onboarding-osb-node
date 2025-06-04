Write-Host ""
Write-Host "---------- building project image ----------"
Write-Host ""

docker build -f Dockerfile -t $env:ICR_IMAGE $args[0] --debug
docker tag $env:ICR_IMAGE "$env:BROKER_ICR_NAMESPACE_URL/$($env:ICR_IMAGE)"
$RESULT = docker push "$env:BROKER_ICR_NAMESPACE_URL/$($env:ICR_IMAGE)"

if ($RESULT -match "Pushed") {
    Write-Host ""
    Write-Host "*******************************************************************************"
    Write-Host "|                                                                   "
    Write-Host "|Image is successfully pushed on [$env:BROKER_ICR_NAMESPACE_URL/$($env:ICR_IMAGE)]"
    Write-Host "|                                                                   "
    Write-Host "*******************************************************************************"
    Write-Host ""
} else {
    Write-Host $RESULT
    Write-Host ""
    Write-Host "*******************************************************************************"
    Write-Host "|                                                                   "
    Write-Host "|Error while deploying image. check the logs above."
    Write-Host "|                                                                   "
    Write-Host "*******************************************************************************"
    Write-Host ""
}

