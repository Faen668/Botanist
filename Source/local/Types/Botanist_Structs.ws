
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
	var recipes        : array<name>;
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