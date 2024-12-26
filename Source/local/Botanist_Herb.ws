
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

class BT_MapPin extends SU_MapPin
{
	var l_data : Botanist_MapPinLookupData;
	
	function onPinUsed()
	{
		BT_Logger("DATA = " + l_data.hash + " || " + l_data.type + " || " + l_data.region + " || " + l_data.grounds);
	}
}

//---------------------------------------------------
//-- Botanist Main Herb Class -----------------------
//---------------------------------------------------

class BT_Herb extends W3Herb
{
	var master: Botanist;

	var event_manager   : Botanist_EventHandler; 
	
	// Creation Data
	var herb_entity		: W3Herb;
	var herb_areaname	: BT_Herb_Region;
	var entity_storage  : Botanist_KnownEntityStorage;
	var world_position 	: Vector;
	var herb_tag		: name;
	var herb_guidhash	: int;
	
	// Dynamic Boon Data
	var herb_has_boon	: bool;
	var boon_total      : int;
	
	// 3D Marker Data
	var marker_status	: BT_Herb_Display_Status;
	
	var herb_enum_type	: BT_Herb_Enum;
	var herb_marker		: BT_OneLiner;
	var icon_path		: string;
	var localised_name	: string;
	
	// Map Pin Data
	var herb_mappin		: BT_MapPin;
	
	default marker_status = BT_Herb_Hidden;

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
		BT_Logger("Herb Details: [TYPE: " + this.herb_enum_type + "] [AREA: " + this.herb_areaname + "] [NAME: " + this.herb_tag + "] [ATTACHED: " + (bool) this.herb_entity + "] [HASH: " + this.herb_guidhash + "] [CAN HARVEST: " + !this.is_looted() + "] [POSITION: " + this.world_position.X + ", " + this.world_position.Y + ", " + this.world_position.Z + ", " + this.world_position.W + "] [DISTANCE TO PLAYER: " + FloatToStringPrec( FloorF( SqrtF( VecDistanceSquared(thePlayer.GetWorldPosition(), world_position))), 0) + "]");
	}
	
	//---------------------------------------------------
	//-- Creation Functions -----------------------------
	//---------------------------------------------------
	
	function create_new_herb(herb_entity: W3Herb, world_position: Vector, herb_tag: name, herb_guidhash: int, herb_areaname: EAreaName, master : Botanist) : bool
	{
		this.herb_areaname = set_herb_region(herb_areaname);
		if (this.herb_areaname == BT_Invalid_Location)
		{
			return false;
		}
		
		this.master = master;
		
		this.event_manager  = master.BT_PersistentStorage.BT_EventHandler;
		this.entity_storage = master.BT_PersistentStorage.BT_HerbStorage;
		
		this.herb_entity 	= herb_entity;

		this.world_position = world_position;
		this.herb_tag 		= herb_tag;
		this.herb_guidhash 	= herb_guidhash;
		this.herb_enum_type = botanist_get_herb_enum_from_name( this.herb_tag );
		this.marker_status  = BT_Herb_Ready;
		
		this.icon_path		= thePlayer.GetInventory().GetItemIconPathByName(herb_tag);
		this.localised_name = GetLocStringByKeyExt(theGame.GetDefinitionsManager().GetItemLocalisationKeyName(herb_tag));
	
		this.add_herb_to_storage();
		
		this.event_manager.register_for_event( botanist_event_data(BT_Herb_Looted, , , this) );
		this.event_manager.register_for_event( botanist_event_data(BT_Herb_Reset, , , this) );
		
		return true;
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
	//-- Reset Functions --------------------------------
	//---------------------------------------------------
	
	function reset() : void
	{
		this.remove_markers();
		this.remove_boon();
		
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
	
	function reset_entity( herb_entity : W3Herb, master: Botanist ) : bool
	{
		this.master = master;
		
		this.event_manager.register_for_event( botanist_event_data(BT_Herb_Looted, , , this) );
		this.event_manager.register_for_event( botanist_event_data(BT_Herb_Reset, , , this) );
		this.herb_entity = herb_entity;
		
		if ( this.herb_entity && this.master )
			return true;
		
		return false;
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
		this.reset();
		this.marker_status = BT_Herb_In_Grounds;
		this.display_markers();
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
			this.GotoState('on_looted');
		}
	}

	//---------------------------------------------------
	
	event On_herb_reset() : void
	{
		if ( !this.is_in_harvesting_grounds() )
		{
			this.GotoState('on_reset');
		}
	}

	//---------------------------------------------------
	
	function is_looted() : bool
	{
		return this.herb_entity.is_empty();
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
	
	function set_displayed(optional in_grounds : bool) : void
	{
		if ( in_grounds )
		{
			this.set_in_harvesting_grounds();
			return;
		}

		this.marker_status 	= BT_Herb_HarvestReady;
		this.display_markers();
	}

	//---------------------------------------------------
	
	function is_displayed() : bool
	{
		return this.entity_storage.botanist_displayed_herbs_guid_hashes.Contains(this.herb_guidhash);
	}
	
	//---------------------------------------------------

	function update_markers() : void
	{
		var config: Botanist_UserSettings = BT_GetUserSettings(BT_Config_User);
		
		//oneliner
		if ( !herb_marker )
		{
			herb_marker					= new BT_OneLiner in this;
		}
		
		herb_marker.tag					= "Botanist_" + this.herb_guidhash;
		herb_marker.active_status		= config.ints[BT_Config_Ols_Active];
		herb_marker.text 				= this.get_marker_label();
		herb_marker.position 			= this.world_position;
		herb_marker.render_distance 	= this.get_marker_visibility_range();
		
		//mappin
		if ( !herb_mappin )
		{
			herb_mappin					= new BT_MapPin in this;
		}
		
		herb_mappin.tag 				= "Botanist_" + this.herb_guidhash;
		herb_mappin.label 				= get_mappin_label();
		herb_mappin.description 		= get_mappin_description();
		herb_mappin.radius				= get_mappin_radius();
		herb_mappin.type 				= get_mappin_type();
		herb_mappin.filtered_type   	= get_mappin_type();
		herb_mappin.position 			= Vector(world_position.X, world_position.Y);
		herb_mappin.region 				= get_herb_region_string();
		herb_mappin.is_quest 			= false;
		herb_mappin.appears_on_minimap 	= false;
		herb_mappin.pointed_by_arrow 	= false;
		herb_mappin.highlighted 		= false;
		herb_mappin.is_fast_travel		= false;
	}
	
	//---------------------------------------------------

	function display_markers() : void
	{
		var Idx : int;
		var marker_manager: SUOL_Manager  = thePlayer.GetBotanistConfig().marker_manager;
		var mappin_manager: SUMP_Manager  = thePlayer.GetBotanistConfig().mappin_manager;
		var config: Botanist_UserSettings = BT_GetUserSettings(BT_Config_User);

		this.update_markers();
		
		if ( config.bools[BT_Config_Ols_Enabled] ) {
			marker_manager.createOneliner( this.herb_marker ); 
		}

		if ( !this.is_in_harvesting_grounds() )
		{
			this.entity_storage.botanist_displayed_herbs[herb_areaname][herb_enum_type].PushBack( this );
			this.entity_storage.botanist_displayed_herbs_guid_hashes.PushBack( this.herb_guidhash );
		}

		if ( config.bools[BT_Config_Pin_Enabled] )
		{
			Idx = mappin_manager.mappins.FindFirst( this.herb_mappin );
			
			if ( Idx != -1 )
			{
				mappin_manager.mappins[Idx] = this.herb_mappin;
			}
			else
			{
				mappin_manager.mappins.PushBack( this.herb_mappin );
			}
		}
	}
	
	//---------------------------------------------------

	function remove_markers() : void
	{
		var marker_manager: SUOL_Manager = thePlayer.GetBotanistConfig().marker_manager;
		var mappin_manager: SUMP_Manager = thePlayer.GetBotanistConfig().mappin_manager;
		
		this.entity_storage.botanist_displayed_herbs[herb_areaname][herb_enum_type].Remove( this );
		this.entity_storage.botanist_displayed_herbs_guid_hashes.Remove( this.herb_guidhash );
		
		marker_manager.deleteOneliner( (SU_Oneliner)this.herb_marker );
		mappin_manager.mappins.Remove( this.herb_mappin );
	}
	
	//---------------------------------------------------
	
	function get_marker_visibility_range() : int
	{
		var config: Botanist_UserSettings = BT_GetUserSettings(BT_Config_User);
		
		switch( config.ints[BT_Config_Ols_Visible] )
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
		var config	 : Botanist_UserSettings = BT_GetUserSettings(BT_Config_User);
		var fontSize : int = config.ints[BT_Config_Ols_Fontsize];
		var iconPath : string = "<img src='img://" + this.icon_path + "' height='" + (fontSize) + "' width='" + (fontSize) + "' />";
		
		if ( this.is_in_harvesting_grounds() )
			return iconPath + "<font color='#9baadd' size='" + fontSize + "'> " + "  " + this.localised_name + "</font>";

		return iconPath + "<font color='#ffcc00' size='" + fontSize + "'> " + "  " + this.localised_name + "</font>";
	}

	//---------------------------------------------------

	function get_marker_iconpath() : string
	{
		var config	 : Botanist_UserSettings = BT_GetUserSettings(BT_Config_User);
		var fontSize : int = config.ints[BT_Config_Ols_Fontsize];
		return "<img src='img://" + icon_path + "' height='" + (fontSize + 10) + "' width='" + (fontSize + 10) + "' vspace='" + (fontSize + 10) + "' />&nbsp;";
	}
	
	//---------------------------------------------------

	function get_mappin_label() : string
	{
		if ( this.is_in_harvesting_grounds() )
			return GetLocStringByKeyExt("BT_HerbLootableHG");
		
		return GetLocStringByKeyExt("BT_HerbLootable");
	}

	//---------------------------------------------------

	function get_mappin_type() : string
	{
		if ( this.is_in_harvesting_grounds() )
			return "BotanistHGHerb";
		
		return "Botanist";
	}

	//---------------------------------------------------
	
	function get_mappin_description() : string
	{
		if ( this.is_in_harvesting_grounds() )
			return StrReplace(GetLocStringByKeyExt("BT_HerbMapPinInfo_HG"), "[NAME]", this.localised_name);
		
		return StrReplace(GetLocStringByKeyExt("BT_HerbMapPinInfo"), "[NAME]", this.localised_name);
	}

	//---------------------------------------------------
	
	function get_mappin_radius() : int
	{
		var config: Botanist_UserSettings = BT_GetUserSettings(BT_Config_User);
		return config.ints[BT_Config_Pin_Radius];
	}
}

//---------------------------------------------------
//-- Botanist Main Herb States ----------------------
//---------------------------------------------------

state waiting in BT_Herb 
{
	event OnEnterState(previous_state_name: name) 
	{
		super.OnEnterState(previous_state_name);
	}
}

//---------------------------------------------------
//-- Botanist Main Herb States ----------------------
//---------------------------------------------------

state on_looted in BT_Herb 
{
	event OnEnterState(previous_state_name: name) 
	{			
		this.loot();
		super.OnEnterState(previous_state_name);
	}

	entry function loot()
	{
		if ( parent.herb_has_boon && parent.is_in_harvesting_grounds() )
		{
			GetWitcherPlayer().DisplayHudMessage( StrReplace(GetLocStringByKeyExt("BT_HerbYieldInfo_HG"), "[REPLACE]", parent.boon_total) );
			thePlayer.inv.AddAnItem(parent.herb_tag, parent.boon_total, false, false, true);
		}
		
		parent.reset();
		parent.GotoState('waiting');
	}
}

//---------------------------------------------------
//-- Botanist Main Herb States ----------------------
//---------------------------------------------------

state on_reset in BT_Herb 
{
	event OnEnterState(previous_state_name: name) 
	{			
		this.run_reset();
		super.OnEnterState(previous_state_name);
	}

	entry function run_reset()
	{
		parent.reset();
		parent.GotoState('waiting');
	}
}