
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
