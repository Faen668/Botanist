#HerbScanner Install script by Faen668

cls

echo ""
write-host -BackgroundColor darkred "                                    "
write-host -ForegroundColor white -BackgroundColor darkred "  Botanist Installer                "
write-host -BackgroundColor darkred "                                    "
echo ""
echo "- This script will automatically install Botanist and its dependencies."
echo ""
write-Host '- Please make sure this script is placed in your ' -NoNewline; Write-Host -ForegroundColor green 'The Witcher 3 installation folder' -NoNewline; Write-Host '.'
echo ""
write-Host '- If you can see the folders ' -NoNewline; Write-Host -ForegroundColor green 'bin' -NoNewline; Write-Host ', ' -NoNewline; Write-Host -ForegroundColor green 'content'-NoNewline; Write-Host ' and ' -NoNewline; Write-Host -ForegroundColor green 'dlc' -NoNewline; Write-Host ', the script is in the correct place.'
echo ""
echo ""

$shouldInstall = Read-Host "- Install Botanist [Y/N]"
while($shouldInstall -ne "y")
{
    if ($shouldInstall -eq 'n') 
	{
		exit
	}
	write-Host '*** Please Type ' -NoNewline; Write-Host -ForegroundColor darkgreen 'Y' -NoNewline; Write-Host ' to install the mod or ' -NoNewline; Write-Host -ForegroundColor darkred 'N' -NoNewline; Write-Host ' to exit.'
	echo ""
	$shouldInstall = Read-Host "- Install Botanist [Y/N]"
}

cls

if (!(test-path dlc)) 
{
  echo ""
  write-host -ForegroundColor red "Please make sure the script is placed inside your The Witcher 3 installation directly."
  echo ""
  echo "- The script must be placed in the same folder alongside the bin, content, and dlc folders."
  echo ""
  echo "- Place it in your The Witcher 3 root directory correctly and run the script again."
  echo ""

  pause
  exit
}

# first we create the mods folder if it doesn't exist, because in clean installs
# this folder may be missing.
if (!(test-path mods)) {
  mkdir mods | out-null
}

write-host -BackgroundColor darkred "                                    "
write-host -ForegroundColor white -BackgroundColor darkred "  Botanist Installer                "
write-host -BackgroundColor darkred "                                    "

echo ""
echo "- Fetching latest release from Github..."
echo ""

$response = Invoke-RestMethod -Uri "https://api.github.com/repos/Faen668/Botanist/releases"
$latestversion = $response[0].name
$latestAssetUrl = "https://github.com/Faen668/Botanist/releases/latest/download/Botanist.zip"

echo ""
write-host "- Downloading Botanist $($latestversion)"
echo ""

$extractingFolder = "./__install_Botanist"


$latestAssetName = "Botanist.zip"
Invoke-WebRequest -Uri $latestAssetUrl -OutFile $latestAssetName

Expand-Archive -Force -LiteralPath $latestAssetName -DestinationPath ./$extractingFolder
remove-item $latestAssetName -recurse -force

$installMessage = "- Installing release {0}" -f $latestversion

echo ""
echo $installMessage
echo ""

if (test-path mods/modBotanist) 
{
	Remove-Item mods/modBotanist -force -recurse
}

if (test-path dlc/dlcBotanist) 
{
	Remove-Item dlc/dlcBotanist -force -recurse
}

if (test-path bin/config/r4game/user_config_matrix/pc/modBotanist.xml) 
{
	Remove-Item bin/config/r4game/user_config_matrix/pc/modBotanist.xml -force
}

$children = Get-ChildItem ./$extractingFolder
foreach ($child in $children) {
  $fullpath = "{0}/{1}" -f $extractingFolder, $child
  copy-item $fullpath . -force -recurse
}

#Install Scripts
echo ""
echo "- Installing Scripts"
$children = Get-ChildItem mods/modBotanist -recurse -exclude *.csv, *.w3strings, *.bundle, *.store, *.cache, *.txt, *.bat
foreach ($child in $children | Where-Object -Property PSIsContainer -eq $false)
{
  Write-Host -ForegroundColor green 'Installed' -NoNewline; Write-Host " - $($child.name)"
}

#Install Localisation
echo ""
echo "- Installing Localisation"
$children = Get-ChildItem mods/modBotanist -recurse -exclude *.ws, *.bundle, *.store, *.cache, *.txt, *.bat
foreach ($child in $children | Where-Object -Property PSIsContainer -eq $false)
{
  Write-Host -ForegroundColor green 'Installed' -NoNewline; Write-Host " - $($child.name)"
}

#Install Bundles
echo ""
echo "- Installing DLC Bundle"
$children = Get-ChildItem dlc/dlcBotanist -recurse -exclude *.ws, *.csv, *.w3strings, *.txt, *.bat
foreach ($child in $children | Where-Object -Property PSIsContainer -eq $false)
{
  Write-Host -ForegroundColor green 'Installed' -NoNewline; Write-Host " - $($child.name)"
}

if (test-path $extractingFolder) {
  remove-item $extractingFolder -recurse -force
}

$installedMessage = "=== Botanist {0} installed ===" -f $latestversion

echo ""
write-host $installedMessage -ForegroundColor green -BackgroundColor black
echo ""

echo ""
pause

cls
write-host -BackgroundColor darkred "                                      "
write-host -ForegroundColor white -BackgroundColor darkred "   Installation Step: User Settings   "
write-host -BackgroundColor darkred "                                      "
echo ""

write-Host '- Open the following two files:'
echo ""
Write-Host -ForegroundColor green '\Documents\The Witcher 3\user.settings'
Write-Host -ForegroundColor green '\Documents\The Witcher 3\dx12user.settings'
echo ""
echo "- At the top of the files copy and paste the following:"
echo ""

write-host -ForegroundColor yellow "[Botanist_GeneralSettings]"
write-host -ForegroundColor yellow "Botanist_Mod_Targets=00"
write-host -ForegroundColor yellow "Botanist_MapPins_Enabled=true"
write-host -ForegroundColor yellow "Botanist_MapPins_Radius=5"
echo ""
write-host -ForegroundColor yellow "[Botanist_HerbMarkers]"
write-host -ForegroundColor yellow "Botanist_Markers_Enabled=true"
write-host -ForegroundColor yellow "Botanist_Markers_Visible=02"
write-host -ForegroundColor yellow "Botanist_Markers_FontSize=20"
write-host -ForegroundColor yellow "Botanist_Markers_Display=00"
write-host -ForegroundColor yellow "Botanist_Markers_Active=02"
echo ""
write-host -ForegroundColor yellow "[Botanist_HarvestingGrounds]"
write-host -ForegroundColor yellow "Botanist_Farming_Enabled=true"
write-host -ForegroundColor yellow "Botanist_Farming_MaxAll=30"
write-host -ForegroundColor yellow "Botanist_Farming_MaxGrd=3"
write-host -ForegroundColor yellow "Botanist_Farming_MinReq=5"
write-host -ForegroundColor yellow "Botanist_Farming_Radius=150"
echo ""

write-host -BackgroundColor darkred "                             "
write-host -ForegroundColor white -BackgroundColor darkred "   Installation Finished     "
write-host -BackgroundColor darkred "                             "
echo ""

echo "- I hope you enjoy using the mod!"
echo ""
pause