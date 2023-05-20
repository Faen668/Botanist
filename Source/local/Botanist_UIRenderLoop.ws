
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

			//If any changes are detected in the required ingredients or if the user has changed any mod settings then update the UI.
			if ( requirements_have_changed(old_requirements, new_requirements) || settings_have_changed(old_usersettings, new_usersettings) )
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
			BT_Logger("CHANGE: Names Sizes");
			return true;
		}
		
		for( Idx = 0; Idx < new_data.names.Size(); Idx += 1 )
		{
			Edx = parent.storage.get_currently_displayed_count(botanist_get_herb_enum_region(), botanist_get_herb_enum_from_name(new_data.names[Idx]));
			
			if ( (new_data.quantities[Idx] - Edx) > 0 && parent.storage.has_harvestable_plants_in_region(new_data.names[Idx]) )
			{
				BT_Logger("CHANGE: Quantities Sizes");
				return true;
			}	
		
			if ( new_data.names[Idx] != old_data.names[Idx] )
			{
				BT_Logger("CHANGE: Name");
				return true;
			}

			if ( new_data.quantities[Idx] != old_data.quantities[Idx] )
			{
				BT_Logger("CHANGE: Quantity");
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
				BT_Logger("CHANGE: Bools");
				return true;
			}
		}

		for( Idx = 0; Idx < new_data.ints.Size(); Idx += 1 )
		{
			if ( new_data.ints[Idx] != old_data.ints[Idx] )
			{
				BT_Logger("CHANGE: Ints");
				return true;
			}
		}

		return false;
	}
}
