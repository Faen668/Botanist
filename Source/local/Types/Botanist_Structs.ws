
//---------------------------------------------------
//-- Botanist Tutorial Data Struct ------------------
//---------------------------------------------------

struct Botanist_Tutorial_Data
{
	var title    : string;
	var body     : string;
	var variable : name;
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
	var _int : int;
	var _name : name;
	
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

//---------------------------------------------------
//-- Botanist Lookup Mappin Struct ------------------
//---------------------------------------------------

struct Botanist_MapPinLookupData
{
	var hash	: int;
	var type	: BT_Herb_Enum;
	var region	: BT_Herb_Region;
	var grounds : bool;
}