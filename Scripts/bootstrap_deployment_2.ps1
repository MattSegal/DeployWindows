$BootstrapSettngs = @{
    EnableConvenienceFeatures   = $true;
    PullDeploy                  = $true;
}

try 
{
    $ErrorActionPreference = "Stop"

    # PowerShell
    if ($PSVersionTable.PSVersion.Major -lt 5) 
    {
       throw "PowerShell 5 must be installed - it is not installed."
    }
    
    # PowerShell DSC
    Write-Host "Installing PackageManagement module"
    Import-Module PackageManagement
    Get-PackageProvider -Name NuGet -Force -ForceBootstrap
    Set-PSRepository -InstallationPolicy Trusted -Name PSGallery

    Write-Host "Installing DSC modules"
    Install-Module xWebAdministration
    Install-Module xPSDesiredStateConfiguration
    Install-Module cChoco

    # Try load git into path
    RefreshEnv

    # Convenience Features
    if ($BootstrapSettngs.EnableConvenienceFeatures) 
    {
        # Show hidden files and folders (need to restart Windows Explorer)
        $key = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
        Set-ItemProperty $key Hidden 1
        Set-ItemProperty $key HideFileExt 0
        Set-ItemProperty $key ShowSuperHidden 1
    }

    if ($BootstrapSettngs.PullDeploy) 
    {
        Write-Host "Pulling Deployment code"
        $cloneDir = "C:\SetupDeployment"
        Start-Process -FilePath git -ArgumentList "clone https://github.com/MattSegal/DeployWindows.git $cloneDir" -Wait
    }

} 
catch 
{
    $logDir = "C:\Temp"
    $logPath = "$logDir\bootstrap.log"
    if (!(Test-Path $logDir))
    {
        New-Item -Type Directory -Path $logDir
    }
    Write-Host "Logging exception at $logPath"
    Out-File -FilePath $logPath -InputObject ($Error[0] | Out-String)
    exit 1
}


Write-Host "Bootstrap done."