$BootstrapSettngs = @{
    SetExecutionPolicy          = $false;
    InstallSqlServer            = $false;
    InstallDotNet               = $false;
    InstallDSC                  = $false;
    InstallUtils                = $false;
    EnableConvenienceFeatures   = $false;
    PullDeploy                  = $true;
}

try {
    $ErrorActionPreference = "Stop"

    # Execution Policy
    if ($BootstrapSettngs.SetExecutionPolicy) {
        Write-Host "Applying 'Bypass' execution policy."
        Set-ExecutionPolicy Bypass
    }
    
    #  Chocolately
    $isChocoInstalled =  $env:ChocolateyInstall.Length -gt 0
    if(!$isChocoInstalled) {
        Write-Host "Installing Chocolatey package manager."
        $ChocolateyBootstrapUrl = 'https://chocolatey.org/install.ps1'
        Invoke-WebRequest $ChocolateyBootstrapUrl -UseBasicParsing | Invoke-Expression
    }

    # .NET 4.5
    if($BootstrapSettngs.InstallDotNet) {
        Write-Host "Installing .NET 4.5."
        choco install dotnet4.5 -y
    }
    
    # PowerShell
    if ($PSVersionTable.PSVersion.Major -lt 5) {
        Write-Host "Installing PowerShell and WMF 5."
        choco install powershell -y
    }

    # SQL Server
    if ($BootstrapSettngs.InstallSqlServer) {
        Write-Host "Installing MS SQL Server Express 2014."
        # choco install mssql2014express-defaultinstance -y
        Start-Process .\SqlLocalDB.msi
        # msiexec /i ".\SqlLocalDB.msi"
    }
    
    # PowerShell DSC
    if($BootstrapSettngs.InstallDSC) {
        Write-Host "Installing PackageManagement module"
        Import-Module PackageManagement
        Get-PackageProvider -Name NuGet -Force -ForceBootstrap
        Set-PSRepository -InstallationPolicy Trusted -Name PSGallery

        Write-Host "Installing DSC modules"
    #     Install-Module xStorage -RequiredVersion 2.4.0.0
        Install-Module xWebAdministration -RequiredVersion 1.9.0.0
    #     Install-Module xNetworking -RequiredVersion 2.7.0.0 
    #     Install-Module xCertificate -RequiredVersion 1.1.0.0
    #     Install-Module "xPSDesiredStateConfiguration" -RequiredVersion 3.7.0.0
    #     Install-Module Carbon -RequiredVersion 2.0.1
    #     Install-Module cChoco -RequiredVersion 2.0.5.22
    #     Install-Module cMsmq -RequiredVersion 1.0.3
        Install-Module xSQLServer -RequiredVersion 1.4.0.0
    }

    # Utilities
    if ($BootstrapSettngs.InstallUtils) {
        choco install git -y
        choco install python2 -y
    }

    # Convenience Features
    if ($BootstrapSettngs.EnableConvenienceFeatures) {
        # Show hidden files and folders (need to restart Windows Explorer)
        $key = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
        Set-ItemProperty $key Hidden 1
        Set-ItemProperty $key HideFileExt 0
        Set-ItemProperty $key ShowSuperHidden 1
        choco install sublimetext3 -y
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


Write-Host "Bootstrap done. Press 'r' to restart, press any other key to close."
$userInput = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

$isRestartUserInput = $userInput.Character -eq 'r'
if ($isRestartUserInput)
{
    Invoke-Reboot
}