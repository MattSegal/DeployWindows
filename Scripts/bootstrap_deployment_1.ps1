$BootstrapSettngs = @{
    SetExecutionPolicy          = $true;
    InstallDotNet               = $true;
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

    # Load choco environment variables
    refreshenv

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


Write-Host "Bootstrap half done. Press 'r' to restart, press any other key to close."
$userInput = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

$isRestartUserInput = $userInput.Character -eq 'r'
if ($isRestartUserInput)
{
    Invoke-Reboot
}