$currentDir = pwd

# Make sure target dir exists
$targetDir = "C:\RedditFollower"
if (-not ((Test-Path $targetDir) -and (Test-Path $targetDir\.git))) 
{
    if (-not (Test-Path $targetDir))
    {
        New-Item $targetDir -type directory
    }
    cd $targetDir
    git clone https://github.com/MattSegal/RedditFollowerDeploy.git .
} 
else
{
    cd $targetDir
    git pull "https://github.com/MattSegal/RedditFollowerDeploy.git"
} 

cd $currentDir 