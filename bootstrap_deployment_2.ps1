$BootstrapSettngs = @{
    InstallDSC                  = $true;
    InstallUtils                = $true;
    EnableConvenienceFeatures   = $true;
    PullDeploy                  = $true;
}

try {
    $ErrorActionPreference = "Stop"

    # PowerShell
    if ($PSVersionTable.PSVersion.Major -lt 5) {
       throw "PowerShell 5 must be installed - it is not installed."
    }
    
    # PowerShell DSC
    if($BootstrapSettngs.InstallDSC) {
        Write-Host "Installing PackageManagement module"
        Import-Module PackageManagement
        Get-PackageProvider -Name NuGet -Force -ForceBootstrap
        Set-PSRepository -InstallationPolicy Trusted -Name PSGallery

        Write-Host "Installing DSC modules"
        Install-Module xWebAdministration -RequiredVersion 1.9.0.0
    #     Install-Module xStorage -RequiredVersion 2.4.0.0
    #     Install-Module xNetworking -RequiredVersion 2.7.0.0 
    #     Install-Module xCertificate -RequiredVersion 1.1.0.0
    #     Install-Module "xPSDesiredStateConfiguration" -RequiredVersion 3.7.0.0
    #     Install-Module Carbon -RequiredVersion 2.0.1
    #     Install-Module cChoco -RequiredVersion 2.0.5.22
    #     Install-Module cMsmq -RequiredVersion 1.0.3
        # Install-Module xSQLServer -RequiredVersion 1.4.0.0
    }

    # Utilities
    if ($BootstrapSettngs.InstallUtils) {
        choco install git -y
        choco install python2 -y
    }

    # Try load git into path
    refreshenv

    # Convenience Features
    if ($BootstrapSettngs.EnableConvenienceFeatures) {
        # Show hidden files and folders (need to restart Windows Explorer)
        $key = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
        Set-ItemProperty $key Hidden 1
        Set-ItemProperty $key HideFileExt 0
        Set-ItemProperty $key ShowSuperHidden 1
        choco install sublimetext3 -y
        choco install googlechrome -y
    }

    if ($BootstrapSettngs.PullDeploy) {
        Write-Host "Pulling Deployment code"
        $cloneDir = "C:\SetupDeployment"
        Start-Process -FilePath git -ArgumentList "clone https://github.com/MattSegal/DeployWindows.git $cloneDir" -Wait
    }

} catch {
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