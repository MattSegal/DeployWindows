# Chocolatey profile
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) 
{
  Import-Module "$ChocolateyProfile"
}

function py     { python $args }
function exp    { & "explorer" $args }
$setup = "C:\Setup"
$web = "C:\RedditFollower"
$temp = "C:\Temp"

cd $setup