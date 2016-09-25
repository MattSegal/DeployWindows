Configuration BaseServer
{
    param
    (
        [Boolean]$InstallConvenienceApps = $false
    )

    Import-DscResource -Module cChoco

    cChocoInstaller InstallChocolatey
    {
        InstallDir = 'C:\ProgramData\chocolatey'
    }

    $essentialPackages = @(
        'git',
        'python2'
    )

    ForEach ($package in $essentialPackages)
    {
        cChocoPackageInstaller $package
        {
            Name = $package
            DependsOn = "[cChocoInstaller]InstallChocolatey"
        }
    }

    if ($InstallConvenienceApps)
    {
        $conveniencePackages = @(
            'sublimetext3',
            'googlechrome'
        )

        ForEach ($package in $conveniencePackages)
        {
            cChocoPackageInstaller $package
            {
                Name = $package
                DependsOn = "[cChocoInstaller]InstallChocolatey"
            }
        }
    }
}
