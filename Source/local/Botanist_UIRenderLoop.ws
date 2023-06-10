
//---------------------------------------------------
//-- Class ------------------------------------------
//---------------------------------------------------		

statemachine class Botanist_UIRenderLoop
{	
	public var master  : Botanist;
	public var config  : Botanist_Config;
	public var storage : Botanist_KnownEntityStorage;
	
	//---------------------------------------------------

	public function initialise(master: Botanist)
	{
		this.master  = master;
		this.config  = master.BT_ConfigSettings;
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
		var current_region 	 : BT_Herb_Region;
		
		var new_usersettings : Botanist_UserSettings;
		var old_usersettings : Botanist_UserSettings;
		
		var new_herb_requirements : Botanist_HerbRequirements;
		var old_herb_requirements : Botanist_HerbRequirements;
		
		var new_displayed_count : int;
		var old_displayed_count : int;
		
		var new_discovery_count : int;
		var old_discovery_count : int;
		
		var Idx              : int;
		var stt              : float;
		
		var target_herb		 : name;
		var target_quantity  : int;
		
		var changed_req, changed_set : bool;
		
		while(true)
		{
			stt = theGame.GetLocalTimeAsMilliseconds();
			current_region = botanist_get_herb_enum_region();

			//Generate a list of user settings.
			new_usersettings = parent.config.get_user_settings();		
			new_herb_requirements = this.get_herb_requirements(current_region, new_usersettings);
			
			//BT_Logger("UI Update Loop took: " + (theGame.GetLocalTimeAsMilliseconds() - stt) + " milliseconds to generate lists");
			
			//Obtain the base item name of the targetted herb if selected in the mod menu.
			target_herb = BT_GetOverrideItemName( new_usersettings.ints[BT_Config_Mod_Targets] );
			
			//Check for any changes to the required amount of herbs since the last iteration.
			changed_req = requirements_have_changed(old_herb_requirements, new_herb_requirements, target_herb);
			//BT_Logger("UI Update Loop took: " + (theGame.GetLocalTimeAsMilliseconds() - stt) + " milliseconds to check requirements");
			
			//Check for any changes the user has made to the mods settings since the last iteration.
			changed_set = settings_have_changed(old_usersettings, new_usersettings);
			//BT_Logger("UI Update Loop took: " + (theGame.GetLocalTimeAsMilliseconds() - stt) + " milliseconds to check settings");
			
			//If the user has changed any mod settings then update the existing harvesting grounds as the 3D markers are no longer held in temp display storage.
			if ( changed_set )
			{
				this.update_harvesting_grounds_with_new_settings(new_usersettings, current_region);
				//BT_Logger("UI Update Loop took: " + (theGame.GetLocalTimeAsMilliseconds() - stt) + " milliseconds to updated harvesting grounds");
			}			

			//If any changes are detected in the required ingredients or if the user has changed any mod settings then update the UI.
			if ( changed_req || changed_set )
			{
				//Clear all existing UI data such as map pins and 3D Markers for the current region.
				this.clear_existing_ui_data(current_region);
				//BT_Logger("UI Update Loop took: " + (theGame.GetLocalTimeAsMilliseconds() - stt) + " milliseconds to clear existing UI data");
				
				//If the player is only wanting to display a specific herb and that herb is required for a recipe then only process that one list.
				if ( target_herb != '' )
				{
					//if we are targetting a specific herb, remove all harvesting grounds not of this type.
					this.remove_all_harvesting_grounds_except( target_herb );
					
					if ( new_herb_requirements.names.Contains( target_herb ) )
					{
						Idx = new_herb_requirements.names.FindFirst( target_herb );
						(new Botanist_UIDisplayCreator in this).create_and_set_variables( Botanist_DataTransferStruct(current_region, BT_GetOverrideEnumValue( target_herb ), new_herb_requirements.quantities[Idx], new_usersettings, parent.storage) );
					}
				}
				else 
				{	
					//If the user is searching for all required herbs not just a specific one then process all lists of known herbs in that region.
					for( Idx = 0; Idx < new_herb_requirements.names.Size(); Idx += 1 )
					{
						(new Botanist_UIDisplayCreator in this).create_and_set_variables( Botanist_DataTransferStruct(current_region, botanist_get_herb_enum_from_name(new_herb_requirements.names[Idx]), new_herb_requirements.quantities[Idx], new_usersettings, parent.storage) );
					}
				}

			}
				
			//The UI is now updated, store the requirements and user settings in a seperate variable so we can compare them on the next iteration.
			old_usersettings = new_usersettings;
			old_herb_requirements = new_herb_requirements;
			
			//BT_Logger("UI Update Loop took: " + (theGame.GetLocalTimeAsMilliseconds() - stt) + " milliseconds to run");
			SleepOneFrame();
		}
	}

	//---------------------------------------------------
	
	private function get_herb_requirements(current_region: BT_Herb_Region, new_usersettings: Botanist_UserSettings) : Botanist_HerbRequirements
	{	
		var output_data : Botanist_HerbRequirements;		
		var output_name : name;
		var output_quan : int;
		var Idx : int;
		
		for( Idx = 1; Idx < EnumGetMax('BT_Herb_Enum')+1; Idx += 1 )
		{
			output_name = botanist_get_herb_name_from_enum( Idx );
			
			if ( !parent.storage.has_discovered_plants_in_region( output_name ) )
			{
				continue;
			}
			
			output_data.names.PushBack( output_name );
			output_data.quantities.PushBack ( new_usersettings.ints[BT_Config_Mod_Quantity] );
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
			}
		}

		return output_data;
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
		parent.master.BT_PersistentStorage.BT_EventHandler.send_event( botanist_event_data( BT_Herb_Reset ) );
		
		//This setup uses nested arrays so we need to re-initialise them for the next iteration of the monitoring loop.
		parent.storage.initialise_temporary_displayed_arrays();	
	}

	//---------------------------------------------------
	
	private function remove_all_harvesting_grounds_except( target_herb : name )
	{
		parent.master.BT_PersistentStorage.BT_EventHandler.send_event( botanist_event_data( BT_Herb_Clear_Except, , target_herb ) );
	}
	
	//---------------------------------------------------

	private function requirements_have_changed(old_data, new_data : Botanist_HerbRequirements, target_herb : name) : bool
	{
		var Idx, Edx : int;
		
		if ( target_herb != '' )
		{
			Edx = parent.storage.get_currently_displayed_count( botanist_get_herb_enum_region(), botanist_get_herb_enum_from_name( target_herb ) );
			Idx = new_data.names.FindFirst( target_herb );
			
			if ( (new_data.quantities[Idx] - Edx) > 0 && parent.storage.has_harvestable_plants_in_region( target_herb ) )
			{
				return true;
			}
			
			return false;
		}
		
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