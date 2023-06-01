
//---------------------------------------------------
//-- Botanist User Settings Struct ------------------
//---------------------------------------------------

struct Botanist_UserSettings
{
	var bools : array<bool>;
	var ints  : array<int>;
}

//---------------------------------------------------
//-- Botanist Harvesting Grounds Data Transfer-------
//---------------------------------------------------

struct Botanist_DataTransferStruct
{
	var region         : BT_Herb_Region;
	var type           : BT_Herb_Enum;
	var quantity       : int;
	var user_settings  : Botanist_UserSettings;
	var storage        : Botanist_KnownEntityStorage;
}

//---------------------------------------------------
//-- Botanist Harvesting Grounds Results Struct -----
//---------------------------------------------------

struct Botanist_HarvestGroundResults 
{
  var harvesting_nodes : array<Botanist_NodePairing>;
  var filtered_nodes   : array<Botanist_NodePairing>;
}

//---------------------------------------------------
//-- Botanist Node Pairing Generation Struct --------
//---------------------------------------------------

struct Botanist_NodePairing
{
	var node : CNode;
	var herb : BT_Herb;
}

//---------------------------------------------------
//-- Botanist Event Data Struct ---------------------
//---------------------------------------------------

struct botanist_event_data
{
	//Event Type
	var type : BT_Event_Type;
	
	//For event sending
	var hash : int;
	
	//For new registrations
	var herb : BT_Herb;
	var harvesting_ground : BT_Harvesting_Ground;
}

//---------------------------------------------------
//-- Botanist Required Herbs Struct -----------------
//---------------------------------------------------

struct Botanist_HerbRequirements
{
	var names		: array<name>;
	var quantities	: array<int>;
}