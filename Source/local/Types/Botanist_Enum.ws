//---------------------------------------------------
//-- Botanist User Settings Enums -------------------
//---------------------------------------------------

enum Botanist_UserSettings_Enum_Bool
{
	BT_Config_Ols_Enabled = 0,
	BT_Config_Pin_Enabled = 1,
	BT_Config_Hgr_Enabled = 2,
}

enum Botanist_UserSettings_Enum_Ints
{
	BT_Config_Mod_Targets 	= 0,
	BT_Config_Ols_Active 	= 1,
	BT_Config_Ols_Display 	= 2,
	BT_Config_Ols_Visible 	= 3,
	BT_Config_Ols_Fontsize 	= 4,
	BT_Config_Pin_Radius 	= 5,
	BT_Config_Hgr_Radius    = 6,
	BT_Config_Hgr_MinReq    = 7,
	BT_Config_Hgr_MaxAll    = 8,
	BT_Config_Hgr_MaxGrd    = 9,
	BT_Config_Mod_Quantity  = 10,
}

//---------------------------------------------------
//-- Botanist Herb Type Enum ------------------------
//---------------------------------------------------

enum BT_Herb_Enum
{
	BT_Invalid_Herb_Type   = 0,
	BT_Allspiceroot		   = 1,
	BT_Arenaria            = 2,
	BT_Balissefruit        = 3,
	BT_Beggartickblossoms  = 4,
	BT_Berbercanefruit     = 5,
	BT_Bloodmoss           = 6,
	BT_Blowbill            = 7,
	BT_Bryonia             = 8,
	BT_Buckthorn           = 9,
	BT_Celandine           = 10,
	BT_Cortinarius         = 11,
	BT_Crowseye            = 12,
	BT_Ergotseeds          = 13,
	BT_Foolsparsleyleaves  = 14,
	BT_Ginatiapetals       = 15,
	BT_Greenmold           = 16,
	BT_Han                 = 17,
	BT_Helleborepetals     = 18,
	BT_Honeysuckle         = 19,
	BT_Hopumbels           = 20,
	BT_Hornwort            = 21,
	BT_Longrube            = 22,
	BT_Mandrakeroot        = 23,
	BT_Mistletoe           = 24,
	BT_Moleyarrow          = 25,
	BT_Nostrix             = 26,
	BT_Pigskinpuffball     = 27,
	BT_Pringrape           = 28,
	BT_Ranogrin            = 29,
	BT_Ribleaf             = 30,
	BT_Sewantmushrooms     = 31,
	BT_Verbena             = 32,
	BT_Whitemyrtle         = 33,
	BT_Wolfsbane           = 34,
}

//---------------------------------------------------
//-- Botanist Region Enum ---------------------------
//---------------------------------------------------
		
enum BT_Herb_Region
{
	BT_Invalid_Location = 0,
	BT_WhiteOrchard		= 1,
	BT_NoMansLand   	= 2,
	BT_Skellige     	= 3,
	BT_KaerMorhen   	= 4,
	BT_Toussaint    	= 5,
}

//---------------------------------------------------
//-- Botanist Status Enum ---------------------------
//---------------------------------------------------

enum BT_Herb_Display_Status
{
	BT_Herb_Ready = 0,
	BT_Herb_Hidden = 1,
	BT_Herb_HarvestReady = 2,
	BT_Herb_In_Grounds = 3,
}

//---------------------------------------------------
//-- Botanist Events Enum ---------------------------
//---------------------------------------------------

enum BT_Event_Type
{
	BT_Herb_Looted = 0,
	BT_Herb_Reset = 1,
}