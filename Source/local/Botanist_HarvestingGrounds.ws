
//---------------------------------------------------
//-- Botanist Main Harvesting Grounds Class ---------
//---------------------------------------------------

statemachine class BT_Harvesting_Ground
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
		
		this.mappin_manager  = SUMP_getManager();
		this.mappin_pos      = mappin_pos;
		this.mappin_rad      = mappin_rad;
		this.mappin_name     = GetLocStringByKeyExt(theGame.GetDefinitionsManager().GetItemLocalisationKeyName( botanist_get_herb_name_from_enum( this.spot_type ) ));
		this.apply_random_boon();
		
		this.display_farming_spot();
		this.print_info();
		
		this.event_manager.register_for_event( botanist_event_data(BT_Herb_Looted, , , , this) );
		this.event_manager.register_for_event( botanist_event_data(BT_Herb_Clear_Except, , , , this) );
		
		master.BT_TutorialsSystem.show_tutorial( Botanist_Tutorial_HarvestingGrounds );
		
		this.GotoState('update');
		return this;
	}

	//---------------------------------------------------
	
	function load(user_settings : Botanist_UserSettings)
	{
		var Idx : int;
		
		this.user_settings = user_settings;
		
		if ( !user_settings.bools[BT_Config_Hgr_Enabled] || this.spot_herbs.Size() < 1 )
		{
			this.remove_farming_spot();
			return;			
		}
		
		for( Idx = this.spot_herbs.Size()-1; Idx >= 0 ; Idx -= 1 )
		{
			if ( !this.spot_herbs[Idx].herb.is_looted() && !this.entity_storage.is_herb_excluded( this.spot_herbs[Idx].herb.herb_guidhash ) )
			{
				this.spot_herbs[Idx].herb.set_displayed(this.user_settings, true);
				continue;
			}

			this.spot_herbs[Idx].herb.reset();
			this.spot_herbs.EraseFast(Idx);
		}
		
		this.event_manager.register_for_event( botanist_event_data(BT_Herb_Looted, , , , this) );
		this.event_manager.register_for_event( botanist_event_data(BT_Herb_Clear_Except, , , , this) );
		
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
		var Idx : int = this.mappin_manager.mappins.FindFirst( this.mappin );

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
	
	event On_clear_except( _name : name )
	{
	 if ( _name != botanist_get_herb_name_from_enum( this.spot_type ) )
		this.remove_farming_spot();
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
		var Idx : int;
		
		if ( !this.mappin )
		{
			this.mappin = new BT_MapPin in this;
		}	
		
		mappin.tag 				    = "Botanist_Harvesting_Ground_" + this.spot_hash;
		mappin.label 			    = this.get_mappin_label();
		mappin.radius				= this.mappin_rad;
		mappin.position 			= this.mappin_pos;
		mappin.description 		    = this.get_mappin_description();
		mappin.region 				= this.get_herb_region_string();
		mappin.type 				= "BotanistHG";
		mappin.filtered_type 		= "BotanistHG";
		mappin.is_quest 			= false;
		mappin.appears_on_minimap 	= false;
		mappin.pointed_by_arrow 	= false;
		mappin.highlighted 		    = false;
		mappin.is_fast_travel		= false;		
		
		mappin.l_data               = Botanist_MapPinLookupData(this.spot_hash, this.spot_type, this.spot_region, true);

		if ( !this.is_displayed() )
		{
			this.entity_storage.botanist_displayed_harvesting_grounds[spot_region][spot_type].PushBack( this );
			this.entity_storage.botanist_displayed_harvesting_grounds_guid_hashes.PushBack( this.spot_hash );		
		}
		
		Idx = this.mappin_manager.mappins.FindFirst( this.mappin );
		
		if ( Idx != -1 )
		{
			this.mappin_manager.mappins[Idx] = this.mappin;
		}
		else
		{
			this.mappin_manager.mappins.PushBack( this.mappin );
		}
	}
	
	//---------------------------------------------------

	function remove_farming_spot() : void
	{
		var Idx : int;
		
		this.event_manager.unregister_for_event( botanist_event_data(BT_Herb_Looted, , , , this) );
		this.event_manager.unregister_for_event( botanist_event_data(BT_Herb_Clear_Except, , , , this) );
		
		for( Idx = this.spot_herbs.Size()-1; Idx >= 0 ; Idx -= 1 )
		{
			this.spot_herbs[Idx].herb.reset();
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
		return GetLocStringByKeyExt("BT_HarvestingGrounds");
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
			case BT_NoMansLand:	 	return SUH_normalizeRegion("no_mans_land");
			case BT_Skellige:	 	return SUH_normalizeRegion("skellige");
			case BT_KaerMorhen: 	return SUH_normalizeRegion("kaer_morhen");
			case BT_WhiteOrchard: 	return SUH_normalizeRegion("prolog_village");
			case BT_Toussaint: 		return SUH_normalizeRegion("bob");
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
		
		for( Idx = parent.spot_herbs.Size()-1; Idx >= 0 ; Idx -= 1 )
		{
			parent.spot_herbs[Idx].herb.set_displayed(parent.user_settings, true);
		}

		parent.GotoState('waiting');
	}
}