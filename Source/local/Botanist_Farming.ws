
//---------------------------------------------------
//-- Botanist Main Harvesting Grounds Class ---------
//---------------------------------------------------

class BT_Harvesting_Ground
{
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
		var Idx : int;
		
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
		
		this.GotoState('monitor');
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

		this.GotoState('monitor');
	}

	//---------------------------------------------------
	
	function update(user_settings : Botanist_UserSettings)
	{
		var Idx : int;
		
		this.user_settings = user_settings;
		
		for( Idx = this.spot_herbs.Size()-1; Idx >= 0 ; Idx -= 1 )
		{
			this.spot_herbs[Idx].herb.set_displayed_in_grounds(this.user_settings);
		}
	}
	
	//---------------------------------------------------
	
	function validate_harvesting_ground() : void
	{
		var Idx : int;
		
		for( Idx = this.spot_herbs.Size()-1; Idx >= 0 ; Idx -= 1 )
		{
			if ( this.spot_herbs[Idx].herb.is_looted() )
			{
				this.spot_herbs[Idx].herb.reset( true );
				this.spot_herbs.EraseFast(Idx);
			}
		}

		Idx = this.mappin_manager.mappins.FindFirst(this.mappin);
		if ( Idx != -1 )
		{
			this.mappin_manager.mappins[Idx].description = this.get_mappin_description();
		}
			
		if ( this.spot_herbs.Size() <= 0 )
		{
			this.remove_farming_spot();
		}
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
			mappin.region 				= "prolog_village";
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

state monitor in BT_Harvesting_Ground 
{
	event OnEnterState(previous_state_name: name) 
	{
		super.OnEnterState(previous_state_name);
		BT_Logger(parent.spot_hash + "Entered state [monitor]");

		parent.display_farming_spot();
		parent.print_info();	
		
		this.monitor();
	}
	
	//-----------------------------------------------
	
	entry function monitor() : void
	{
		var Idx, Edx : int;

		for( Idx = parent.spot_herbs.Size()-1; Idx >= 0 ; Idx -= 1 )
		{
			parent.spot_herbs[Idx].herb.set_displayed_in_grounds(parent.user_settings);
		}		
		this.loop();
	}
	
	//-----------------------------------------------
	
	latent function loop() : void
	{
		var new_usersettings : Botanist_UserSettings;
		var old_usersettings : Botanist_UserSettings;
		
		while (true)
		{
			new_usersettings = parent.config.get_user_settings();

			if ( this.settings_have_changed(old_usersettings, new_usersettings) )
			{
				parent.update(new_usersettings);
			}
			
			old_usersettings = new_usersettings;
			parent.validate_harvesting_ground();			
			Sleep(3);
		}
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