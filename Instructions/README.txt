//--------------------------------------------------------
//-------------------- Installation ----------------------
//--------------------------------------------------------

Completely remove any old version.

Skip this step if you have installed the mod with the install script.

Copy the 'mods', 'dlc' and 'bin' folder into your witcher 3 directory.

If you get a prompt to overwrite files go ahead and do so.

//--------------------------------------------------------
//---------------- Adding User Settings ------------------
//--------------------------------------------------------

- Copy and paste the following:

[Botanist_GeneralSettings]
Botanist_Mod_Targets=00
Botanist_MapPins_Enabled=true
Botanist_MapPins_Radius=5

[Botanist_HerbMarkers]
Botanist_Markers_Enabled=true
Botanist_Markers_Visible=02
Botanist_Markers_FontSize=20
Botanist_Markers_Display=00
Botanist_Markers_Active=02

[Botanist_HarvestingGrounds]
Botanist_Farming_Enabled=true
Botanist_Farming_MaxAll=30
Botanist_Farming_MaxGrd=3
Botanist_Farming_MinReq=5
Botanist_Farming_Radius=150

- Into These 2 Files:

*\Documents\The Witcher 3\user.settings
*\Documents\The Witcher 3\dx12user.settings (NG Only)

//--------------------------------------------------------
//----------------- Menu Building (NG ONLY) --------------
//--------------------------------------------------------

-Copy and paste the following:

modHerbScanner.xml;

- Into These 2 Files:

*The Witcher 3\bin\config\r4game\user_config_matrix\pc\dx11filelist.txt
*The Witcher 3\bin\config\r4game\user_config_matrix\pc\dx12filelist.txt

NOTE: Some users have reported problems if this line is at the very end of the file list, if you have any issues displaying the menu then move the line further up the file list.

//--------------------------------------------------------
//-------------------------- End -------------------------
//--------------------------------------------------------