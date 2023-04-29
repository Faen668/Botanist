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

[HerbScanner_GeneralSettings]
HerbScanner_Mod_Enabled=true
HerbScanner_DynamicMode_OnlyNeededQty=true
HerbScanner_DynamicMode_ShowMiniMap=false
HerbScanner_DynamicMode_ArrowPointers=false
HerbScanner_DynamicMode_Highlighted=false
HerbScanner_Global_RemoveIfEmpty=true
HerbScanner_Global_SearchRadius=9000
HerbScanner_Global_MaximumResults=100
HerbScanner_Global_MapPinSize=20
HerbScanner_DynamicMode_OverrideTarget=0

- Into These 2 Files:

*\Documents\The Witcher 3\user.settings
*\Documents\The Witcher 3\dx12user.settings (NG Only)

//--------------------------------------------------------
//-------- Adding Hotkey Support (Optional) --------------
//--------------------------------------------------------

- Copy and paste the following:

[Exploration]
IK_NumPad7=(Action=ScanForHerbs)
IK_NumPad8=(Action=ClearHerbPins)
[Horse]
IK_NumPad7=(Action=ScanForHerbs)
IK_NumPad8=(Action=ClearHerbPins)
[Swimming]
IK_NumPad7=(Action=ScanForHerbs)
IK_NumPad8=(Action=ClearHerbPins)
[Boat]
IK_NumPad7=(Action=ScanForHerbs)
IK_NumPad8=(Action=ClearHerbPins)
[BoatPassenger]
IK_NumPad7=(Action=ScanForHerbs)
IK_NumPad8=(Action=ClearHerbPins)
[Combat]
IK_NumPad7=(Action=ScanForHerbs)
IK_NumPad8=(Action=ClearHerbPins)
[Diving]
IK_NumPad7=(Action=ScanForHerbs)
IK_NumPad8=(Action=ClearHerbPins)

- Into This File:

*\Documents\The Witcher 3\input.settings

- Copy and paste the following:

			<!-- Herb Scanner Begin -->
			<Var builder="Input" id="ScanForHerbs" 		displayName="ScanForHerbs" 		displayType="INPUTPC" actions="ScanForHerbs"/>
			<Var builder="Input" id="ClearHerbPins" 	displayName="ClearHerbPins" 	displayType="INPUTPC" actions="ClearHerbPins"/>
			<!-- Herb Scanner End -->

- Into This File:

*\The Witcher 3\bin\config\r4game\user_config_matrix\pc\input.xml

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