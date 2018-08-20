Get-PackageSource -Name PSGallery | Set-PackageSource -Trusted -Force -ForceBootstrap | Out-Null

$requiredVersion ='0.10.1'
$LabilityMod = Get-Module -Name Lability -ListAvailable | Sort Version -Descending
if (-Not $LabilityMod) {
   Write-Host -ForegroundColor Cyan "Installing Lability Module version $requiredVersion for the lab build"
   Install-Module -Name Lability -RequiredVersion $requiredVersion -Force
}
elseif ($LabilityMod[0].Version.ToString() -eq $requiredVersion) {
    Write-Host "Version $requiredVersion of Lability is already installed" -ForegroundColor Cyan
}
elseif ($LabilityMod[0]) {
    Write-Host -ForegroundColor Cyan "Updating Lability Module for the lab build"
    Update-Module -Name Lability -force #-RequiredVersion $requiredVersion -Force
}

