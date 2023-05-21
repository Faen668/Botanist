//---------------------------------------------------
//-- Botanist Main Class ----------------------------
//---------------------------------------------------

statemachine class Botanist extends SU_BaseBootstrappedMod 
{
	public saved var BT_PersistentStorage 	: Botanist_Storage;
	public var BT_ConfigSettings			: Botanist_Config;
	public var BT_RenderingLoop				: Botanist_UIRenderLoop;
	public var BT_AlchemyManager			: Botanist_AlchemyManager;
	
	default tag 							= 'Botanist_BootStrapper';

	//-----------------------------------------------
	
	public function start() : void
	{					
		this.BT_ConfigSettings = new Botanist_Config in this;
		this.BT_RenderingLoop  = new Botanist_UIRenderLoop in this;
		this.BT_AlchemyManager = new Botanist_AlchemyManager in this;

		this.GotoState('Initialising');
	}
	
	//-----------------------------------------------
	
	public function SetEntityKnown(potential_herb: W3RefillableContainer) : void
	{	
		var herb_entity		: W3Herb;
		var herb_tag		: name;
		var herb_guid		: int;
		var created_herb  	: BT_Herb;
		
		herb_entity = (W3Herb)potential_herb;
		herb_guid = herb_entity.GetGuidHash();
		herb_entity.GetStaticMapPinTag(herb_tag);
		
		if ( herb_entity && BT_IsValidHerb(herb_tag) && !this.BT_PersistentStorage.BT_HerbStorage.botanist_known_herbs_guid_hashes.Contains(herb_guid) )
		{
			created_herb = (new BT_Herb in this).create_new_herb(herb_entity, herb_entity.GetWorldPosition(), herb_tag, herb_guid, theGame.GetCommonMapManager().GetCurrentArea(), this);
		}
	}

	//-----------------------------------------------
	
	public function SetEntityLooted(potential_herb: W3RefillableContainer) : void
	{	
		BT_PersistentStorage.BT_EventHandler.send_event( botanist_event_data( BT_Herb_Looted, potential_herb.GetGuidHash() ) );
	}
}

//---------------------------------------------------
//-- Botanist Main Class - (Idle State) -------------
//---------------------------------------------------

state Idle in Botanist 
{
	event OnEnterState(previous_state_name: name) 
	{
		super.OnEnterState(previous_state_name);
		BT_Logger("Main Class Entered state [Idle]");
		
		//this.test_entities();
	}
	
	//-----------------------------------------------
	
	entry function test_entities() : void // Only For Testing
	{
		var ents : array<CGameplayEntity>;
		var Idx : int;
		
		FindGameplayEntitiesCloseToPoint(ents, GetWitcherPlayer().GetWorldPosition(), 100000000, 100000000, , , ,'W3Container');
		
		for( Idx = 0; Idx < ents.Size(); Idx += 1 )
		{
			parent.SetEntityKnown( (W3Herb)ents[Idx] );
		}
		GetWitcherPlayer().DisplayHudMessage(ents.Size());
	}
}

//---------------------------------------------------
//-- Botanist Main Class - (Initialising State) -----
//---------------------------------------------------

state Initialising in Botanist 
{
	private var curVersionStr: string;
		default curVersionStr = "1.0.0";
		
	private var curVersionInt: int;
		default curVersionInt = 100;
	
	private var hasUpdated: bool;
		default hasUpdated = false;
	
	private var initStr: string;
		default initStr = "BT_Initialised";
		
	private var VersStr: string;
		default VersStr = "Botanist_CurrentModVersion";

	//-----------------------------------------------
		
	event OnEnterState(previous_state_name: name) 
	{
		super.OnEnterState(previous_state_name);
		BT_Logger("Main Class Entered state [Initialising]");
		
		this.Initialising_Main();
	}

	//-----------------------------------------------
	
	entry function Initialising_Main() : void
	{	
		var Idx: int;

		while (theGame.IsLoadingScreenVideoPlaying()) 
		{
		  Sleep(1);
		}
		
		this.SetModVersion();
		BT_LoadStorageCollection(parent);
		
		parent.BT_AlchemyManager	.initialise(parent);
		parent.BT_ConfigSettings 	.initialise(parent);
		parent.BT_RenderingLoop		.initialise(parent);
		parent.GotoState('Idle');
	}
	
	//-----------------------------------------------

	latent function SetModVersion() : void
	{		
		if (FactsQuerySum(initStr) != 1) 
		{
			FactsSet(initStr, 1);
			FactsSet(VersStr, curVersionInt);
			
			GetWitcherPlayer().DisplayHudMessage( StrReplace(GetLocStringByKeyExt("BT_Message_Install"), "[REPLACE]", curVersionStr) );
			return;
		}

		this.UpdateMod();	
		
		if (hasUpdated) 
		{
			GetWitcherPlayer().DisplayHudMessage( StrReplace(GetLocStringByKeyExt("BT_Message_Updated"), "[REPLACE]", curVersionStr) );
		}
	}
	
	//-----------------------------------------------
	
	latent function UpdateMod() : void
	{
		if (FactsQuerySum(VersStr) < curVersionInt) 
		{
			if (FactsQuerySum(VersStr) < 100) { FactsSet(VersStr, 100); hasUpdated = true; }
		}
	}
}

//---------------------------------------------------
//--Botanist Alchemy Manager Class ------------------
//---------------------------------------------------

class Botanist_AlchemyManager
{
	var master : Botanist;
	var storage : Botanist_KnownEntityStorage;
	
	//-----------------------------------------------
	
	public function initialise(master: Botanist) : void
	{
		this.master = master;
		this.storage = master.BT_PersistentStorage.BT_HerbStorage;
	}
	
	//-----------------------------------------------
	
	public function get_alchemy_data(m_alchemyManager : W3AlchemyManager) : Botanist_RequiredHerbs
	{
		var output_data  : Botanist_RequiredHerbs = initialise_struct();
		var m_recipeList : array<SAlchemyRecipe>;
		var blank_array	 : array<name>;
		var herb_name    : name;
		var item_name  	 : name;
		var herb_quantity : int;
		var Idx, Edx, Rdx : int;
		
		//Obtain a list of all known recipes.
		m_recipeList = m_alchemyManager.GetRecipes(false);

		//Traverse Recipe List.
		for( Idx = 0; Idx < m_recipeList.Size(); Idx += 1 )
		{
			//Traverse Recipe Lists Required Ingredients.
			for( Edx = 0; Edx < m_recipeList[Idx].requiredIngredients.Size(); Edx += 1 )
			{	
				item_name = m_recipeList[Idx].cookedItemName;
				herb_name = m_recipeList[Idx].requiredIngredients[Edx].itemName;
				herb_quantity = m_recipeList[Idx].requiredIngredients[Edx].quantity;

				//If we have not discovered any plants in the current region of this type then ignore it.
				if ( !this.storage.has_discovered_plants_in_region( herb_name ) )
				{
					continue;
				}

				//Check to see if we need this herb for a previous recipe.
				Rdx = output_data.names.FindFirst( herb_name );

				if (Rdx != -1)
				{
					//If we know we already need this herb, increase the quantity for it and record the recipe its used for.
					output_data.quantities[Rdx] += herb_quantity;
					output_data.cookeditems[Rdx].PushBack( item_name );
				}
				else
				{
					//If we need this herb then record its name, quantity and the recipe its used for.
					output_data.names.PushBack( herb_name );
					output_data.quantities.PushBack( herb_quantity );
					
					blank_array = get_blank_name_array();
					blank_array.PushBack( item_name );
					output_data.cookeditems.PushBack( blank_array );
				}
			}
		}

		//Traverse output List.
		for( Idx = output_data.names.Size()-1; Idx >= 0; Idx -= 1 )
		{
			//Lower the quantity of the herbs needed for recipes by the amount the player already has in their inventory.
			output_data.quantities[Idx] -= thePlayer.inv.GetItemQuantityByName(output_data.names[Idx]);

			if ( output_data.quantities[Idx] <= 0 )
			{
				//If the quantity we need drops below or equal to 0, remove the herb from consideration as it's not needed.
				output_data.names.EraseFast(Idx);
				output_data.quantities.EraseFast(Idx);
				output_data.cookeditems.EraseFast(Idx);
			}
		}
		
		//Finished. Return the data.
		return output_data;
	}

	//-----------------------------------------------

	private function initialise_struct() : Botanist_RequiredHerbs
	{
		var output_data : Botanist_RequiredHerbs;
		return output_data;
	}

	//-----------------------------------------------

	private function get_blank_name_array() : array<name>
	{
		var output : array<name>;
		return output;
	}
}

//---------------------------------------------------
//-- Botanist Bootstrapper Class --------------------
//---------------------------------------------------

state Botanist_BootStrapper in SU_TinyBootstrapperManager extends BaseMod 
{
	public function getTag(): name 
	{
		return 'Botanist_BootStrapper';
	}
	
	//-----------------------------------------------
	
	public function getMod(): SU_BaseBootstrappedMod 
	{
		return new Botanist in parent;
	}
}

//---------------------------------------------------
//-- Botanist User Settings Class -------------------
//---------------------------------------------------

class Botanist_Config
{
	public var master : Botanist;
	
	//-----------------------------------------------

	public function initialise(master: Botanist) : void
	{
		this.master = master;
	}
	
	//-----------------------------------------------

	public function get_config_bool_name(Idx : int) : name
	{
		switch (Idx)
		{
		 case 0: return 'Botanist_Markers_Enabled';
		 case 1: return 'Botanist_MapPins_Enabled';	
		 case 2: return 'Botanist_Farming_Enabled';
		}
	}
	
	//-----------------------------------------------

	public function get_config_int_name(Idx : int) : name
	{
		switch (Idx)
		{
		 case 0: return 'Botanist_Mod_Targets';
		 case 1: return 'Botanist_Markers_Active';
		 case 2: return 'Botanist_Markers_Display';
		 case 3: return 'Botanist_Markers_Visible';
		 case 4: return 'Botanist_Markers_FontSize';
		 case 5: return 'Botanist_MapPins_Radius';
		 case 6: return 'Botanist_Farming_Radius';
		 case 7: return 'Botanist_Farming_MinReq';
		 case 8: return 'Botanist_Farming_MaxAll';
		 case 9: return 'Botanist_Farming_MaxGrd';
		}
	}
	
	//-----------------------------------------------

	public function get_user_settings() : Botanist_UserSettings
	{
		var output_data    : Botanist_UserSettings;
		var config_wrapper : CInGameConfigWrapper = theGame.GetInGameConfigWrapper();
		
		output_data.bools.PushBack(config_wrapper.GetVarValue('Botanist_HerbMarkers', 'Botanist_Markers_Enabled'));
		output_data.bools.PushBack(config_wrapper.GetVarValue('Botanist_GeneralSettings', 'Botanist_MapPins_Enabled'));
		output_data.bools.PushBack(config_wrapper.GetVarValue('Botanist_HarvestingGrounds', 'Botanist_Farming_Enabled'));
		
		output_data.ints.PushBack(StringToInt(config_wrapper.GetVarValue('Botanist_GeneralSettings', 'Botanist_Mod_Targets')));
		output_data.ints.PushBack(StringToInt(config_wrapper.GetVarValue('Botanist_HerbMarkers', 'Botanist_Markers_Active')));
		output_data.ints.PushBack(StringToInt(config_wrapper.GetVarValue('Botanist_HerbMarkers', 'Botanist_Markers_Display')));
		output_data.ints.PushBack(StringToInt(config_wrapper.GetVarValue('Botanist_HerbMarkers', 'Botanist_Markers_Visible')));
		output_data.ints.PushBack(StringToInt(config_wrapper.GetVarValue('Botanist_HerbMarkers', 'Botanist_Markers_FontSize')));	
		output_data.ints.PushBack(StringToInt(config_wrapper.GetVarValue('Botanist_GeneralSettings', 'Botanist_MapPins_Radius')));
		output_data.ints.PushBack(StringToInt(config_wrapper.GetVarValue('Botanist_HarvestingGrounds', 'Botanist_Farming_Radius')));
		output_data.ints.PushBack(StringToInt(config_wrapper.GetVarValue('Botanist_HarvestingGrounds', 'Botanist_Farming_MinReq')));
		output_data.ints.PushBack(StringToInt(config_wrapper.GetVarValue('Botanist_HarvestingGrounds', 'Botanist_Farming_MaxAll')));
		output_data.ints.PushBack(StringToInt(config_wrapper.GetVarValue('Botanist_HarvestingGrounds', 'Botanist_Farming_MaxGrd')));
		
		return output_data;
	}
}

//---------------------------------------------------
//-- Botanist Oneliner Extension Class --------------
//---------------------------------------------------

class BT_OneLiner extends SU_Oneliner
{
	var active_status : int;
	
	function getVisible(player_position: Vector): bool 
	{
		var fcs : bool = theGame.IsFocusModeActive();
		
		switch ( active_status )
		{
			case 0 : { return super.getVisible(player_position) && fcs; }
			case 1 : { return super.getVisible(player_position) && !fcs; }
			case 2 : { return super.getVisible(player_position); }
			case 3 : { return false; }
		}
	}
}

//---------------------------------------------------
//-- Botanist Map Pin Extension Class ---------------
//---------------------------------------------------

class BT_MapPin extends SU_MapPin
{
	function onPinUsed()
	{
		return;
	}
}

//---------------------------------------------------
//-- Botanist Main Herb Class -----------------------
//---------------------------------------------------

class BT_Herb
{
	var user_settings	: Botanist_UserSettings;
	var event_manager   : Botanist_EventHandler; 
	
	// Creation Data
	var herb_entity		: W3Herb;
	var herb_areaname	: BT_Herb_Region;
	var entity_storage  : Botanist_KnownEntityStorage;
	var world_position 	: Vector;
	var herb_tag		: name;
	var check_tag		: name;
	
	var herb_guidhash	: int;
	var icon_guidhash	: int;

	// Dynamic Marker Data
	var discovery_mode	: bool;
	
	// Dynamic Boon Data
	var herb_has_boon	: bool;
	var boon_total      : int;
	
	// 3D Marker Data
	var marker_status	: BT_Herb_Display_Status;
	var marker_manager	: SUOL_Manager;
	var mappin_manager	: SUMP_Manager;
	var herb_enum_type	: BT_Herb_Enum;
	var herb_marker		: BT_OneLiner;
	var icon_marker		: BT_OneLiner;
	var icon_path		: string;
	var localised_name	: string;
	
	// Map Pin Data
	var herb_recipe		: name;
	var herb_mappin		: BT_MapPin;
	
	default marker_status = BT_Herb_Hidden;
	default discovery_mode = true;

	//---------------------------------------------------
	//-- Logging Functions ------------------------------
	//---------------------------------------------------

	function get_info() : string
	{
		return "Herb Details: [HASH: " + this.herb_guidhash + "] [TYPE: " + this.herb_enum_type + "] [AREA: " + this.herb_areaname + "] [NAME: " + this.herb_tag + "] [CAN HARVEST: " + !this.is_looted() + "] [POSITION: " + this.world_position.X + ", " + this.world_position.Y + ", " + this.world_position.Z + ", " + this.world_position.W + "] [DISTANCE TO PLAYER: " + FloatToStringPrec( FloorF( SqrtF( VecDistanceSquared(thePlayer.GetWorldPosition(), world_position))), 0) + "]";
	}
	
	//---------------------------------------------------
	
	function print_info() : void
	{
		BT_Logger("Herb Details: [HASH: " + this.herb_guidhash + "] [TYPE: " + this.herb_enum_type +  "] [AREA: " + this.herb_areaname + "] [NAME: " + this.herb_tag + "] [CAN HARVEST: " + !this.is_looted() + "] [POSITION: " + this.world_position.X + ", " + this.world_position.Y + ", " + this.world_position.Z + ", " + this.world_position.W + "] [DISTANCE TO PLAYER: " + FloatToStringPrec( FloorF( SqrtF( VecDistanceSquared(thePlayer.GetWorldPosition(), world_position))), 0) + "]");
	}
	
	//---------------------------------------------------
	//-- Creation Functions -----------------------------
	//---------------------------------------------------
	
	function create_new_herb(herb_entity: W3Herb, world_position: Vector, herb_tag: name, herb_guidhash: int, herb_areaname: EAreaName, master : Botanist) : BT_Herb
	{
		var Idx : int;
		var hrb : BT_Herb;
		
		this.event_manager  = master.BT_PersistentStorage.BT_EventHandler;
		this.entity_storage = master.BT_PersistentStorage.BT_HerbStorage;
		
		this.herb_entity 	= herb_entity;
		
		this.herb_areaname 	= set_herb_region(herb_areaname);
		this.world_position = world_position;
		this.herb_tag 		= herb_tag;
		this.herb_guidhash 	= herb_guidhash;
		this.icon_guidhash	= herb_guidhash + 9854;
		this.herb_enum_type = botanist_get_herb_enum_from_name( this.herb_tag );
		this.marker_status  = BT_Herb_Ready; 
		
		this.marker_manager = master.BT_PersistentStorage.BT_HerbStorage.marker_manager;
		this.mappin_manager = master.BT_PersistentStorage.BT_HerbStorage.mappin_manager;
		
		this.icon_path		= thePlayer.GetInventory().GetItemIconPathByName(herb_tag);
		this.localised_name = GetLocStringByKeyExt(theGame.GetDefinitionsManager().GetItemLocalisationKeyName(herb_tag));
	
		this.add_herb_to_storage();
		
		this.event_manager.register_for_event( botanist_event_data(BT_Herb_Looted, , this) );
		return this;
	}
	
	//---------------------------------------------------
	
	function add_herb_to_storage() : void
	{
		this.entity_storage.botanist_known_herbs[herb_areaname][herb_enum_type].PushBack(this);
		this.entity_storage.botanist_known_herbs_guid_hashes.PushBack(herb_guidhash);

		this.entity_storage.botanist_master_herbs.PushBack(this);
		this.entity_storage.botanist_master_hashs.PushBack(herb_guidhash);
		this.entity_storage.botanist_master_names.PushBack(herb_tag);
		this.entity_storage.botanist_master_world.PushBack(world_position);
		
		this.print_info();
	}

	//---------------------------------------------------
	
	function attach_shared_util_pointers(mappin_manager : SUMP_Manager, marker_manager : SUOL_Manager) : bool
	{
		this.mappin_manager = mappin_manager;
		this.marker_manager = marker_manager;
		
		return (this.marker_manager && this.mappin_manager);
	}
	
	//---------------------------------------------------
	//-- Reset Functions --------------------------------
	//---------------------------------------------------
	
	function reset(remove_from_list : bool) : void
	{
		this.remove_markers(remove_from_list);

		if ( this.is_looted() )
		{
			this.marker_status = BT_Herb_Hidden;
		}
		else 
		{
			this.marker_status = BT_Herb_Ready;
		}	
	}
	
	//---------------------------------------------------
	
	function reset_entity( herb_entity : W3Herb ) : bool
	{
		this.herb_entity = herb_entity;
		return (herb_entity);
	}	
	
	//---------------------------------------------------
	
	function apply_boon(total : int) : void
	{
		this.herb_has_boon = true;
		this.boon_total = total;
	}

	//---------------------------------------------------
	
	function remove_boon() : void
	{
		this.herb_has_boon = false;
		this.boon_total = 0;
	}

	//---------------------------------------------------
	
	function set_in_harvesting_grounds() : void
	{
		this.marker_status = BT_Herb_In_Grounds;
	}

	//---------------------------------------------------
	
	function is_in_harvesting_grounds() : bool
	{
		return this.marker_status == BT_Herb_In_Grounds;
	}
	
	//---------------------------------------------------
	//-- Region Functions -------------------------------
	//---------------------------------------------------

	function set_herb_region(areaname : EAreaName) : BT_Herb_Region
	{
		switch( AreaTypeToName( areaname ) )
		{
			case "novigrad"			: return BT_NoMansLand;
			case "no_mans_land"		: return BT_NoMansLand;
			case "skellige"			: return BT_Skellige;
			case "kaer_morhen"		: return BT_KaerMorhen;
			case "prolog_village"	: return BT_WhiteOrchard;
			case "bob"				: return BT_Toussaint;
			default 				: return BT_Invalid_Location;
		}
	}

	//---------------------------------------------------

	function get_herb_region_string() : string
	{
		switch( this.herb_areaname )
		{
			case BT_NoMansLand:	 	return "novigrad";
			case BT_NoMansLand:	 	return "no_mans_land";
			case BT_Skellige:	 	return "skellige";
			case BT_KaerMorhen: 	return "kaer_morhen";
			case BT_WhiteOrchard: 	return "prolog_village";
			case BT_Toussaint: 		return "bob";
			default: 				return "";
		}
	}

	//---------------------------------------------------
	//-- Loot Functions ---------------------------------
	//---------------------------------------------------

	event On_herb_looted(hash : int) : void
	{
		if ( this.herb_guidhash == hash )
		{
			if ( this.herb_has_boon && this.is_in_harvesting_grounds() )
			{			
				GetWitcherPlayer().DisplayHudMessage("Harvesting Grounds: This plant yielded an extra " + this.boon_total + " herbs.");
				thePlayer.inv.AddAnItem(this.herb_tag, boon_total, false, false, true);
			}
			
			this.remove_boon();		
			this.reset( true );		
		}
	}

	//---------------------------------------------------
	
	function is_looted() : bool
	{
		var tag : name;
		
		this.herb_entity.GetStaticMapPinTag(tag);
		
		return tag == '' || tag == 'NONE';
	}

	//---------------------------------------------------
	
	function is_eligible_for_harvesting_grounds() : bool
	{		
		return !this.is_looted() && this.is_displayed() && !this.is_in_harvesting_grounds();
	}

	//---------------------------------------------------
	
	function is_eligible_for_normal_display() : bool
	{		
		return !this.is_looted() && !this.is_displayed() && !this.is_in_harvesting_grounds();
	}
	
	//---------------------------------------------------
	//-- 3D Markers & Map Pin Functions -----------------
	//---------------------------------------------------
	
	function set_displayed(user_settings : Botanist_UserSettings, recipe_name : name) : void
	{
		this.user_settings = user_settings;
		
		if ( this.is_displayed() )
		{
			return;
		}

		this.marker_status 	= BT_Herb_HarvestReady;
		this.herb_recipe 	= recipe_name;
		
		this.display_markers();	
	}

	//---------------------------------------------------
	
	function is_displayed() : bool
	{
		return this.entity_storage.botanist_displayed_herbs_guid_hashes.Contains(this.herb_guidhash);
	}
	
	//---------------------------------------------------
	
	function set_displayed_in_grounds(user_settings : Botanist_UserSettings) : void
	{
		this.reset( true );
		this.set_in_harvesting_grounds();
		this.user_settings = user_settings;		
		this.display_markers_for_harvesting_grounds();	
	}
	
	//---------------------------------------------------

	function update_markers() : void
	{
		if ( !herb_marker )
		{
			herb_marker					= new BT_OneLiner in this;
		}
		
		herb_marker.active_status		= this.user_settings.ints[BT_Config_Ols_Active];
		herb_marker.id					= this.herb_guidhash;
		herb_marker.text 				= this.get_marker_label();
		herb_marker.position 			= this.world_position;
		herb_marker.render_distance 	= this.get_marker_visibility_range();

		if ( !icon_marker )
		{
			icon_marker					= new BT_OneLiner in this;
		}
		
		icon_marker.active_status		= this.user_settings.ints[BT_Config_Ols_Active];
		icon_marker.id					= this.icon_guidhash;
		icon_marker.text 				= this.get_marker_iconpath();
		icon_marker.position 			= this.world_position;
		icon_marker.render_distance 	= this.get_marker_visibility_range();

		if ( !herb_mappin )
		{
			herb_mappin					= new BT_MapPin in this;
		}
		
		herb_mappin.tag 				= "Botanist_" + herb_guidhash;
		herb_mappin.label 				= get_mappin_label();
		herb_mappin.description 		= get_mappin_description();
		herb_mappin.radius				= get_mappin_radius();
		herb_mappin.position 			= Vector(world_position.X, world_position.Y);
		herb_mappin.region 				= get_herb_region_string();
		herb_mappin.type 				= "Herb";
		herb_mappin.is_quest 			= false;
		herb_mappin.appears_on_minimap 	= false;
		herb_mappin.pointed_by_arrow 	= false;
		herb_mappin.highlighted 		= false;
		herb_mappin.is_fast_travel		= false;
	}

	//---------------------------------------------------

	function update_markers_for_harvesting_grounds() : void
	{
		if ( !herb_marker )
		{
			herb_marker					= new BT_OneLiner in this;
		}
		
		herb_marker.active_status		= this.user_settings.ints[BT_Config_Ols_Active];
		herb_marker.id					= this.herb_guidhash;
		herb_marker.text 				= this.get_marker_label_for_harvesting_grounds();
		herb_marker.position 			= this.world_position;
		herb_marker.render_distance 	= this.get_marker_visibility_range();

		if ( !icon_marker )
		{
			icon_marker					= new BT_OneLiner in this;
		}
		
		icon_marker.active_status		= this.user_settings.ints[BT_Config_Ols_Active];
		icon_marker.id					= this.icon_guidhash;
		icon_marker.text 				= this.get_marker_iconpath();
		icon_marker.position 			= this.world_position;
		icon_marker.render_distance 	= this.get_marker_visibility_range();

		if ( !herb_mappin )
		{
			herb_mappin					= new BT_MapPin in this;
		}
		
		herb_mappin.tag 				= "Botanist_" + herb_guidhash;
		herb_mappin.label 				= get_mappin_label_for_harvesting_grounds();
		herb_mappin.description 		= get_mappin_description_for_harvesting_grounds();
		herb_mappin.radius				= get_mappin_radius();
		herb_mappin.position 			= Vector(world_position.X, world_position.Y);
		herb_mappin.region 				= get_herb_region_string();
		herb_mappin.type 				= "Herb";
		herb_mappin.is_quest 			= false;
		herb_mappin.appears_on_minimap 	= false;
		herb_mappin.pointed_by_arrow 	= false;
		herb_mappin.highlighted 		= false;
		herb_mappin.is_fast_travel		= false;
	}
	
	//---------------------------------------------------

	function display_markers() : void
	{
		this.update_markers();
		
		if (this.user_settings.bools[BT_Config_Ols_Enabled]  )
		{
			switch( this.user_settings.ints[BT_Config_Ols_Display] )
			{
				case 0: 
				{
					this.marker_manager.createOneliner( this.herb_marker ); 
					this.marker_manager.createOneliner( this.icon_marker );
					break;
				}

				case 1: 
				{
					this.marker_manager.createOneliner( this.herb_marker ); 
					break;
				}
				
				case 2: 
				{
					this.marker_manager.createOneliner( this.icon_marker );
					break;
				}
			}
		}
		
		this.entity_storage.botanist_displayed_herbs[herb_areaname][herb_enum_type].PushBack( this );
		this.entity_storage.botanist_displayed_herbs_guid_hashes.PushBack( this.herb_guidhash );

		if ( !this.mappin_manager.mappins.Contains( this.herb_mappin ) && this.user_settings.bools[BT_Config_Pin_Enabled] )
		{
			this.mappin_manager.mappins.PushBack( this.herb_mappin );
		}
	}

	//---------------------------------------------------

	function display_markers_for_harvesting_grounds() : void
	{
		this.update_markers_for_harvesting_grounds();
		
		if (this.user_settings.bools[BT_Config_Ols_Enabled]  )
		{
			switch( this.user_settings.ints[BT_Config_Ols_Display] )
			{
				case 0: 
				{
					this.marker_manager.createOneliner( this.herb_marker ); 
					this.marker_manager.createOneliner( this.icon_marker );
					break;
				}

				case 1: 
				{
					this.marker_manager.createOneliner( this.herb_marker ); 
					break;
				}
				
				case 2: 
				{
					this.marker_manager.createOneliner( this.icon_marker );
					break;
				}
			}
		}
		
		if ( !this.mappin_manager.mappins.Contains( this.herb_mappin ) && this.user_settings.bools[BT_Config_Pin_Enabled] )
		{
			this.mappin_manager.mappins.PushBack( this.herb_mappin );
		}
	}
	
	//---------------------------------------------------

	function remove_markers(remove_from_list : bool) : void
	{
		if ( remove_from_list )
		{
			this.entity_storage.botanist_displayed_herbs[herb_areaname][herb_enum_type].Remove( this );
			this.entity_storage.botanist_displayed_herbs_guid_hashes.Remove( this.herb_guidhash );
		}
		
		this.marker_manager.deleteOneliner( (SU_Oneliner)this.herb_marker );
		this.marker_manager.deleteOneliner( (SU_Oneliner)this.icon_marker );
		
		SU_removeCustomPinByTag("Botanist_" + herb_guidhash);	
	}
	
	//---------------------------------------------------
	
	function get_marker_visibility_range() : int
	{
		switch( this.user_settings.ints[BT_Config_Ols_Visible] )
		{
			case 0: return 10;
			case 1: return 25;
			case 2: return 75;
			case 3: return 115;
			case 4: return 150;
		}
	}
	
	//---------------------------------------------------

	function get_marker_label() : string
	{
		return "<font size='" + this.user_settings.ints[BT_Config_Ols_Fontsize] + "'>" + this.localised_name + GetLocStringByKeyExt("BT_HerbLootable") + "</font>";
	}

	//---------------------------------------------------

	function get_marker_label_for_harvesting_grounds() : string
	{
		return "<font size='" + this.user_settings.ints[BT_Config_Ols_Fontsize] + "'>" + this.localised_name + GetLocStringByKeyExt("BT_HerbLootable_HG") + "</font>";
	}
	
	//---------------------------------------------------

	function get_mappin_label() : string
	{
		return this.localised_name + GetLocStringByKeyExt("BT_HerbLootable");
	}

	//---------------------------------------------------

	function get_mappin_label_for_harvesting_grounds() : string
	{
		return this.localised_name + GetLocStringByKeyExt("BT_HerbLootable_HG");
	}
	
	//---------------------------------------------------

	function get_marker_iconpath() : string
	{
		var fontSize : int = this.user_settings.ints[BT_Config_Ols_Fontsize];
		return "<img src='img://" + icon_path + "' height='" + (fontSize + 30) + "' width='" + (fontSize + 30) + "' vspace='" + (fontSize) + "' />&nbsp;";
	}

	//---------------------------------------------------
	
	function get_mappin_description() : string
	{
		if ( !this.discovery_mode )
		{
			return "A common herb used for various recipes";
		}
		return "A common herb used to create <font color='#D7D23A'>" + this.get_marker_recipe() + "</font>";
	}

	//---------------------------------------------------
	
	function get_mappin_description_for_harvesting_grounds() : string
	{
		return "Harvest this plant for a chance to recieve bonus herbs!";
	}
	
	//---------------------------------------------------
	
	function get_marker_recipe() : string
	{
		return GetLocStringByKeyExt( theGame.GetDefinitionsManager().GetItemLocalisationKeyName( this.herb_recipe ) );
	}

	//---------------------------------------------------
	
	function get_mappin_radius() : int
	{
		return this.user_settings.ints[BT_Config_Pin_Radius] ;
	}
}

//---------------------------------------------------
//-- Botanist Event Manager Class -------------------
//---------------------------------------------------

class Botanist_EventHandler 
{
	private var on_herb_looted_registrations : array< BT_Herb >;
	private var on_herb_looted_registrations_hg : array< BT_Harvesting_Ground >;
	
	//-----------------------------------------------
	
	public function get_registration_count() : int
	{
		return on_herb_looted_registrations.Size() + on_herb_looted_registrations_hg.Size();
	}
	
	//-----------------------------------------------
	
	public function send_event( data : botanist_event_data ) : void
	{
		var Idx : int;
		
		switch ( data.type )
		{
			case BT_Herb_Looted : 
			{
				for (Idx = 0; Idx < this.on_herb_looted_registrations_hg.Size(); Idx += 1) 
				{
					this.on_herb_looted_registrations_hg[Idx].On_herb_looted( data.hash );
				}

				for (Idx = 0; Idx < this.on_herb_looted_registrations.Size(); Idx += 1) 
				{
					this.on_herb_looted_registrations[Idx].On_herb_looted( data.hash );
				}	
			}
			
			default : 
				break;
		}
	}
	
	//-----------------------------------------------
	
	public function register_for_event( data : botanist_event_data ) : void
	{
		switch ( data.type )
		{
			case BT_Herb_Looted : 
			{
				if ( data.harvesting_ground ) {
					this.on_herb_looted_registrations_hg.PushBack( data.harvesting_ground );
				}

				if ( data.herb ) {
					this.on_herb_looted_registrations.PushBack( data.herb );
				}				
			}
			
			default : break;
		}
	}
	
	//-----------------------------------------------
	
	public function unregister_for_event( data : botanist_event_data ) : void
	{
		switch ( data.type )
		{
			case BT_Herb_Looted : 
			{
				if ( data.harvesting_ground ) {
					this.on_herb_looted_registrations_hg.Remove( data.harvesting_ground );
				}

				if ( data.herb ) {
					this.on_herb_looted_registrations.Remove( data.herb );
				}				
			}
			
			default : break;
		}
	}
}

//---------------------------------------------------
//-- Botanist Main Harvesting Grounds Class ---------
//---------------------------------------------------

class BT_Harvesting_Ground
{
	var event_manager   : Botanist_EventHandler; 
	var user_settings	: Botanist_UserSettings;
	var entity_storage  : Botanist_KnownEntityStorage;
	var config          : Botanist_Config;
	
	// Creation Data
	var spot_herbs	: array<Botanist_NodePairing>;
	var spot_region	: BT_Herb_Region;
	var spot_type	: BT_Herb_Enum;
	var spot_hash	: int;
	var spot_total  : int;

	// Map Pin Data
	var mappin_manager	: SUMP_Manager;
	var mappin		    : BT_MapPin;
	var mappin_pos	    : Vector;
	var mappin_rad	    : float;
	var mappin_name  	: string;
	
	//---------------------------------------------------
	//-- Logging Functions ------------------------------
	//---------------------------------------------------

	function print_info() : void
	{
		BT_Logger("Harvesting Ground Details: [HASH: " + this.spot_hash + "] [AREA: " + this.spot_region + "] [TYPE: " + this.spot_type + "] [POSITION: " + this.mappin_pos.X + ", " + this.mappin_pos.Y + ", " + this.mappin_pos.Z + ", " + this.mappin_pos.W + "] [DISTANCE TO PLAYER: " + FloatToStringPrec( FloorF( SqrtF( VecDistanceSquared(thePlayer.GetWorldPosition(), this.mappin_pos))), 0) + "]");
	}
	
	//---------------------------------------------------
	//-- Creation Functions -----------------------------
	//---------------------------------------------------
	
	function create(Harvest_Grounds_Results  : Botanist_HarvestGroundResults, region : BT_Herb_Region, type : BT_Herb_Enum, mappin_rad	: float, mappin_pos	: Vector, master : Botanist, user_settings : Botanist_UserSettings) : BT_Harvesting_Ground
	{
		this.event_manager   = master.BT_PersistentStorage.BT_EventHandler;
		this.entity_storage  = master.BT_PersistentStorage.BT_HerbStorage;
		this.config          = master.BT_ConfigSettings;
		
		this.user_settings   = user_settings;
		
		this.spot_herbs      = Harvest_Grounds_Results.harvesting_nodes;
		this.spot_region     = region;
		this.spot_type       = type;
		this.spot_hash		 = spot_herbs[0].herb.herb_guidhash + 6558;
		this.spot_total		 = spot_herbs.Size();
		
		this.mappin_manager  = this.entity_storage.mappin_manager;
		this.mappin_pos      = mappin_pos;
		this.mappin_rad      = mappin_rad;
		this.mappin_name     = GetLocStringByKeyExt(theGame.GetDefinitionsManager().GetItemLocalisationKeyName( botanist_get_herb_name_from_enum( this.spot_type ) ));
		this.apply_random_boon();
		
		this.display_farming_spot();
		this.print_info();
		
		this.event_manager.register_for_event( botanist_event_data(BT_Herb_Looted, , , this) );
		
		this.GotoState('update');
		return this;
	}

	//---------------------------------------------------
	
	function load(user_settings : Botanist_UserSettings)
	{
		var Idx : int;
		
		this.user_settings = user_settings;
		
		if ( !user_settings.bools[BT_Config_Hgr_Enabled] )
		{
			this.remove_farming_spot();
			return;			
		}
		
		for( Idx = this.spot_herbs.Size()-1; Idx >= 0 ; Idx -= 1 )
		{
			if ( !this.spot_herbs[Idx].herb.is_looted() )
			{
				this.spot_herbs[Idx].herb.set_displayed_in_grounds(this.user_settings);
				continue;
			}

			this.spot_herbs[Idx].herb.reset( true );
			this.spot_herbs.EraseFast(Idx);
		}
		
		this.event_manager.register_for_event( botanist_event_data(BT_Herb_Looted, , , this) );
		this.display_farming_spot();
		this.update_mappin_description();
	}

	//---------------------------------------------------
	
	function update(user_settings : Botanist_UserSettings)
	{	
		this.user_settings = user_settings;
		this.GotoState('update');
	}
	
	//---------------------------------------------------
	
	function update_mappin_description() : void
	{
		var Idx : int = this.mappin_manager.mappins.FindFirst(this.mappin);

		if ( Idx != -1 )
		{
			this.mappin_manager.mappins[Idx].description = this.get_mappin_description();
		}
	}

	//---------------------------------------------------
	
	event On_herb_looted(hash : int) : void
	{
		var Idx : int;
		
		for( Idx = this.spot_herbs.Size()-1; Idx >= 0 ; Idx -= 1 )
		{
			if ( this.spot_herbs[Idx].herb.herb_guidhash == hash )
			{
				this.spot_herbs[Idx].herb.reset( true );
				this.spot_herbs.EraseFast(Idx);
				break;
			}
		}
		
		if ( this.spot_herbs.Size() <= 0 )
		{
			this.remove_farming_spot();
		}
		
		this.update_mappin_description();
	}
	
	//---------------------------------------------------
	
	function apply_random_boon() : void
	{
		this.spot_herbs[RandRange(this.spot_herbs.Size(), 0)].herb.apply_boon(this.spot_total);
	}
	
	//---------------------------------------------------
	//-- Display Functions ------------------------------
	//---------------------------------------------------
	
	function is_displayed() : bool
	{
		return this.entity_storage.botanist_displayed_harvesting_grounds_guid_hashes.Contains( this.spot_hash );
	}

	//---------------------------------------------------

	function display_farming_spot() : void
	{
		if ( !this.is_displayed() )
		{
			if ( !mappin )
			{
				mappin				    = new BT_MapPin in this;
			}

			mappin.tag 				    = "Botanist_Harvesting_Ground_" + this.spot_hash;		
			mappin.label 			    = this.get_mappin_label();
			mappin.radius				= this.mappin_rad;
			mappin.position 			= this.mappin_pos;
			mappin.description 		    = this.get_mappin_description();
			mappin.region 				= this.get_herb_region_string();
			mappin.type 				= "Herbalist";
			mappin.filtered_type 		= "Herbalist";
			mappin.is_quest 			= false;
			mappin.appears_on_minimap 	= false;
			mappin.pointed_by_arrow 	= false;
			mappin.highlighted 		    = false;
			mappin.is_fast_travel		= true;	

			if ( !this.mappin_manager.mappins.Contains( this.mappin ) )
			{
				 this.mappin_manager.mappins.PushBack( this.mappin );
			}

			this.entity_storage.botanist_displayed_harvesting_grounds[spot_region][spot_type].PushBack( this );
			this.entity_storage.botanist_displayed_harvesting_grounds_guid_hashes.PushBack( this.spot_hash );
		}
	}
	
	//---------------------------------------------------

	function remove_farming_spot() : void
	{
		var Idx : int;
		
		this.event_manager.unregister_for_event( botanist_event_data(BT_Herb_Looted, , , this) );
		
		for( Idx = this.spot_herbs.Size()-1; Idx >= 0 ; Idx -= 1 )
		{
			this.spot_herbs[Idx].herb.reset( true );
		}
		this.spot_herbs.Clear();
			
		SU_removeCustomPinByTag( "Botanist_Harvesting_Ground_" + this.spot_hash );
		this.entity_storage.botanist_displayed_harvesting_grounds[spot_region][spot_type].Remove( this );
		this.entity_storage.botanist_displayed_harvesting_grounds_guid_hashes.Remove( this.spot_hash );
		this.GotoState('disabled');
	}

	//---------------------------------------------------

	function get_mappin_label() : string
	{
		return StrReplace(GetLocStringByKeyExt("BT_HarvestingGrounds"), "[NAME]", this.mappin_name);
	}
	
	//---------------------------------------------------
	
	function get_mappin_description() : string
	{
		var description : string = GetLocStringByKeyExt("BT_HarvestingGrounds_Description");
		
		description = StrReplace(description, "[NAME]", this.mappin_name);
		description = StrReplace(description, "[COUNT]", this.spot_herbs.Size());

		return description;
	}
	
	//---------------------------------------------------

	function get_herb_region_string() : string
	{
		switch( this.spot_region )
		{
			case BT_NoMansLand:	 	return "novigrad";
			case BT_NoMansLand:	 	return "no_mans_land";
			case BT_Skellige:	 	return "skellige";
			case BT_KaerMorhen: 	return "kaer_morhen";
			case BT_WhiteOrchard: 	return "prolog_village";
			case BT_Toussaint: 		return "bob";
			default: 				return "";
		}
	}
}

//---------------------------------------------------
//-- Botanist Main Harvesting Grounds States --------
//---------------------------------------------------

state disabled in BT_Harvesting_Ground 
{
	event OnEnterState(previous_state_name: name) 
	{
		super.OnEnterState(previous_state_name);
		BT_Logger(parent.spot_hash + "Entered state [disabled]");
	}
}

//---------------------------------------------------
//-- Botanist Main Harvesting Grounds States --------
//---------------------------------------------------

state waiting in BT_Harvesting_Ground 
{
	event OnEnterState(previous_state_name: name) 
	{
		super.OnEnterState(previous_state_name);
		BT_Logger(parent.spot_hash + "Entered state [waiting]");
	}
}

//---------------------------------------------------
//-- Botanist Main Harvesting Grounds States --------
//---------------------------------------------------

state update in BT_Harvesting_Ground 
{
	event OnEnterState(previous_state_name: name) 
	{	
		var Idx : int;
		
		super.OnEnterState(previous_state_name);
		BT_Logger(parent.spot_hash + "Entered state [update]");
		
		for( Idx = parent.spot_herbs.Size()-1; Idx >= 0 ; Idx -= 1 )
		{
			parent.spot_herbs[Idx].herb.set_displayed_in_grounds(parent.user_settings);
		}

		parent.GotoState('waiting');
	}
}
//---------------------------------------------------
//-- Functions --------------------------------------
//---------------------------------------------------

function Get_Botanist(out master: Botanist, optional caller: string): bool 
{
	BT_Logger("Get_Botanist Called by [" + caller + "]");
	master = (Botanist)SUTB_getModByTag('Botanist_BootStrapper');
	
	if (master)
	{
		return true;
	}
	return false;
}

//---------------------------------------------------
//-- Functions --------------------------------------
//---------------------------------------------------

function BT_SetEntityKnown(ent: W3RefillableContainer) : void
{
	var master : Botanist;

	if (!Get_Botanist(master, 'BT_SetEntityKnown'))
	{
		return;
	}
	master.SetEntityKnown(ent);
}
	
//---------------------------------------------------
//-- Functions --------------------------------------
//---------------------------------------------------

function BT_SetEntityLooted(ent: W3RefillableContainer) : void
{
	var master : Botanist;
	
	if (!Get_Botanist(master, 'BT_SetEntityLooted'))
	{
		return;
	}
	master.SetEntityLooted(ent);
}

//---------------------------------------------------
//-- Functions --------------------------------------
//---------------------------------------------------

function BT_Logger(message: string, optional ShowInGUI: bool) : void
{	
	LogChannel('Botanist', message);
  
	if (ShowInGUI)
	{
		GetWitcherPlayer().DisplayHudMessage("Botanist: " + message);
	}
}

//---------------------------------------------------
//-- Functions --------------------------------------
//---------------------------------------------------

function BT_IsPlayerBusy(): bool 
{
	return thePlayer.IsInNonGameplayCutscene()
		|| theGame.IsLoadingScreenVideoPlaying()
		|| thePlayer.IsInGameplayScene()
		|| thePlayer.IsCiri()
		|| theGame.IsDialogOrCutscenePlaying()
		|| theGame.IsCurrentlyPlayingNonGameplayScene()
		|| theGame.IsFading()
		|| theGame.IsBlackscreen()
		|| thePlayer.IsInFistFightMiniGame()
		|| thePlayer.IsInCombat()
		|| !thePlayer.IsAlive();
}

//---------------------------------------------------
//-- Functions --------------------------------------
//---------------------------------------------------

function BT_VectorToString(vec : Vector): string 
{
	return vec.X + ", " + vec.Y + ", " + vec.Z + ", " + vec.W;
}

//---------------------------------------------------
//-- Enum Return Functions --------------------------
//---------------------------------------------------

function botanist_get_herb_enum_from_name(herb_tag : name) : BT_Herb_Enum
{
	switch(herb_tag)
	{
	case 'Allspice root':        { return BT_Allspiceroot; }
	case 'Arenaria':             { return BT_Arenaria; }
	case 'Balisse fruit':        { return BT_Balissefruit; }
	case 'Beggartick blossoms':  { return BT_Beggartickblossoms; }
	case 'Berbercane fruit':     { return BT_Berbercanefruit; }
	case 'Bloodmoss':            { return BT_Bloodmoss; }
	case 'Blowbill':             { return BT_Blowbill; }
	case 'Bryonia':              { return BT_Bryonia; }
	case 'Buckthorn':            { return BT_Buckthorn; }
	case 'Celandine':            { return BT_Celandine; }
	case 'Cortinarius':          { return BT_Cortinarius; }
	case 'Crows eye':            { return BT_Crowseye; }
	case 'Ergot seeds':          { return BT_Ergotseeds; }
	case 'Fools parsley leaves': { return BT_Foolsparsleyleaves; }
	case 'Ginatia petals':       { return BT_Ginatiapetals; }
	case 'Green mold':           { return BT_Greenmold; }
	case 'Han':                  { return BT_Han; }
	case 'Hellebore petals':     { return BT_Helleborepetals; }
	case 'Honeysuckle':          { return BT_Honeysuckle; }
	case 'Hop umbels':           { return BT_Hopumbels; }
	case 'Hornwort':             { return BT_Hornwort; }
	case 'Longrube':             { return BT_Longrube; }
	case 'Mandrake root':        { return BT_Mandrakeroot; }
	case 'Mistletoe':            { return BT_Mistletoe; }
	case 'Moleyarrow':           { return BT_Moleyarrow; }
	case 'Nostrix':              { return BT_Nostrix; }
	case 'Pigskin puffball':     { return BT_Pigskinpuffball; }
	case 'Pringrape':            { return BT_Pringrape; }
	case 'Ranogrin':             { return BT_Ranogrin; }
	case 'Ribleaf':              { return BT_Ribleaf; }
	case 'Sewant mushrooms':     { return BT_Sewantmushrooms; }
	case 'Verbena':              { return BT_Verbena; }
	case 'White myrtle':         { return BT_Whitemyrtle; }
	case 'Wolfsbane':            { return BT_Wolfsbane; }
	default : return BT_Invalid_Herb_Type;
	}
}

//---------------------------------------------------
//-- Enum Return Functions --------------------------
//---------------------------------------------------

function botanist_get_herb_name_from_enum(value : int) : name
{
	switch(value)
	{
	case BT_Allspiceroot:        return 'Allspice root';        
	case BT_Arenaria:            return 'Arenaria';             
	case BT_Balissefruit:        return 'Balisse fruit';        
	case BT_Beggartickblossoms:  return 'Beggartick blossoms';  
	case BT_Berbercanefruit:     return 'Berbercane fruit';     
	case BT_Bloodmoss:           return 'Bloodmoss';            
	case BT_Blowbill:            return 'Blowbill';             
	case BT_Bryonia:             return 'Bryonia';              
	case BT_Buckthorn:           return 'Buckthorn';            
	case BT_Celandine:           return 'Celandine';            
	case BT_Cortinarius:         return 'Cortinarius';          
	case BT_Crowseye:            return 'Crows eye';            
	case BT_Ergotseeds:          return 'Ergot seeds';          
	case BT_Foolsparsleyleaves:  return 'Fools parsley leaves'; 
	case BT_Ginatiapetals:       return 'Ginatia petals';       
	case BT_Greenmold:           return 'Green mold';           
	case BT_Han:                 return 'Han';                  
	case BT_Helleborepetals:     return 'Hellebore petals';     
	case BT_Honeysuckle:         return 'Honeysuckle';          
	case BT_Hopumbels:           return 'Hop umbels';           
	case BT_Hornwort:            return 'Hornwort';             
	case BT_Longrube:            return 'Longrube';             
	case BT_Mandrakeroot:        return 'Mandrake root';        
	case BT_Mistletoe:           return 'Mistletoe';            
	case BT_Moleyarrow:          return 'Moleyarrow';           
	case BT_Nostrix:             return 'Nostrix';              
	case BT_Pigskinpuffball:     return 'Pigskin puffball';     
	case BT_Pringrape:           return 'Pringrape';            
	case BT_Ranogrin:            return 'Ranogrin';             
	case BT_Ribleaf:             return 'Ribleaf';              
	case BT_Sewantmushrooms:     return 'Sewant mushrooms';     
	case BT_Verbena:             return 'Verbena';              
	case BT_Whitemyrtle:         return 'White myrtle';         
	case BT_Wolfsbane:           return 'Wolfsbane';            
	default : return '';
	}
}

//---------------------------------------------------
//-- Enum Return Functions --------------------------
//---------------------------------------------------

function botanist_get_herb_enum_region() : BT_Herb_Region
{
	switch( AreaTypeToName(theGame.GetCommonMapManager().GetCurrentArea()) )
	{
		case "novigrad"			: return BT_NoMansLand;
		case "no_mans_land"		: return BT_NoMansLand;
		case "skellige"			: return BT_Skellige;
		case "kaer_morhen"		: return BT_KaerMorhen;
		case "prolog_village"	: return BT_WhiteOrchard;
		case "bob"				: return BT_Toussaint;
		default 				: return BT_Invalid_Location;
	}
}
	
//---------------------------------------------------
//-- Herb Validity Functions ------------------------
//---------------------------------------------------

function BT_IsValidHerb(itemName : name) : bool
{	
	switch(itemName) 
	{
	case 'Allspice root':
	case 'Arenaria':
	case 'Balisse fruit':
	case 'Beggartick blossoms':
	case 'Berbercane fruit':
	case 'Bloodmoss':
	case 'Blowbill':
	case 'Bryonia':
	case 'Buckthorn':
	case 'Celandine':
	case 'Cortinarius':
	case 'Crows eye':
	case 'Ergot seeds':
	case 'Fools parsley leaves':
	case 'Ginatia petals':
	case 'Green mold':
	case 'Han':
	case 'Hellebore petals':
	case 'Honeysuckle':
	case 'Hop umbels':
	case 'Hornwort':
	case 'Longrube':
	case 'Mandrake root':
	case 'Mistletoe':
	case 'Moleyarrow':
	case 'Nostrix':
	case 'Pigskin puffball':
	case 'Pringrape':
	case 'Ranogrin':
	case 'Ribleaf':
	case 'Sewant mushrooms':
	case 'Verbena':
	case 'White myrtle':
	case 'Wolfsbane':
		return true;
	
	default: 
		return false;
	}
}

//---------------------------------------------------
//-- Herb Override Functions ------------------------
//---------------------------------------------------

function BT_GetOverrideEnumValue( herb_name : name ) : BT_Herb_Enum
{
	return botanist_get_herb_enum_from_name( herb_name );
}

//---------------------------------------------------
//-- Herb Override Functions ------------------------
//---------------------------------------------------

function BT_GetOverrideItemName(value: float) : name
{	
	switch(value)
	{
	case  1: return 'Allspice root';				
	case  2: return 'Arenaria';
	case  3: return 'Balisse fruit';
	case  4: return 'Beggartick blossoms';
	case  5: return 'Berbercane fruit';
	case  6: return 'Bloodmoss';
	case  7: return 'Blowbill';
	case  8: return 'Bryonia';
	case  9: return 'Buckthorn';
	case 10: return 'Celandine';
	case 11: return 'Cortinarius';
	case 12: return 'Crows eye';
	case 13: return 'Ergot seeds';
	case 14: return 'Fools parsley leaves';
	case 15: return 'Ginatia petals';
	case 16: return 'Green mold';
	case 17: return 'Han';
	case 18: return 'Hellebore petals';
	case 19: return 'Honeysuckle';
	case 20: return 'Hop umbels';
	case 21: return 'Hornwort';
	case 22: return 'Longrube';
	case 23: return 'Mandrake root';
	case 24: return 'Mistletoe';
	case 25: return 'Moleyarrow';
	case 26: return 'Nostrix';
	case 27: return 'Pigskin puffball';
	case 28: return 'Pringrape';
	case 29: return 'Ranogrin';
	case 30: return 'Ribleaf';
	case 31: return 'Sewant mushrooms';
	case 32: return 'Verbena';
	case 33: return 'White myrtle';
	case 34: return 'Wolfsbane';
	default: return '';
	}
}        

exec function bt_reset()
{
	var master : Botanist;
	
	if (!Get_Botanist(master, 'BT_SetEntityLooted'))
	{
		return;
	}
	master.BT_PersistentStorage.BT_HerbStorage.reset_and_clerar();
}
//---------------------------------------------------
//-- Botanist Persistent Storage Class --------------
//---------------------------------------------------

class Botanist_Storage
{
	var BT_HerbStorage  : Botanist_KnownEntityStorage;
	var BT_EventHandler : Botanist_EventHandler;
}
	
//---------------------------------------------------
//-- Storage Functions ------------------------------
//---------------------------------------------------

function BT_LoadStorageCollection(master: Botanist)
{
	if (!master.BT_PersistentStorage)
	{
		master.BT_PersistentStorage = new Botanist_Storage in master;
		BT_Logger("New Master Storage Instance Created.");
	}
	else
	{
		BT_Logger("Existing Master Storage Instance Loaded.");
	}

//---------------------------------------------------

	if (!master.BT_PersistentStorage.BT_HerbStorage)
	{
		master.BT_PersistentStorage.BT_HerbStorage = new Botanist_KnownEntityStorage in master.BT_PersistentStorage;
		master.BT_PersistentStorage.BT_HerbStorage.inititalise(master);
		BT_Logger("New Herb Storage Instance Created.");
	}
	else
	{
		master.BT_PersistentStorage.BT_HerbStorage.inititalise(master);
		BT_Logger("Existing Herb Storage Instance Loaded With A Size Of: " + master.BT_PersistentStorage.BT_HerbStorage.get_known_herbs_count());
	}

//---------------------------------------------------

	if (!master.BT_PersistentStorage.BT_EventHandler)
	{
		master.BT_PersistentStorage.BT_EventHandler = new Botanist_EventHandler in master.BT_PersistentStorage;
		BT_Logger("New Event Handler Instance Created.");
	}
	else
	{
		BT_Logger("Existing Event Handler Instance Loaded With: " + master.BT_PersistentStorage.BT_EventHandler.get_registration_count() + " registrations");
	}
}

//---------------------------------------------------
//-- Entity Storage Class ---------------------------
//---------------------------------------------------

class Botanist_KnownEntityStorage
{
	var master: Botanist;
	var marker_manager : SUOL_Manager;
	var mappin_manager : SUMP_Manager;
		
	var botanist_master_herbs: array<BT_Herb>;
	var botanist_master_hashs: array<int>;
	var botanist_master_names: array<name>;
	var botanist_master_world: array<Vector>;
	
	var botanist_known_herbs : array<array<array<BT_Herb>>>;
	var botanist_known_herbs_guid_hashes : array<int>;
	var botanist_known_herbs_initialised : bool;
	
	var botanist_displayed_herbs : array<array<array<BT_Herb>>>;
	var botanist_displayed_herbs_guid_hashes : array<int>;
	
	var botanist_displayed_harvesting_grounds : array<array<array<BT_Harvesting_Ground>>>;
	var botanist_displayed_harvesting_grounds_guid_hashes : array<int>;
	var botanist_displayed_harvesting_grounds_initialised : bool;
	
	//---------------------------------------------------
	//-- Entity Storage Functions -----------------------
	//---------------------------------------------------

	function inititalise(master: Botanist) : void
	{	
		this.master = master;
		this.marker_manager = SUOL_getManager();
		this.mappin_manager = SUMP_getManager();
	
		this.attach_herb_pointers();
		this.attach_shared_util_pointers();
		
		this.initialise_storage_arrays();
		this.initialise_displayed_harvesting_grounds_arrays();
		
		this.initialise_temporary_displayed_arrays();
		this.initialise_saved_harvesting_grounds();
	}
	
	function reset_and_clerar() : void
	{
		botanist_master_herbs.Clear();
		botanist_master_hashs.Clear();
		botanist_master_names.Clear();
		botanist_master_world.Clear();
		
		botanist_known_herbs.Clear();
		botanist_known_herbs_guid_hashes.Clear();
		botanist_known_herbs_initialised = false;
		
		botanist_displayed_herbs.Clear();
		botanist_displayed_herbs_guid_hashes.Clear();
		
		botanist_displayed_harvesting_grounds.Clear();
		botanist_displayed_harvesting_grounds_guid_hashes.Clear();
		botanist_displayed_harvesting_grounds_initialised = false;
		
		this.initialise_storage_arrays();
		this.initialise_temporary_displayed_arrays();
	}
	
	//---------------------------------------------------
	//-- Array Initialisation Functions -----------------
	//---------------------------------------------------

	function initialise_saved_harvesting_grounds() : void
	{
		var Idx, Edx : int;
		var region   : BT_Herb_Region = botanist_get_herb_enum_region();
		var settings : Botanist_UserSettings = this.master.BT_ConfigSettings.get_user_settings();
		
		for (Idx = 0; Idx < this.botanist_displayed_harvesting_grounds[region].Size(); Idx += 1) 
		{
			for (Edx = 0; Edx < this.botanist_displayed_harvesting_grounds[region][Idx].Size(); Edx += 1) 
			{			
				this.botanist_displayed_harvesting_grounds[region][Idx][Edx].load(settings);
			}
		}
	}
	
	//---------------------------------------------------
	
	function initialise_storage_arrays() : void
	{
		var Idx : int;

		if ( this.botanist_known_herbs_initialised )
		{
			return;
		}
		
		this.botanist_known_herbs.Clear();
		this.botanist_known_herbs_guid_hashes.Clear();

		for (Idx = 0; Idx < EnumGetMax('BT_Herb_Region')+1; Idx += 1) 
		{
			this.botanist_known_herbs.PushBack( this.get_blank_region_array() );
		}
		
		this.botanist_known_herbs_initialised = true;
	}

	//---------------------------------------------------
	
	function initialise_displayed_harvesting_grounds_arrays() : void
	{
		var Idx : int;
		
		if ( this.botanist_displayed_harvesting_grounds_initialised )
		{
			return;
		}
		
		this.botanist_displayed_harvesting_grounds.Clear();
		this.botanist_displayed_harvesting_grounds_guid_hashes.Clear();
		
		for (Idx = 0; Idx < EnumGetMax('BT_Herb_Region')+1; Idx += 1) 
		{
			this.botanist_displayed_harvesting_grounds.PushBack( this.get_blank_farming_region_array() );
		}
		
		this.botanist_displayed_harvesting_grounds_initialised = true;
	}
	
	//---------------------------------------------------
	
	function initialise_temporary_displayed_arrays() : void
	{
		var Idx : int;
		
		this.botanist_displayed_herbs.Clear();
		this.botanist_displayed_herbs_guid_hashes.Clear();
		
		for (Idx = 0; Idx < EnumGetMax('BT_Herb_Region')+1; Idx += 1) 
		{
			this.botanist_displayed_herbs.PushBack( this.get_blank_region_array() );
		}
	}

	//---------------------------------------------------
	
	function get_blank_region_array() : array<array<BT_Herb>>
	{
		var output : array<array<BT_Herb>>;
		var Idx : int;

		for (Idx = 0; Idx < EnumGetMax('BT_Herb_Enum')+1; Idx += 1)
		{
		  output.PushBack( this.get_blank_herb_array() );
		}

		return output;	
	}

	//---------------------------------------------------
	
	function get_blank_farming_region_array() : array<array<BT_Harvesting_Ground>>
	{
		var output : array<array<BT_Harvesting_Ground>>;
		var Idx : int;

		for (Idx = 0; Idx < EnumGetMax('BT_Herb_Enum')+1; Idx += 1)
		{
		  output.PushBack( this.get_blank_farming_herb_array() );
		}

		return output;	
	}
	
	//---------------------------------------------------
	
	function get_blank_herb_array() : array<BT_Herb>
	{
		var output : array<BT_Herb>;
		return output;
	}	

	//---------------------------------------------------
	
	function get_blank_farming_herb_array() : array<BT_Harvesting_Ground>
	{
		var output : array<BT_Harvesting_Ground>;
		return output;
	}
	
	//---------------------------------------------------
	//-- Botanist Array Functions -----------------------
	//---------------------------------------------------
	
	function get_known_herbs_count() : int
	{
		return botanist_master_herbs.Size();
	}
	
	//---------------------------------------------------
	
	function has_discovered_plants_in_region(val : name) : bool
	{
		return this.botanist_known_herbs[botanist_get_herb_enum_region()][botanist_get_herb_enum_from_name(val)].Size() > 0;
	}

	//---------------------------------------------------
	
	function get_currently_displayed_count(region : BT_Herb_Region, type : BT_Herb_Enum) : int
	{
		var Idx, harvesting_grounds_count : int;

		for( Idx = 0; Idx < this.botanist_displayed_harvesting_grounds[region][type].Size(); Idx += 1 )
		{
			harvesting_grounds_count += this.botanist_displayed_harvesting_grounds[region][type][Idx].spot_herbs.Size();
		}
		
		return harvesting_grounds_count + this.botanist_displayed_herbs[region][type].Size();
	}
	
	//---------------------------------------------------
	
	function has_harvestable_plants_in_region(herb_name : name) : bool
	{
		var region : BT_Herb_Region = botanist_get_herb_enum_region();
		var type   : BT_Herb_Enum = botanist_get_herb_enum_from_name(herb_name);
		var Idx    : int;
		
		for( Idx = 0; Idx < this.botanist_known_herbs[region][type].Size(); Idx += 1 )
		{
			if ( this.botanist_known_herbs[region][type][Idx].is_eligible_for_normal_display() )
			{
				return true;
			}
		}
		
		return false;
	}	
	
	//---------------------------------------------------
	
	function generate_herb_node_pairing_for_harvesting_grounds(region :  BT_Herb_Region, type : BT_Herb_Enum) : array<Botanist_NodePairing>
	{
		var pairings : array<Botanist_NodePairing>;		
		var Idx      : int;

		for( Idx = 0; Idx < this.botanist_known_herbs[region][type].Size(); Idx += 1 )
		{
			if ( this.botanist_known_herbs[region][type][Idx].is_eligible_for_harvesting_grounds() )
			{
				pairings.PushBack( Botanist_NodePairing( (CNode)this.botanist_known_herbs[region][type][Idx].herb_entity, this.botanist_known_herbs[region][type][Idx] ) );
			}
		}

		return pairings;
	}
	
	//---------------------------------------------------
	//-- Utility Re-Point Function ----------------------
	//---------------------------------------------------
	
	function attach_herb_pointers() : void
	{
		var vspawned_herbs  : array<W3Herb> = theGame.BT_GetArray();
		var Idx, Edx, Rdx, Pdx   : int;
		
		BT_Logger("Running Pointer Attachment On " + vspawned_herbs.Size() + " Herbs...");
		for( Idx = 0; Idx < vspawned_herbs.Size(); Idx += 1 )
		{
			Edx = botanist_master_hashs.FindFirst(vspawned_herbs[Idx].GetGuidHash());
			if (Edx != -1)
			{
				if (  botanist_master_herbs[Edx].reset_entity( vspawned_herbs[Idx] ) )
				{
					Rdx += 1;
					continue;
				}
				
				Pdx += 1;
			}
		}
		
		BT_Logger("Re-attached Entity Pointers On [" + Rdx + " / " + get_known_herbs_count() + "] Known Herbs With [" + Pdx + "] Failures.");
		theGame.BT_ClearArray();		
	}

	//---------------------------------------------------
	//-- Shared Utils Re-Point Function -----------------
	//---------------------------------------------------
	
	function attach_shared_util_pointers() : void
	{
		var Idx, Edx, Pdx, Rdx : int;
		var region   : BT_Herb_Region = botanist_get_herb_enum_region();
		var settings : Botanist_UserSettings = this.master.BT_ConfigSettings.get_user_settings();
		
		for (Idx = 0; Idx < this.botanist_known_herbs[region].Size(); Idx += 1) 
		{
			for (Edx = 0; Edx < this.botanist_known_herbs[region][Idx].Size(); Edx += 1) 
			{			
				if ( this.botanist_known_herbs[region][Idx][Edx].attach_shared_util_pointers(this.mappin_manager, this.marker_manager) )
				{
					Rdx += 1;
					continue;
				}

				Pdx += 1;
			}
		}
		
		BT_Logger("Re-attached Shared Util Pointers On [" + Rdx + " / " + get_known_herbs_count() + "] Known Herbs With [" + Pdx + "] Failures.");		
	}
}

//---------------------------------------------------
//-- Class ------------------------------------------
//---------------------------------------------------		

statemachine class Botanist_UIDisplayCreator
{	
	public var region         : BT_Herb_Region;
	public var type           : BT_Herb_Enum;
	public var quantity       : int;
	public var user_settings  : Botanist_UserSettings;
	public var recipes        : array<name>;
	public var storage        : Botanist_KnownEntityStorage;
	
	public function create_and_set_variables(data : Botanist_DataTransferStruct) : Botanist_UIDisplayCreator
	{
		this.region        = data.region;
		this.type          = data.type;
		this.quantity      = data.quantity;
		this.user_settings = data.user_settings;
		this.recipes       = data.recipes;
		this.storage       = data.storage;

		this.GotoState('Processing');
		return this;
	}
}

//---------------------------------------------------
//-- Botanist Display Class - (idle State) ----------
//---------------------------------------------------

state idle in Botanist_UIDisplayCreator 
{
	event OnEnterState(previous_state_name: name) 
	{
		super.OnEnterState(previous_state_name);
		BT_Logger("Botanist_UIDisplayCreator Entered state [idle]");
	}
}

//---------------------------------------------------
//-- Botanist Display Class - (Processing State) ----
//---------------------------------------------------

state Processing in Botanist_UIDisplayCreator 
{	
	event OnEnterState(previous_state_name: name) 
	{
		super.OnEnterState(previous_state_name);
		BT_Logger("Botanist_UIDisplayCreator Entered state [Processing]");
		
		this.Processing();
	}

	//---------------------------------------------------

	entry function Processing()
	{
		var herb_nodes   : array<CNode>;
		var current_herb : BT_Herb;
		var node 		 : CNode;
		
		var Pos  		 : Vector = thePlayer.GetWorldPosition();
		var Idx, Edx	 : int;

		if ( parent.storage.get_currently_displayed_count(parent.region, parent.type) >= parent.quantity )
		{
			return;
		}

		for( Idx = 0; Idx < parent.storage.botanist_known_herbs[parent.region][parent.type].Size(); Idx += 1 )
		{
			if ( parent.storage.botanist_known_herbs[parent.region][parent.type][Idx].is_eligible_for_normal_display() )
			{
				herb_nodes.PushBack( (CNode)parent.storage.botanist_known_herbs[parent.region][parent.type][Idx].herb_entity );
			}
		}
		
		Edx = Min(herb_nodes.Size(), parent.quantity);

		//Traverse and find the closest herb to the players position
		for( Idx = 0; Idx < Edx; Idx += 1 )
		{
			node = FindClosestNode(Pos, herb_nodes);
			
			if ( this.get_closest_herb(node, current_herb) != -1 && !current_herb.is_displayed() )
			{
				current_herb.set_displayed(parent.user_settings, parent.recipes[RandRange(parent.recipes.Size(), 0)]);
			}
			herb_nodes.Remove(node);
		}
		
		if ( parent.user_settings.bools[BT_Config_Hgr_Enabled] )
		{
			this.check_for_eligible_grounds(parent.region, parent.type, parent.user_settings);
		}
		
		parent.GotoState('idle');
	}

	//---------------------------------------------------
	
	private function get_closest_herb(node: CNode, out current_herb : BT_Herb) : int
	{		
		var Idx : int = parent.storage.botanist_master_world.FindFirst(node.GetWorldPosition());

		if (Idx != -1)
		{
			current_herb = parent.storage.botanist_master_herbs[Idx];
		}
		
		return Idx;
	}

	//---------------------------------------------------
	//-- Harvesting Grounds -----------------------------
	//---------------------------------------------------
	
	private function check_for_eligible_grounds(region : BT_Herb_Region, type : BT_Herb_Enum, user_settings : Botanist_UserSettings) : void
	{		
		var hg_all_nodes        : array<Botanist_NodePairing>;
		
		var hg_result_01        : Botanist_HarvestGroundResults;
		var hg_result_02        : Botanist_HarvestGroundResults;
		var hg_result_03        : Botanist_HarvestGroundResults;
		
		var hg_maxground		: int = user_settings.ints[BT_Config_Hgr_MaxGrd];
		var hg_displayed		: int = parent.storage.botanist_displayed_harvesting_grounds[region][type].Size();
		
		//Generate an array of nodes and their matching botanist herb classes.		
		hg_all_nodes = parent.storage.generate_herb_node_pairing_for_harvesting_grounds(region, type);
		
		if ( hg_displayed < hg_maxground && hg_all_nodes.Size() > 0 )
		{
			hg_result_01 = this.findHarvestingGround("1", user_settings, hg_all_nodes);
			this.create_harvesting_grounds(region, type, user_settings, hg_result_01);
			
			if ( hg_displayed < hg_maxground && hg_maxground > 1 )
			{
				hg_result_02 = this.findHarvestingGround("3", user_settings, hg_result_01.filtered_nodes);
				this.create_harvesting_grounds(region, type, user_settings, hg_result_02);			
			}
			
			if ( hg_displayed < hg_maxground && hg_maxground > 2 )
			{
				hg_result_03 = this.findHarvestingGround("3", user_settings, hg_result_02.filtered_nodes);
				this.create_harvesting_grounds(region, type, user_settings, hg_result_03);			
			}
		}
	}
	
	//---------------------------------------------------
	
	private function findHarvestingGround(id : string, user_settings : Botanist_UserSettings, node_pairings: array<Botanist_NodePairing>) : Botanist_HarvestGroundResults
	{	
		var output : Botanist_HarvestGroundResults;
		var Edx    : int = RandRange(node_pairings.Size(), 0);
		var Rdx    : int = user_settings.ints[BT_Config_Hgr_Radius];
		var Pdx    : int = user_settings.ints[BT_Config_Hgr_MaxAll];
		var Idx    : int;

		for (Idx = 0; Idx < node_pairings.Size(); Idx += 1) 
		{				
			if ( output.harvesting_nodes.Size() < Pdx && VecDistanceSquared2D(node_pairings[Edx].node.GetWorldPosition(), node_pairings[Idx].node.GetWorldPosition()) <= (Rdx * Rdx) )
			{
				//BT_Logger("Added Herb [" + node_pairings[Idx].herb.herb_guidhash + "] To Harvesting Grounds [" + id + "]");
				output.harvesting_nodes.PushBack( Botanist_NodePairing(node_pairings[Idx].node, node_pairings[Idx].herb) );
			}
			else
			{
				//BT_Logger("Filtered Herb [" + node_pairings[Idx].herb.herb_guidhash + "] From Harvesting Grounds [" + id + "]");
				output.filtered_nodes.PushBack( Botanist_NodePairing(node_pairings[Idx].node, node_pairings[Idx].herb) );
			}
		}
		return output;
	}

	//---------------------------------------------------
	
	private function generate_map_pin_position_from_results(hg_result: Botanist_HarvestGroundResults) : Vector
	{
		var current_distance, new_distance: float;
		var first, last : Vector;
		var Idx, Edx, Rdx : int;
	  
		Rdx = hg_result.harvesting_nodes.Size();
		
		first = hg_result.harvesting_nodes[0].node.GetWorldPosition();
		last  = hg_result.harvesting_nodes[0].node.GetWorldPosition();
		current_distance = 0;

		for (Idx = 0; Idx < Rdx; Idx += 1)
		{
			for (Edx = 0; Edx < Rdx; Edx += 1) 
			{
				new_distance = VecDistanceSquared2D(hg_result.harvesting_nodes[Idx].node.GetWorldPosition(), hg_result.harvesting_nodes[Edx].node.GetWorldPosition());

				if (new_distance > current_distance) 
				{
					first = hg_result.harvesting_nodes[Idx].node.GetWorldPosition();
					last  = hg_result.harvesting_nodes[Edx].node.GetWorldPosition();
					current_distance = new_distance;
				}
			}
		}
		
		//BT_Logger("Furthermost Herb Distances Finished with [Closest] = " + BT_VectorToString(first) + "[Furthest] = " +  BT_VectorToString(last));
		return (first + last) / 2;
	}
	
	//---------------------------------------------------
	
	private function get_furthermost_point_from_centre(mappin_position : Vector, hg_result: Botanist_HarvestGroundResults) : float
	{
		var current_distance, new_distance: float;
		var Idx : int;

		current_distance = 0;

		for (Idx = 0; Idx < hg_result.harvesting_nodes.Size(); Idx += 1)
		{
			new_distance = VecDistanceSquared2D(hg_result.harvesting_nodes[Idx].node.GetWorldPosition(), mappin_position);

			if (new_distance > current_distance) 
			{
				current_distance = new_distance;
			}
		}
		
		//BT_Logger("Herb Furthest From Map Pin Centre = " +  hg_result.harvesting_nodes[Idx].herb.herb_guidhash);
		
		return SqrtF(current_distance) + 10;
	}

	//---------------------------------------------------
	
	private function create_harvesting_grounds(region : BT_Herb_Region, type : BT_Herb_Enum, user_settings : Botanist_UserSettings, hg_result: Botanist_HarvestGroundResults)
	{
		var position : Vector;
		var radius	 : float;		
		
		if ( hg_result.harvesting_nodes.Size() >= user_settings.ints[BT_Config_Hgr_MinReq] )
		{
			//Calculate the centre position and radius of the map pin for the harvesting grounds.
			position = this.generate_map_pin_position_from_results(hg_result);
			
			//Obtain the furthest herb from the centre point on the map pin within range.
			radius = this.get_furthermost_point_from_centre(position, hg_result);
			
			//Create the farming spot and display it on the map.
			( (new BT_Harvesting_Ground in this).create(hg_result, region, type, radius, position, parent.storage.master, user_settings) );
		}
	}
}

//---------------------------------------------------
//-- Class ------------------------------------------
//---------------------------------------------------		

statemachine class Botanist_UIRenderLoop
{	
	public var master  : Botanist;
	public var config  : Botanist_Config;
	public var storage : Botanist_KnownEntityStorage;
	public var alchemy : Botanist_AlchemyManager;
	
	//---------------------------------------------------

	public function initialise(master: Botanist)
	{
		this.master  = master;
		this.config  = master.BT_ConfigSettings;
		this.alchemy = master.BT_AlchemyManager;
		this.storage = master.BT_PersistentStorage.BT_HerbStorage;

		this.GotoState('on_tick');
	}
}

//---------------------------------------------------
//-- States -----------------------------------------
//---------------------------------------------------

state on_tick in Botanist_UIRenderLoop 
{	
	event OnEnterState(previous_state_name: name) 
	{
		super.OnEnterState(previous_state_name);		
		this.on_tick();
	}

	//---------------------------------------------------

	entry function on_tick()
	{	
		var m_alchemyManager : W3AlchemyManager;
		var current_region 	 : BT_Herb_Region;
		
		var old_requirements : Botanist_RequiredHerbs;
		var new_requirements : Botanist_RequiredHerbs;
		
		var new_usersettings : Botanist_UserSettings;
		var old_usersettings : Botanist_UserSettings;
		
		var Idx              : int;
		var stt              : float;
		var target_herb		 : name;
		
		var changed_req, changed_set : bool;
		
		while(true)
		{
			stt = theGame.GetLocalTimeAsMilliseconds();
			current_region = botanist_get_herb_enum_region();
			
			//Initialise the alchemy manager to build a list of all player recipes.
			m_alchemyManager = new W3AlchemyManager in this;
			m_alchemyManager.Init();

			//Generate a list of all current herb requirements and user settings.
			new_requirements = parent.alchemy.get_alchemy_data(m_alchemyManager);
			new_usersettings = parent.config.get_user_settings();
			
			//Obtain the base item name of the targetted herb if selected in the mod menu.
			target_herb = BT_GetOverrideItemName( new_usersettings.ints[BT_Config_Mod_Targets] );
			
			changed_req = requirements_have_changed(old_requirements, new_requirements);
			changed_set = settings_have_changed(old_usersettings, new_usersettings);
			
			//If the user has changed any mod settings then update the existing harvesting grounds as the 3D markers are no longer held in temp display storage.
			if ( changed_set )
			{
				this.update_harvesting_grounds_with_new_settings(new_usersettings, current_region);
			}
			
			//If any changes are detected in the required ingredients or if the user has changed any mod settings then update the UI.
			if ( changed_req || changed_set )
			{
				//Clear all existing UI data such as map pins and 3D Markers for the current region.
				this.clear_existing_ui_data(current_region);

				//If the player is only wanting to display a specific herb and that herb is requird for a recipe then only process that one list.
				if ( target_herb != '' )
				{
					if ( new_requirements.names.Contains( target_herb ) )
					{
						Idx = new_requirements.names.FindFirst( target_herb );
						(new Botanist_UIDisplayCreator in this).create_and_set_variables( Botanist_DataTransferStruct(current_region, BT_GetOverrideEnumValue( target_herb ), new_requirements.quantities[Idx], new_usersettings, new_requirements.cookeditems[Idx], parent.storage) );
					}
				}
				else 
				{	//If the user is searching for all required herbs not just a specific one then process all lists of known herbs in that region.
					for( Idx = 0; Idx < new_requirements.names.Size(); Idx += 1 )
					{
						(new Botanist_UIDisplayCreator in this).create_and_set_variables( Botanist_DataTransferStruct(current_region, botanist_get_herb_enum_from_name(new_requirements.names[Idx]), new_requirements.quantities[Idx], new_usersettings, new_requirements.cookeditems[Idx], parent.storage) );
					}
				}
			}

			//The UI is now updated, store the requirements and user settings in a seperate variable so we can compare them on the next iteration.
			old_requirements = new_requirements;
			old_usersettings = new_usersettings;

			BT_Logger("UI Update Loop took: " + (theGame.GetLocalTimeAsMilliseconds() - stt) + " milliseconds to run");
			Sleep(2);
		}
	}

	//---------------------------------------------------
	
	private function update_harvesting_grounds_with_new_settings(new_usersettings: Botanist_UserSettings, current_region : BT_Herb_Region) : void
	{
		var Idx, Edx: int;

		for( Idx = 0; Idx < parent.storage.botanist_displayed_harvesting_grounds[current_region].Size(); Idx += 1 )
		{
			for( Edx = 0; Edx < parent.storage.botanist_displayed_harvesting_grounds[current_region][Idx].Size(); Edx += 1 )
			{
				parent.storage.botanist_displayed_harvesting_grounds[current_region][Idx][Edx].update( new_usersettings );
			}
		}
		
	}
	
	//---------------------------------------------------
	
	private function clear_existing_ui_data(current_region : BT_Herb_Region) : void
	{
		var Idx, Edx: int;
		
		//Traverse the list of all displayed herbs and reset them to clear their map pins and 3D markers.
		for( Idx = 0; Idx < parent.storage.botanist_displayed_herbs[current_region].Size(); Idx += 1 )
		{
			for( Edx = 0; Edx < parent.storage.botanist_displayed_herbs[current_region][Idx].Size(); Edx += 1 )
			{
				parent.storage.botanist_displayed_herbs[current_region][Idx][Edx].reset( false );
			}
		}
		
		//This setup uses nested arrays so we need to re-initialise them for the next iteration of the monitoring loop.
		parent.storage.initialise_temporary_displayed_arrays();	
	}
	
	//---------------------------------------------------

	private function requirements_have_changed(old_data, new_data : Botanist_RequiredHerbs) : bool
	{
		var Idx, Edx : int;

		if ( new_data.names.Size() != old_data.names.Size() )
		{
			return true;
		}
		
		for( Idx = 0; Idx < new_data.names.Size(); Idx += 1 )
		{
			Edx = parent.storage.get_currently_displayed_count(botanist_get_herb_enum_region(), botanist_get_herb_enum_from_name(new_data.names[Idx]));
			
			if ( (new_data.quantities[Idx] - Edx) > 0 && parent.storage.has_harvestable_plants_in_region(new_data.names[Idx]) )
			{
				return true;
			}	
		
			if ( new_data.names[Idx] != old_data.names[Idx] )
			{
				return true;
			}

			if ( new_data.quantities[Idx] != old_data.quantities[Idx] )
			{
				return true;
			}
		}
		
		return false;
	}

	//---------------------------------------------------

	private function settings_have_changed(old_data, new_data : Botanist_UserSettings) : bool
	{
		var Idx, Edx : int;
		
		for( Idx = 0; Idx < new_data.bools.Size(); Idx += 1 )
		{
			if ( new_data.bools[Idx] != old_data.bools[Idx] )
			{
				return true;
			}
		}

		for( Idx = 0; Idx < new_data.ints.Size(); Idx += 1 )
		{
			if ( new_data.ints[Idx] != old_data.ints[Idx] )
			{
				return true;
			}
		}

		return false;
	}
}
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
}
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

struct Botanist_RequiredHerbs
{
	var names		: array<name>;
	var quantities	: array<int>;
	var cookeditems	: array<array<name>>;
}