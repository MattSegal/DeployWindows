$currentDir = pwd

# Make sure target dir exists
$targetDir = "C:\RedditFollower"
if (-ne Test-Path $targetDir) {
    New-Item $targetDir -type directory
}

cd $targetDir
git pull "https://github.com/MattSegal/RedditFollowerDeploy.git"
cd $currentDir 