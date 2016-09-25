param
(
    [String]$ComputerName = "localhost",
    [String]$ApplicationRoot = "D:\code\dotnet\follower"
)

Configuration RedditFollower
{
    Import-DscResource –ModuleName 'PSDesiredStateConfiguration'
    Import-DSCResource -ModuleName 'xWebAdministration'
    Import-DSCResource -ModuleName 'Deployment'
    

    Node $AllNodes.NodeName
    {
        BaseServer "BaseServer"
        {
        }

        IISServer "IIS"
        { 
            ComputerName = $ComputerName
        }

        xWebAppPool RedditFollowerAppPool 
        { 
            Name   = "RedditFollowerAppPool"
            State  = "Started" 
            managedPipelineMode = "Integrated"
            managedRuntimeVersion = "v4.0"
            identityType = "ApplicationPoolIdentity"
            startMode = "AlwaysRunning"
            DependsOn = "[IISServer]IIS"
        } 

        xWebsite DefaultWebSite 
        {
            Name            = "Default Web Site" 
            State           = "Stopped" 
            PhysicalPath    = "C:\inetpub\wwwroot" 
            DependsOn       = "[IISServer]IIS"  
        }

        xWebsite RedditFollower
        {
            Name            = "RedditFollower" 
            State           = "Started" 
            PhysicalPath    = (Join-Path $ApplicationRoot "RedditFollower.Web")
            BindingInfo     = MSFT_xWebBindingInformation 
                            { 
                                Protocol = "HTTP" 
                                Port     = 80
                            }
            DependsOn       = "[xWebAppPool]RedditFollowerAppPool" 
            ApplicationPool = "RedditFollowerAppPool"
        }

        xWebApplication RedditFollowerApi
        {
            Name = "api"
            Website = "RedditFollower"
            PhysicalPath = (Join-Path $ApplicationRoot "RedditFollower.Api")
            WebAppPool = "RedditFollowerAppPool"
            DependsOn = "[xWebsite]RedditFollower" 
        }
    }
}

$configurationData = @{
    AllNodes = @(
        @{
            NodeName = "localhost"
        }
    )
}

$compiledDscPath = Join-Path $PSScriptRoot '..\CompiledDsc\RedditFollower'
if (Test-Path $compiledDscPath) 
{
    Remove-Item $compiledDscPath -recurse -force
}

# Compile the DSC
& RedditFollower -ConfigurationData $configurationData -OutputPath $compiledDscPath

# Run the DSC
Start-DscConfiguration -Force -Verbose -Wait -Path $compiledDscPath -ComputerName $ComputerName