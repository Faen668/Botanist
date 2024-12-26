//---------------------------------------------------
//-- Botanist Main Class ----------------------------
//---------------------------------------------------

statemachine class Botanist 
{
	public saved var BT_PersistentStorage : Botanist_Storage;
	public var BT_RenderingLoop           : Botanist_UIRenderLoop;
	public var BT_TutorialsSystem         : Botanist_TutorialsSystem;
	public var BT_FocusModeHander         : Botanist_FocusModeHandler;
	
	//-----------------------------------------------

	public function start() : void
	{	
		if ( thePlayer.IsCiri() )
		{
			BT_Logger("Unable to start as Ciri");
			return;
		}
		
		this.BT_RenderingLoop   = new Botanist_UIRenderLoop in this;
		this.BT_TutorialsSystem = new Botanist_TutorialsSystem in this;
		this.BT_FocusModeHander = new Botanist_FocusModeHandler in this;
		this.GotoState('Initialising');
	}
	
	//-----------------------------------------------
	
	public function SetEntityKnown(potential_herb: W3RefillableContainer) : void
	{	
		var herb_entity     : W3Herb;
		var herb_tag        : name;
		var herb_guid       : int;
		var created_herb    : BT_Herb;
		
		herb_entity = (W3Herb)potential_herb;
		herb_guid   = herb_entity.GetGuidHash();
		herb_tag    = herb_entity.get_herb_name();
		
		if ( herb_entity && !this.BT_PersistentStorage.BT_HerbStorage.is_herb_excluded(herb_guid) && BT_IsValidHerb(herb_tag) && !this.BT_PersistentStorage.BT_HerbStorage.botanist_known_herbs_guid_hashes.Contains(herb_guid) )
		{
			created_herb = new BT_Herb in this;
			
			if ( created_herb.create_new_herb(herb_entity, herb_entity.GetWorldPosition(), herb_tag, herb_guid, theGame.GetCommonMapManager().GetCurrentArea(), this) )
				this.BT_TutorialsSystem.show_tutorial( Botanist_Tutorial_Discovery );
		}
	}

	//-----------------------------------------------
	
	public function SetEntityLooted(potential_herb: W3RefillableContainer) : void
	{
		BT_PersistentStorage.BT_EventHandler.send_event( botanist_event_data( BT_Herb_Looted, potential_herb.GetGuidHash() ) );
		BT_Logger("LOOTED: [HASH = " + potential_herb.GetGuidHash() + "] [POSITION = " + BT_VectorToString(potential_herb.GetWorldPosition()) + "]");
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
		
		parent.BT_TutorialsSystem.show_tutorial( Botanist_Tutorial_Installation );
	}
}

//---------------------------------------------------
//-- Botanist Main Class - (Initialising State) -----
//---------------------------------------------------

state Initialising in Botanist 
{
	private var curVersionStr: string;
		default curVersionStr = "1.0.8";
		
	private var curVersionInt: int;
		default curVersionInt = 108;
	
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
		
		this.Initialising_Main();
	}

	//-----------------------------------------------
	
	entry function Initialising_Main() : void
	{	
		var Idx: int;

		while (BT_Mod_Not_Ready()) 
		{
		  Sleep(5);
		}
		
		thePlayer.InitBotanistSettings();
		BT_LoadStorageCollection(parent);
		
		this.SetModVersion();
		
		parent.BT_RenderingLoop		.initialise(parent);
		parent.BT_FocusModeHander 	.initialise(parent);
		parent.BT_TutorialsSystem   .initialise(parent);
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
			if (FactsQuerySum(VersStr) < 105) { FactsSet(VersStr, 105); this.remove_excluded_herbs(); hasUpdated = true; }
			if (FactsQuerySum(VersStr) < 108) { FactsSet(VersStr, 108); hasUpdated = true; }
		}
	}
	
	//-----------------------------------------------
	
	latent function remove_excluded_herbs() : void
	{
		var Idx, Edx, Rdx, Pdx, Sdx, Ldx, Qdx : int;
		
		for (Idx = 0; Idx < parent.BT_PersistentStorage.BT_HerbStorage.excluded_herbs.Size(); Idx += 1) 
		{
			Pdx = parent.BT_PersistentStorage.BT_HerbStorage.excluded_herbs[Idx];

			for (Sdx = 0; Sdx < parent.BT_PersistentStorage.BT_HerbStorage.botanist_known_herbs.Size(); Sdx += 1) 
			{
				for (Ldx = parent.BT_PersistentStorage.BT_HerbStorage.botanist_known_herbs[Sdx].Size(); Ldx >= 0 ; Ldx -= 1) 
				{
					for (Qdx = parent.BT_PersistentStorage.BT_HerbStorage.botanist_known_herbs[Sdx][Ldx].Size(); Qdx >= 0 ; Qdx -= 1) 
					{
						if ( parent.BT_PersistentStorage.BT_HerbStorage.botanist_known_herbs[Sdx][Ldx][Qdx].herb_guidhash == Pdx )
						{
							parent.BT_PersistentStorage.BT_HerbStorage.botanist_known_herbs[Sdx][Ldx].EraseFast(Qdx);
							BT_Logger("Erased Excluded Herb From Known Herbs: " + Pdx);
						}
					}
				}
			}
			
			Edx = parent.BT_PersistentStorage.BT_HerbStorage.botanist_known_herbs_guid_hashes.FindFirst( Pdx );
			if ( Edx != -1 )
			{
				parent.BT_PersistentStorage.BT_HerbStorage.botanist_known_herbs_guid_hashes.Erase( Edx );
				BT_Logger("Erased Excluded Herb From Known Hashs: " + Pdx);
			}					
			
			Edx = parent.BT_PersistentStorage.BT_HerbStorage.botanist_master_hashs.FindFirst( Pdx );
			
			if ( Edx != -1 )
			{
				parent.BT_PersistentStorage.BT_HerbStorage.botanist_master_herbs.Erase( Edx );
				parent.BT_PersistentStorage.BT_HerbStorage.botanist_master_hashs.Erase( Edx );
				parent.BT_PersistentStorage.BT_HerbStorage.botanist_master_names.Erase( Edx );
				parent.BT_PersistentStorage.BT_HerbStorage.botanist_master_world.Erase( Edx );
				BT_Logger("Erased Excluded Herb From Master Hashs: " + Pdx);
			}
		}	
	}
}
//---------------------------------------------------
//-- Bootstrapper Wrapper ---------------------------
//---------------------------------------------------

@addField( CR4Player )
public saved var BotanistClass: Botanist;

@addField( CR4Player )
public var BotanistSettings: Botanist_Config;

@wrapMethod( CR4Player ) function InitTargeting()
{
	wrappedMethod();
	
	if (!BotanistClass)
	{
		BT_Logger("Creating new Botanist Instance...");
		BotanistClass = (new Botanist in this);
	}
	else
	{
		BT_Logger("Loading existing Botanist Instance...");
	}
	
	BotanistClass.start();
}

@addMethod(CR4Player) public function InitBotanistSettings() : void
{
	BotanistSettings = new Botanist_Config in this;
	BotanistSettings.initialise(BotanistClass);
}

@addMethod(CR4Player) public function GetBotanistConfig() : Botanist_Config
{
	return BotanistSettings;
}

@addMethod(CR4Player) public function GetBotanistSettings(type: Botanist_UserSettings_Type) : Botanist_UserSettings
{
	switch(type)
	{
		case BT_Config_User			: return BotanistSettings.user_settings; break;
		case BT_Config_Discovery	: return BotanistSettings.discovery_settings; break;
		case BT_Config_Tutorial		: return BotanistSettings.tutorial_settings; break;
	}
	return NULL;
}

//---------------------------------------------------
//-- Botanist Settings Updater ----------------------
//---------------------------------------------------

@wrapMethod( CR4CommonIngameMenu ) function OnClosingMenu()
{
	var master : Botanist;

	wrappedMethod();
	if (Get_Botanist(master, 'OnClosingMenu'))
		thePlayer.GetBotanistConfig().update();
}
	
//---------------------------------------------------
//-- Botanist Herb Array Methods --------------------
//---------------------------------------------------

@addField(CR4Game)
var BT_SpawnedEntities : array<W3Herb>;

@addMethod(CR4Game) public function BT_GetArray() : array <W3Herb>
{
	return BT_SpawnedEntities;
}

@addMethod(CR4Game) public function BT_ClearArray() : void
{
	BT_SpawnedEntities.Clear();
}

@addMethod(CR4Game) public function BT_AddSpawnedEntity(ent : W3Herb) : void
{
	BT_SpawnedEntities.PushBack(ent);
}

//---------------------------------------------------
//-- Botanist Focus Handler Hook --------------------
//---------------------------------------------------

@wrapMethod(CFocusModeController) function ActivateInternal()
{
	wrappedMethod();
	BT_SetFocussing();
}

//---------------------------------------------------
//-- Botanist Herb Handler Hook ---------------------
//---------------------------------------------------

@wrapMethod(W3Herb) function OnSpawned( spawnData : SEntitySpawnData )
{
	wrappedMethod(spawnData);
	theGame.BT_AddSpawnedEntity(this);
}

@wrapMethod(W3Herb) function ApplyAppearance( appearanceName : string )
{
	if ( appearanceName == "2_empty" ) 
	{
		BT_SetEntityLooted(this);
	}
	wrappedMethod(appearanceName);
}

@addMethod(W3Herb) function get_herb_name() : name
{
	var items : array< SItemUniqueId >;
	
	inv.GetAllItems( items );
	if ( !items.Size() )
		return '';
	
	return inv.GetItemName( items[ 0 ] );
}

@addMethod(W3Herb) function is_empty() : bool
{
	return inv.IsEmpty();
}

@wrapMethod(W3RefillableContainer) function OnInteractionActivated(interactionComponentName : string, activator : CEntity) 
{
	wrappedMethod(interactionComponentName, activator);
	BT_SetEntityKnown( this );
}



//---------------------------------------------------
//-- Botanist User Settings Class -------------------
//---------------------------------------------------

class Botanist_Config
{
	public var master 				: Botanist;
	public var marker_manager		: SUOL_Manager;
	public var mappin_manager  		: SUMP_Manager;
	public var user_settings		: Botanist_UserSettings;
	public var discovery_settings	: Botanist_UserSettings;
	public var tutorial_settings	: Botanist_UserSettings;

	//-----------------------------------------------

	public function initialise(master: Botanist) : void
	{
		this.master = master;
		this.update();
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
		 case 2: return 'Botanist_Markers_Visible';
		 case 3: return 'Botanist_Markers_FontSize';
		 case 4: return 'Botanist_MapPins_Radius';
		 case 5: return 'Botanist_Farming_Radius';
		 case 6: return 'Botanist_Farming_MinReq';
		 case 7: return 'Botanist_Farming_MaxAll';
		 case 8: return 'Botanist_Farming_MaxGrd';
		 case 9: return 'Botanist_Mod_Quantity';
		}
	}

	//-----------------------------------------------

	public function get_config_tutorial_name(Idx : int) : name
	{
		switch (Idx)
		{
			case 0: return 'Botanist_Tutorial_Installation';
			case 1: return 'Botanist_Tutorial_Discovery';
			case 2: return 'Botanist_Tutorial_HarvestingGrounds';
		}
	}

	//-----------------------------------------------

	public function get_config_discovery_name(Idx : int) : name
	{
		switch (Idx)
		{
			case 0: return 'Botanist_Discovery_Method';
			case 1: return 'Botanist_Discovery_Range';
		}
	}

	//-----------------------------------------------
	
	private function destroy() : void
	{
		this.marker_manager = NULL;
		this.mappin_manager = NULL;
		this.user_settings = NULL;
		this.discovery_settings = NULL;
		this.tutorial_settings = NULL;
	}
	
	//-----------------------------------------------
	
	public function update() : void
	{
		this.destroy();
		
		this.marker_manager = SUOL_getManager();
		this.mappin_manager = SUMP_getManager();

		if ( !this.marker_manager )
		{
			BT_Logger("Failed to get marker_manager...");
		}

		if ( !this.mappin_manager )
		{
			BT_Logger("Failed to get mappin_manager...");
		}
		
		this.user_settings = (new Botanist_UserSettings in this).get_user_settings();
		this.discovery_settings = (new Botanist_UserSettings in this).get_discovery_settings();
		this.tutorial_settings = (new Botanist_UserSettings in this).get_tutorial_settings();
		
		if (!this.user_settings || !this.discovery_settings || !this.tutorial_settings )
		{
			BT_Logger("Failed to update settings...");
			return;
		}
		
		BT_Logger("Settings Updated Succesfully...");
	}
}


//---------------------------------------------------
//-- Botanist User Settings Struct ------------------
//---------------------------------------------------

class Botanist_UserSettings
{
	var bools : array<bool>;
	var ints  : array<int>;

	public function get_user_settings() : Botanist_UserSettings
	{
		var config_wrapper : CInGameConfigWrapper = theGame.GetInGameConfigWrapper();

		this.bools.PushBack(config_wrapper.GetVarValue('Botanist_HerbMarkers', 'Botanist_Markers_Enabled'));
		this.bools.PushBack(config_wrapper.GetVarValue('Botanist_GeneralSettings', 'Botanist_MapPins_Enabled'));
		this.bools.PushBack(config_wrapper.GetVarValue('Botanist_HarvestingGrounds', 'Botanist_Farming_Enabled'));
		
		this.ints.PushBack(StringToInt(config_wrapper.GetVarValue('Botanist_GeneralSettings', 'Botanist_Mod_Targets')));
		this.ints.PushBack(StringToInt(config_wrapper.GetVarValue('Botanist_HerbMarkers', 'Botanist_Markers_Active')));
		this.ints.PushBack(StringToInt(config_wrapper.GetVarValue('Botanist_HerbMarkers', 'Botanist_Markers_Visible')));
		this.ints.PushBack(StringToInt(config_wrapper.GetVarValue('Botanist_HerbMarkers', 'Botanist_Markers_FontSize')));	
		this.ints.PushBack(StringToInt(config_wrapper.GetVarValue('Botanist_GeneralSettings', 'Botanist_MapPins_Radius')));
		this.ints.PushBack(StringToInt(config_wrapper.GetVarValue('Botanist_HarvestingGrounds', 'Botanist_Farming_Radius')));
		this.ints.PushBack(StringToInt(config_wrapper.GetVarValue('Botanist_HarvestingGrounds', 'Botanist_Farming_MinReq')));
		this.ints.PushBack(StringToInt(config_wrapper.GetVarValue('Botanist_HarvestingGrounds', 'Botanist_Farming_MaxAll')));
		this.ints.PushBack(StringToInt(config_wrapper.GetVarValue('Botanist_HarvestingGrounds', 'Botanist_Farming_MaxGrd')));
		this.ints.PushBack(StringToInt(config_wrapper.GetVarValue('Botanist_GeneralSettings', 'Botanist_Mod_Quantity')));
		return this;
	}

	public function get_discovery_settings() : Botanist_UserSettings
	{
		var config_wrapper : CInGameConfigWrapper = theGame.GetInGameConfigWrapper();
		
		this.ints.PushBack(StringToInt(config_wrapper.GetVarValue('Botanist_GeneralSettings', 'Botanist_Discovery_Method')));
		this.ints.PushBack(StringToInt(config_wrapper.GetVarValue('Botanist_GeneralSettings', 'Botanist_Discovery_Range')));
		return this;
	}

	public function get_tutorial_settings() : Botanist_UserSettings
	{
		var config_wrapper : CInGameConfigWrapper = theGame.GetInGameConfigWrapper();
		
		this.bools.PushBack(config_wrapper.GetVarValue('Botanist_Tutorials', 'Botanist_Tutorial_Installation'));
		this.bools.PushBack(config_wrapper.GetVarValue('Botanist_Tutorials', 'Botanist_Tutorial_Discovery'));
		this.bools.PushBack(config_wrapper.GetVarValue('Botanist_Tutorials', 'Botanist_Tutorial_HarvestingGrounds'));
		return this;
	}
	
	public function log() : void
	{		
		var Notification : string = "";
		GetWitcherPlayer().DisplayHudMessage("Logging");
		
		BT_Logger("Botanist Config Settings:");
		BT_Logger("BT_Config_Ols_Enabled 	- " + this.bools[BT_Config_Ols_Enabled] );
		BT_Logger("BT_Config_Pin_Enabled 	- " + this.bools[BT_Config_Pin_Enabled] );
		BT_Logger("BT_Config_Hgr_Enabled 	- " + this.bools[BT_Config_Hgr_Enabled] );

		BT_Logger("BT_Config_Mod_Targets  	- " + this.ints[BT_Config_Mod_Targets]  );
		BT_Logger("BT_Config_Ols_Active  	- " + this.ints[BT_Config_Ols_Active]   );
		BT_Logger("BT_Config_Ols_Visible  	- " + this.ints[BT_Config_Ols_Visible]  );
		BT_Logger("BT_Config_Ols_Fontsize 	- " + this.ints[BT_Config_Ols_Fontsize] );
		BT_Logger("BT_Config_Pin_Radius  	- " + this.ints[BT_Config_Pin_Radius]   );
		BT_Logger("BT_Config_Hgr_Radius   	- " + this.ints[BT_Config_Hgr_Radius]   );
		BT_Logger("BT_Config_Hgr_MinReq   	- " + this.ints[BT_Config_Hgr_MinReq]   );
		BT_Logger("BT_Config_Hgr_MaxAll   	- " + this.ints[BT_Config_Hgr_MaxAll]   );
		BT_Logger("BT_Config_Hgr_MaxGrd   	- " + this.ints[BT_Config_Hgr_MaxGrd]   );
		BT_Logger("BT_Config_Mod_Quantity 	- " + this.ints[BT_Config_Mod_Quantity] );
	}
}

//---------------------------------------------------
//-- Botanist Event Manager Class -------------------
//---------------------------------------------------

class Botanist_EventHandler 
{
	private var on_herb_reset_registrations  : array< BT_Herb >;
	private var on_herb_looted_registrations : array< BT_Herb >;
	private var on_herb_looted_registrations_hg : array< BT_Harvesting_Ground >;
	private var on_harvesting_ground_update_registrations : array< BT_Harvesting_Ground >;
	private var on_herb_clear_except_registrations_hg : array< BT_Harvesting_Ground >;
	
	//-----------------------------------------------
	
	public function get_registration_count() : int
	{
		return 
			  on_herb_looted_registrations.Size() 
			+ on_herb_looted_registrations_hg.Size() 
			+ on_herb_reset_registrations.Size()
			+ on_herb_clear_except_registrations_hg.Size()
			+ on_harvesting_ground_update_registrations.Size();
	}

	//-----------------------------------------------
	
	public function clear_all_registered_events() : void
	{
		on_herb_reset_registrations.Clear();
		on_herb_looted_registrations.Clear();
		on_herb_looted_registrations_hg.Clear();
		on_herb_clear_except_registrations_hg.Clear();	
		on_harvesting_ground_update_registrations.Clear();
	}
	
	//-----------------------------------------------
	
	public function send_event( data : botanist_event_data ) : void
	{
		var Idx : int;
		var temp_hg : array< BT_Harvesting_Ground >;
		
		switch ( data.type )
		{
			case BT_Herb_Looted : 
			{
				for (Idx = 0; Idx < this.on_herb_looted_registrations.Size(); Idx += 1) 
				{
					this.on_herb_looted_registrations[Idx].On_herb_looted( data._int );
				}	
				
				for (Idx = 0; Idx < this.on_herb_looted_registrations_hg.Size(); Idx += 1) 
				{
					this.on_herb_looted_registrations_hg[Idx].On_herb_looted( data._int );
				}
				break;
			}

			case BT_Herb_Reset : 
			{
				for (Idx = 0; Idx < this.on_herb_reset_registrations.Size(); Idx += 1) 
				{
					this.on_herb_reset_registrations[Idx].On_herb_reset();
				}
				break;				
			}

			case BT_Herb_Clear_Except : 
			{
				temp_hg = on_herb_clear_except_registrations_hg;
				
				for (Idx = 0; Idx < temp_hg.Size(); Idx += 1) 
				{
					temp_hg[Idx].On_clear_except( data._name );
				}
				break;				
			}
			
			case BT_HarvestingGrounds_Update:
			{
				for (Idx = 0; Idx < this.on_harvesting_ground_update_registrations.Size(); Idx += 1) 
				{
					this.on_harvesting_ground_update_registrations[Idx].update();
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
				if ( data.herb && !this.on_herb_looted_registrations.Contains(data.herb) ) {
					this.on_herb_looted_registrations.PushBack( data.herb );
				}	
				
				if ( data.harvesting_ground && !this.on_herb_looted_registrations_hg.Contains(data.harvesting_ground) ) {
					this.on_herb_looted_registrations_hg.PushBack( data.harvesting_ground );
				}
				break;
			}

			case BT_Herb_Reset : 
			{
				if ( data.herb && !this.on_herb_reset_registrations.Contains(data.herb) ) {
					this.on_herb_reset_registrations.PushBack( data.herb );
				}
				break;
			}

			case BT_Herb_Clear_Except : 
			{
				if ( data.harvesting_ground && !this.on_herb_clear_except_registrations_hg.Contains(data.harvesting_ground) ) {
					this.on_herb_clear_except_registrations_hg.PushBack( data.harvesting_ground );
				}
				break;				
			}

			case BT_HarvestingGrounds_Update:
			{
				if ( data.harvesting_ground && !this.on_harvesting_ground_update_registrations.Contains(data.harvesting_ground) ) {
					this.on_harvesting_ground_update_registrations.PushBack( data.harvesting_ground );
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
				if ( data.herb ) {
					this.on_herb_looted_registrations.Remove( data.herb );
				}
				
				if ( data.harvesting_ground ) {
					this.on_herb_looted_registrations_hg.Remove( data.harvesting_ground );
				}
				break;
			}

			case BT_Herb_Reset : 
			{
				if ( data.herb ) {
					this.on_herb_reset_registrations.Remove( data.herb );
				}
				break;
			}

			case BT_Herb_Clear_Except : 
			{
				if ( data.harvesting_ground ) {
					this.on_herb_clear_except_registrations_hg.Remove( data.harvesting_ground );
				}
				break;				
			}

			case BT_HarvestingGrounds_Update:
			{
				if ( data.harvesting_ground ) {
					this.on_harvesting_ground_update_registrations.Remove( data.harvesting_ground );
				}		
			}
			
			default : break;
		}
	}
}

//---------------------------------------------------
//-- Botanist Focus Handler -------------------------
//---------------------------------------------------

statemachine class Botanist_FocusModeHandler 
{
	public var master : Botanist;
	
	//-----------------------------------------------

	public function initialise(master: Botanist) : void
	{
		this.master = master;
	}

	//-----------------------------------------------
	
	public function start() : void
	{
		this.GotoState('Focus');
	}

	//-----------------------------------------------
	
	public function stop() : void
	{
		this.GotoState('Idle');
	}
}

//---------------------------------------------------
//-- Botanist Botanist Focus Handler - (Idle State) -
//---------------------------------------------------

state Idle in Botanist_FocusModeHandler 
{
	event OnEnterState(previous_state_name: name) 
	{
		super.OnEnterState(previous_state_name);
	}
}

//---------------------------------------------------
//-- Botanist Botanist Focus Handler - (Focus State) -
//---------------------------------------------------

state Focus in Botanist_FocusModeHandler 
{
	event OnEnterState(previous_state_name: name) 
	{
		super.OnEnterState(previous_state_name);
		this.monitor_focus_mode();
	}
	
	entry function monitor_focus_mode() : void
	{
		var settings : Botanist_UserSettings = BT_GetUserSettings(BT_Config_Discovery);
		
		var Idx : int;
		var ents, cache : array<CGameplayEntity>;

		while(true)
		{
			if ( !theGame.IsFocusModeActive() || settings.ints[BT_Config_Disc_Method] == 2 )
			{
				parent.stop();
				break;
			}
			
			ents.Clear();
			FindGameplayEntitiesCloseToPoint( ents, thePlayer.GetWorldPosition(), settings.ints[BT_Config_Disc_Range], 50, , , ,'W3Herb' );

			for( Idx = ents.Size(); Idx >= 0 ; Idx -= 1 )
			{
				if ( !cache.Contains( ents[Idx] ) )
					parent.master.SetEntityKnown( (W3RefillableContainer)ents[Idx] );
				
				cache.PushBack( ents[Idx] );
				ents.EraseFast( Idx );
			}
			
			SleepOneFrame();
		}	
	}
}
//---------------------------------------------------
//-- Functions --------------------------------------
//---------------------------------------------------

function Get_Botanist(out master: Botanist, optional caller: string): bool 
{
	if (BT_Mod_Not_Ready())
	{
		return false;
	}
	
	master = thePlayer.BotanistClass;
	
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
	
	if (Get_Botanist(master, 'BT_SetEntityKnown'))
		master.SetEntityKnown(ent);
}
	
//---------------------------------------------------
//-- Functions --------------------------------------
//---------------------------------------------------

function BT_SetEntityLooted(ent: W3RefillableContainer) : void
{
	var master : Botanist;

	if (Get_Botanist(master, 'BT_SetEntityLooted'))
		master.SetEntityLooted(ent);
}

//---------------------------------------------------
//-- Functions --------------------------------------
//---------------------------------------------------

function BT_SetFocussing() : void
{
	var master : Botanist;

	if (Get_Botanist(master, 'BT_SetFocussing'))
		master.BT_FocusModeHander.start();
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

function BT_Mod_Not_Ready(): bool 
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
//-- Settings Return Functions ----------------------
//---------------------------------------------------

function BT_GetUserSettings(type: Botanist_UserSettings_Type) : Botanist_UserSettings
{
	return thePlayer.GetBotanistSettings(type);
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
	
	//Glassfish Herbs - https://www.nexusmods.com/witcher3/mods/8258
	case 'Belladonna':           { return BT_Belladonna; }
	case 'Burmarigold':          { return BT_Burmarigold; }
	case 'Chamomile':            { return BT_Chamomile; }
	case 'Hemlock':            	 { return BT_Hemlock; }
	case 'Scleroderm':           { return BT_Scleroderm; }
	case 'Aloe leaves':          { return BT_Aloeleaves; }

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
	
	//Glassfish Herbs - https://www.nexusmods.com/witcher3/mods/8258
	case BT_Belladonna:          return 'Belladonna';
	case BT_Burmarigold:         return 'Burmarigold';
	case BT_Chamomile:         	 return 'Chamomile';
	case BT_Hemlock:             return 'Hemlock';
	case BT_Scleroderm:          return 'Scleroderm';
	case BT_Aloeleaves:     	 return 'Aloe leaves';
	
	default : return '';
	}
}

//---------------------------------------------------
//-- Enum Return Functions --------------------------
//---------------------------------------------------

function botanist_get_herb_int_from_enum(value : BT_Herb_Enum) : int
{
	switch(value)
	{
	case BT_Allspiceroot:        return 0;
	case BT_Arenaria:            return 1;
	case BT_Balissefruit:        return 2;
	case BT_Beggartickblossoms:  return 3;
	case BT_Berbercanefruit:     return 4;
	case BT_Bloodmoss:           return 5;
	case BT_Blowbill:            return 6;
	case BT_Bryonia:             return 7;
	case BT_Buckthorn:           return 8;
	case BT_Celandine:           return 9;
	case BT_Cortinarius:         return 10;
	case BT_Crowseye:            return 11;
	case BT_Ergotseeds:          return 12;
	case BT_Foolsparsleyleaves:  return 13;
	case BT_Ginatiapetals:       return 14;
	case BT_Greenmold:           return 15;
	case BT_Han:                 return 16;
	case BT_Helleborepetals:     return 17;
	case BT_Honeysuckle:         return 18;
	case BT_Hopumbels:           return 19;
	case BT_Hornwort:            return 20;
	case BT_Longrube:            return 21;
	case BT_Mandrakeroot:        return 22;
	case BT_Mistletoe:           return 23;
	case BT_Moleyarrow:          return 24;
	case BT_Nostrix:             return 25;
	case BT_Pigskinpuffball:     return 26;
	case BT_Pringrape:           return 27;
	case BT_Ranogrin:            return 28;
	case BT_Ribleaf:             return 29;
	case BT_Sewantmushrooms:     return 30;
	case BT_Verbena:             return 31;
	case BT_Whitemyrtle:         return 32;
	case BT_Wolfsbane:           return 33;
	
	//Glassfish Herbs - https://www.nexusmods.com/witcher3/mods/8258
	case BT_Belladonna:          return 34;
	case BT_Burmarigold:         return 35;
	case BT_Chamomile:           return 36;
	case BT_Hemlock:             return 37;
	case BT_Scleroderm:          return 38;
	case BT_Aloeleaves:     	 return 39;

	default : return -1;               
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
//-- Enum Return Functions --------------------------
//---------------------------------------------------

function botanist_get_herb_region_from_int_debug_function(value: int) : string
{
	switch( value )
	{
		case 0: return "Invalid Location";
		case 1: return "White Orchard";
		case 2: return "No Mans Land";
		case 3: return "Skellige";
		case 4: return "Kaer Morhen";
		case 5: return "Toussaint";
		default: return "";
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
	
	//Glassfish Herbs - https://www.nexusmods.com/witcher3/mods/8258
	case 'Belladonna':
	case 'Burmarigold':
	case 'Chamomile':
	case 'Hemlock':
	case 'Scleroderm':
	case 'Aloe leaves':
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
	
	//Glassfish Herbs - https://www.nexusmods.com/witcher3/mods/8258
	case 35: return 'Belladonna';
	case 36: return 'Burmarigold';
	case 37: return 'Chamomile';
	case 38: return 'Hemlock';
	case 39: return 'Scleroderm';
	case 40: return 'Aloe leaves';

	default: return '';
	}
}        

exec function bt_reset()
{
	var master : Botanist;
	
	if (!Get_Botanist(master, 'bt_reset'))
	{
		return;
	}
	master.BT_PersistentStorage.BT_HerbStorage.reset_and_clerar();
}

exec function bt_clear()
{
	var master : Botanist;
	
	if (!Get_Botanist(master, 'bt_reset'))
	{
		return;
	}
	master.BT_PersistentStorage.BT_HerbStorage.reset_ui();
}

exec function bt_settings()
{
	thePlayer.GetBotanistConfig().user_settings.log();
}
//---------------------------------------------------
//-- Botanist Main Harvesting Grounds Class ---------
//---------------------------------------------------

statemachine class BT_Harvesting_Ground
{
	var event_manager   : Botanist_EventHandler; 
	var entity_storage  : Botanist_KnownEntityStorage;
	
	// Creation Data
	var spot_herbs	: array<Botanist_NodePairing>;
	var spot_region	: BT_Herb_Region;
	var spot_type	: BT_Herb_Enum;
	var spot_hash	: int;
	var spot_total  : int;

	// Map Pin Data
	var mappin		    : BT_MapPin;
	var mappin_pos	    : Vector;
	var mappin_rad	    : float;
	var mappin_name  	: string;
	
	//Set when looted event procs for lookup from the state.
	var looted_hash		: int;

	//Set when remove event procs for specific harvesting grounds types.
	var removed_name		: name;
	
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
		
		this.spot_herbs      = Harvest_Grounds_Results.harvesting_nodes;
		this.spot_region     = region;
		this.spot_type       = type;
		this.spot_hash		 = spot_herbs[0].herb.herb_guidhash + 6558;
		this.spot_total		 = spot_herbs.Size();
		
		this.mappin_pos      = mappin_pos;
		this.mappin_rad      = mappin_rad;
		this.mappin_name     = GetLocStringByKeyExt(theGame.GetDefinitionsManager().GetItemLocalisationKeyName( botanist_get_herb_name_from_enum( this.spot_type ) ));
		this.apply_random_boon();
		
		this.display_farming_spot();
		this.print_info();
		
		this.event_manager.register_for_event( botanist_event_data(BT_Herb_Looted, , , , this) );
		this.event_manager.register_for_event( botanist_event_data(BT_Herb_Clear_Except, , , , this) );
		
		master.BT_TutorialsSystem.show_tutorial( Botanist_Tutorial_HarvestingGrounds );
		
		this.GotoState('on_update');
		return this;
	}

	//---------------------------------------------------
	
	function load()
	{
		var Idx 		: int;
		var settings	: Botanist_UserSettings = BT_GetUserSettings(BT_Config_User);
		
		if ( !settings.bools[BT_Config_Hgr_Enabled] || this.spot_herbs.Size() < 1 )
		{
			this.remove_farming_spot();
			return;			
		}
		
		for( Idx = this.spot_herbs.Size()-1; Idx >= 0 ; Idx -= 1 )
		{
			if ( !this.spot_herbs[Idx].herb.is_looted() && !this.entity_storage.is_herb_excluded( this.spot_herbs[Idx].herb.herb_guidhash ) )
			{
				this.spot_herbs[Idx].herb.set_displayed(true);
				continue;
			}

			this.spot_herbs[Idx].herb.reset();
			this.spot_herbs.EraseFast(Idx);
		}
		
		this.event_manager.register_for_event( botanist_event_data(BT_Herb_Looted, , , , this) );
		this.event_manager.register_for_event( botanist_event_data(BT_Herb_Clear_Except, , , , this) );
		this.event_manager.register_for_event( botanist_event_data(BT_HarvestingGrounds_Update, , , , this) );
		
		this.display_farming_spot();
		this.update_mappin_description();
	}

	//---------------------------------------------------
	
	function update()
	{	
		this.GotoState('on_update');
	}
	
	//---------------------------------------------------
	
	function update_mappin_description() : void
	{
		var mappin_manager: SUMP_Manager = thePlayer.GetBotanistConfig().mappin_manager;
		var Idx : int = mappin_manager.mappins.FindFirst( this.mappin );

		if ( Idx != -1 )
		{
			mappin_manager.mappins[Idx].description = this.get_mappin_description();
		}
	}

	//---------------------------------------------------
	
	event On_herb_looted(hash : int) : void
	{
		this.looted_hash = hash;
		this.GotoState('on_looted');
	}

	//---------------------------------------------------
	
	event On_clear_except( _name : name )
	{
		this.removed_name = _name;
		this.GotoState('on_remove');
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
		var mappin_manager: SUMP_Manager = thePlayer.GetBotanistConfig().mappin_manager;
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
		
		Idx = mappin_manager.mappins.FindFirst( this.mappin );
		
		if ( Idx != -1 )
		{
			mappin_manager.mappins[Idx] = this.mappin;
		}
		else
		{
			mappin_manager.mappins.PushBack( this.mappin );
		}
	}
	
	//---------------------------------------------------

	function remove_farming_spot() : void
	{
		var Idx : int;
		
		this.event_manager.unregister_for_event( botanist_event_data(BT_Herb_Looted, , , , this) );
		this.event_manager.unregister_for_event( botanist_event_data(BT_Herb_Clear_Except, , , , this) );
		this.event_manager.unregister_for_event( botanist_event_data(BT_HarvestingGrounds_Update, , , , this) );
		
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

state on_update in BT_Harvesting_Ground 
{
	event OnEnterState(previous_state_name: name) 
	{	
		this.run_update();
		super.OnEnterState(previous_state_name);
	}

	entry function run_update()
	{
		var Idx : int;		
		for( Idx = parent.spot_herbs.Size()-1; Idx >= 0 ; Idx -= 1 )
		{
			parent.spot_herbs[Idx].herb.set_displayed(true);
		}
		parent.GotoState('waiting');
	}
}

//---------------------------------------------------
//-- Botanist Main Harvesting Grounds States --------
//---------------------------------------------------

state on_looted in BT_Harvesting_Ground 
{
	event OnEnterState(previous_state_name: name) 
	{			
		this.loot();
		super.OnEnterState(previous_state_name);
	}

	entry function loot()
	{
		var Idx : int;
		
		for( Idx = parent.spot_herbs.Size()-1; Idx >= 0 ; Idx -= 1 )
		{
			if ( parent.spot_herbs[Idx].herb.herb_guidhash == parent.looted_hash )
			{
				parent.spot_herbs.EraseFast(Idx);
				break;
			}
		}
		
		if ( parent.spot_herbs.Size() <= 0 )
		{
			parent.remove_farming_spot();
		}
		parent.update_mappin_description();
		parent.GotoState('waiting');
	}
}

//---------------------------------------------------
//-- Botanist Main Harvesting Grounds States --------
//---------------------------------------------------

state on_remove in BT_Harvesting_Ground 
{
	event OnEnterState(previous_state_name: name) 
	{			
		this.run_removal();
		super.OnEnterState(previous_state_name);
	}

	entry function run_removal()
	{
		if ( parent.removed_name != botanist_get_herb_name_from_enum( parent.spot_type ) )
		{
			parent.remove_farming_spot();
		}
		parent.GotoState('waiting');
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

class BT_Herb
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
class Botanist_RemoveAllMapPins extends SU_PredicateInterfaceRemovePin 
{
	function predicate(pin: SU_MapPin): bool {
		return StrStartsWith(pin.tag, "Botanist_");
	}
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
	
	var excluded_herbs : array<int>;
	
	var predicate: Botanist_RemoveAllMapPins;

	//---------------------------------------------------
	//-- Entity Storage Functions -----------------------
	//---------------------------------------------------
	
	function inititalise(master: Botanist) : void
	{	
		this.master = master;	
		this.attach_herb_pointers();
		
		this.initialise_storage_arrays();
		this.initialise_displayed_harvesting_grounds_arrays();

		predicate = new Botanist_RemoveAllMapPins in thePlayer;
		SU_removeCustomPinByPredicate(predicate);
		
		this.initialise_exclusion_list();
		this.initialise_temporary_displayed_arrays();
		this.initialise_saved_harvesting_grounds();
	}
	
	function initialise_exclusion_list() : void
	{
		this.excluded_herbs.Clear();
		
		// Keira's Hideout
		this.excluded_herbs.PushBack( 549522696 );
		this.excluded_herbs.PushBack( 1338875484 );
		this.excluded_herbs.PushBack( -1078211475 );
		this.excluded_herbs.PushBack( -541392408 );
		this.excluded_herbs.PushBack( -559926266 );
		this.excluded_herbs.PushBack( -2006234737 );
		this.excluded_herbs.PushBack( -1791854638 );
		this.excluded_herbs.PushBack( -484491973 );
		this.excluded_herbs.PushBack( 400975944 );
		this.excluded_herbs.PushBack( -1606184739 );
		this.excluded_herbs.PushBack( 963451185 );
		this.excluded_herbs.PushBack( 1270212183 );
	}
	
	function reset_ui() : void
	{
		var output: array<SU_Oneliner>;
		
		master.BT_RenderingLoop.GotoState('disabled');
		
		master.BT_PersistentStorage.BT_EventHandler.clear_all_registered_events();
		
		botanist_displayed_herbs.Clear();
		botanist_displayed_herbs_guid_hashes.Clear();
		
		botanist_displayed_harvesting_grounds.Clear();
		botanist_displayed_harvesting_grounds_guid_hashes.Clear();

		predicate = new Botanist_RemoveAllMapPins in thePlayer;
		SU_removeCustomPinByPredicate(predicate);

		output = SUOL_getManager().deleteByTagPrefix("Botanist_");
		GetWitcherPlayer().DisplayHudMessage("removed " + output.Size() + " Botanist Markers");
		
		master.BT_RenderingLoop.GotoState('on_tick');
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
	
	function is_herb_excluded(hash : int) : bool
	{
		return excluded_herbs.Contains(hash);
	}
	
	//---------------------------------------------------
	//-- Array Initialisation Functions -----------------
	//---------------------------------------------------

	function initialise_saved_harvesting_grounds() : void
	{
		var Idx, Edx : int;
		var region   : BT_Herb_Region = botanist_get_herb_enum_region();
		
		for (Idx = 0; Idx < this.botanist_displayed_harvesting_grounds[region].Size(); Idx += 1) 
		{
			for (Edx = 0; Edx < this.botanist_displayed_harvesting_grounds[region][Idx].Size(); Edx += 1) 
			{			
				this.botanist_displayed_harvesting_grounds[region][Idx][Edx].load();
			}
		}
	}
	
	//---------------------------------------------------
	
	function initialise_storage_arrays() : void
	{
		var Idx : int;

		if ( this.botanist_known_herbs_initialised )
		{
			expand_storage_arrays();
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
	
	function expand_storage_arrays() : void
	{
		var accurate_array_size: int = EnumGetMax('BT_Herb_Enum')+1;
		var Idx, Edx : int;
		
		for (Idx = 0; Idx < this.botanist_known_herbs.Size(); Idx += 1) 
		{
			Edx = 0;
			if ( this.botanist_known_herbs[Idx].Size() < accurate_array_size ) 
			{
				while ( this.botanist_known_herbs[Idx].Size() < accurate_array_size ) 
				{
					this.botanist_known_herbs[Idx].PushBack( this.get_blank_herb_array() );
					Edx += 1;
				}
			}
		}
	}
	
	//---------------------------------------------------
	
	function initialise_displayed_harvesting_grounds_arrays() : void
	{
		var Idx : int;
		
		if ( this.botanist_displayed_harvesting_grounds_initialised )
		{
			expand_displayed_harvesting_grounds_arrays();
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
	
	function expand_displayed_harvesting_grounds_arrays() : void
	{
		var accurate_array_size: int = EnumGetMax('BT_Herb_Enum')+1;
		var Idx, Edx : int;
		
		for (Idx = 0; Idx < this.botanist_displayed_harvesting_grounds.Size(); Idx += 1) 
		{
			Edx = 0;
			if ( this.botanist_displayed_harvesting_grounds[Idx].Size() < accurate_array_size ) 
			{
				while ( this.botanist_displayed_harvesting_grounds[Idx].Size() < accurate_array_size ) 
				{
					this.botanist_displayed_harvesting_grounds[Idx].PushBack( this.get_blank_farming_herb_array() );
					Edx += 1;
				}
			}
		}
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
	
	function get_harvestable_plants_in_region_count(herb_name : name) : int
	{
		var region 		: BT_Herb_Region = botanist_get_herb_enum_region();
		var type   		: BT_Herb_Enum = botanist_get_herb_enum_from_name(herb_name);
		var Idx, Rdx	: int;
		
		for( Idx = 0; Idx < this.botanist_known_herbs[region][type].Size(); Idx += 1 )
		{
			if ( this.botanist_known_herbs[region][type][Idx].is_eligible_for_normal_display() )
			{
				Rdx += 1;
			}
		}
		
		return Rdx;
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
				if (  botanist_master_herbs[Edx].reset_entity( vspawned_herbs[Idx], this.master ) )
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
	
	function list_known_herbs() : void
	{
		var Idx : int;
		
		BT_Logger("Processing Known Herbs List With A Size Of: " + get_known_herbs_count());
		for( Idx = 0; Idx < botanist_master_herbs.Size(); Idx += 1 )
		{
			botanist_master_herbs[Idx].print_info();
		}	
	}
}
class Botanist_TutorialsSystem 
{
	var master : Botanist;
	
	//---------------------------------------------------
	
	function initialise(master : Botanist)
	{
		this.master = master;
	}
	
	//---------------------------------------------------
	
	function show_tutorial(tutorial_identifier : Botanist_Tutorial_Enum, optional object : Vector) 
	{
		var data          : W3TutorialPopupData;
		var tutorial_data : Botanist_Tutorial_Data;
		
		if ( !get_tutorial_data( tutorial_identifier, tutorial_data ) )
		{
			return;
		}
		
		data                     = new W3TutorialPopupData in thePlayer;
		data.managerRef          = theGame.GetTutorialSystem();
		
		data.messageTitle        = tutorial_data.title;
		data.messageText         = tutorial_data.body;
		
		data.enableGlossoryLink  = false;
		data.autosize            = true;
		data.blockInput          = true;
		data.pauseGame           = true;
		data.fullscreen          = true;
		data.canBeShownInMenus   = true;
		data.enableAcceptButton  = true;
		data.fullscreen          = true;	

		
		data.duration = -1;
		data.posX = 0;
		data.posY = 0;

		theGame.GetInGameConfigWrapper().SetVarValue('Botanist_Tutorials', tutorial_data.variable, "false");
		theGame.GetTutorialSystem().ShowTutorialHint(data);
	}
	
	//---------------------------------------------------
	
	function get_tutorial_data(tutorial_identifier : Botanist_Tutorial_Enum, out output : Botanist_Tutorial_Data) : bool
	{
		var config : Botanist_Config = thePlayer.GetBotanistConfig();
		
		if ( !config.tutorial_settings.bools[tutorial_identifier] )
		{	
			return false;
		}
		
		switch( tutorial_identifier )
		{
			case Botanist_Tutorial_Installation : { 
				output.title = GetLocStringByKeyExt("BT_Tutorial_Installation_T"); 
				output.body = GetLocStringByKeyExt("BT_Tutorial_Installation_B"); 
				break; 
			}
			
			case Botanist_Tutorial_Discovery : { 
				output.title = GetLocStringByKeyExt("BT_Tutorial_Discovery_T"); 
				output.body = GetLocStringByKeyExt("BT_Tutorial_Discovery_B"); 
				break; 
			}

			case Botanist_Tutorial_HarvestingGrounds : { 
				output.title = GetLocStringByKeyExt("BT_Tutorial_HarvestingGounds_T"); 
				output.body = GetLocStringByKeyExt("BT_Tutorial_HarvestingGounds_B"); 
				break; 
			}			

			default : 
				break;
		}
		
		output.variable = config.get_config_tutorial_name( tutorial_identifier );
		return true;
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
	public var storage        : Botanist_KnownEntityStorage;
	
	public function create_and_set_variables(data : Botanist_DataTransferStruct) : Botanist_UIDisplayCreator
	{
		this.region        = data.region;
		this.type          = data.type;
		this.quantity      = data.quantity;
		this.user_settings = data.user_settings;
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
		this.Processing();
	}

	//---------------------------------------------------

	entry function Processing()
	{
		var node 		 : CNode;
		var Idx, Edx	 : int;
		var known_nodes  : array<CNode>;
		var known_herbs	 : array<BT_Herb> = parent.storage.botanist_known_herbs[parent.region][parent.type];

		if ( parent.storage.get_currently_displayed_count(parent.region, parent.type) >= parent.quantity )
		{
			return;
		}
		
		for( Idx = 0; Idx < known_herbs.Size(); Idx += 1 )
		{
			if ( known_herbs[Idx].is_eligible_for_normal_display() )
			{
				known_nodes.PushBack( (CNode)known_herbs[Idx].herb_entity );
			}
		}
		
		SortNodesByDistance(thePlayer.GetWorldPosition(), known_nodes);
		for( Idx = 0; Idx < Min(known_nodes.Size(), parent.quantity); Idx += 1 )
		{
			for ( Edx = 0; Edx < known_herbs.Size(); Edx += 1 )
			{
				if (known_nodes[Idx].GetWorldPosition() == known_herbs[Edx].herb_entity.GetWorldPosition())
				{
					known_herbs[Edx].set_displayed();
				}
			}
		}
		
		if ( parent.user_settings.bools[BT_Config_Hgr_Enabled] )
		{
			this.check_for_eligible_grounds(parent.region, parent.type, parent.user_settings);
		}
		
		parent.GotoState('idle');
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
			hg_result_01 = this.findHarvestingGround(user_settings, hg_all_nodes);
			this.create_harvesting_grounds(region, type, user_settings, hg_result_01);
			
			if ( hg_displayed < hg_maxground && hg_maxground > 1 )
			{
				hg_result_02 = this.findHarvestingGround(user_settings, hg_result_01.filtered_nodes);
				this.create_harvesting_grounds(region, type, user_settings, hg_result_02);			
			}
			
			if ( hg_displayed < hg_maxground && hg_maxground > 2 )
			{
				hg_result_03 = this.findHarvestingGround(user_settings, hg_result_02.filtered_nodes);
				this.create_harvesting_grounds(region, type, user_settings, hg_result_03);			
			}
		}
	}
	
	//---------------------------------------------------
	
	private function findHarvestingGround(user_settings : Botanist_UserSettings, node_pairings: array<Botanist_NodePairing>) : Botanist_HarvestGroundResults
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
				output.harvesting_nodes.PushBack( Botanist_NodePairing(node_pairings[Idx].node, node_pairings[Idx].herb) );
			}
			else
			{
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
	public var storage : Botanist_KnownEntityStorage;
	
	//---------------------------------------------------

	public function initialise(master: Botanist)
	{
		this.master  = master;
		this.storage = master.BT_PersistentStorage.BT_HerbStorage;
		this.GotoState('on_tick');
	}
}

//---------------------------------------------------
//-- States -----------------------------------------
//---------------------------------------------------

state disabled in Botanist_UIRenderLoop 
{	
	event OnEnterState(previous_state_name: name) 
	{
		super.OnEnterState(previous_state_name);		
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
		
		var Idx              : int;
		var stt              : float;
		
		var target_herb		 : name;
		
		var changed_req, changed_set : bool;
		
		while(true)
		{
			stt = theGame.GetLocalTimeAsMilliseconds();
			current_region = botanist_get_herb_enum_region();

			//Generate a list of user settings.
			new_usersettings = BT_GetUserSettings(BT_Config_User);
			new_herb_requirements = get_herb_requirements(current_region, new_usersettings);
			//SleepOneFrame();
			
			//BT_Logger("UI Update Loop took: " + (theGame.GetLocalTimeAsMilliseconds() - stt) + " milliseconds to generate lists");
			
			//Obtain the base item name of the targetted herb if selected in the mod menu.
			target_herb = BT_GetOverrideItemName( new_usersettings.ints[BT_Config_Mod_Targets] );
			
			//Check for any changes to the required amount of herbs since the last iteration.
			changed_req = requirements_have_changed(old_herb_requirements, new_herb_requirements, target_herb);
			//SleepOneFrame();
			//BT_Logger("UI Update Loop took: " + (theGame.GetLocalTimeAsMilliseconds() - stt) + " milliseconds to check requirements");
			
			//Check for any changes the user has made to the mods settings since the last iteration.
			changed_set = settings_have_changed(old_usersettings, new_usersettings);
			//SleepOneFrame();
			//BT_Logger("UI Update Loop took: " + (theGame.GetLocalTimeAsMilliseconds() - stt) + " milliseconds to check settings");
			
			//If the user has changed any mod settings then update the existing harvesting grounds as the 3D markers are no longer held in temp display storage.
			if ( changed_set )
			{
				this.update_harvesting_grounds_with_new_settings();
				//SleepOneFrame();
				//BT_Logger("UI Update Loop took: " + (theGame.GetLocalTimeAsMilliseconds() - stt) + " milliseconds to updated harvesting grounds");
			}			

			//If any changes are detected in the required ingredients or if the user has changed any mod settings then update the UI.
			if ( changed_req || changed_set )
			{
				//Clear all existing UI data such as map pins and 3D Markers.
				this.clear_existing_ui_data();
				SleepOneFrame();
				//BT_Logger("UI Update Loop took: " + (theGame.GetLocalTimeAsMilliseconds() - stt) + " milliseconds to clear existing UI data");
				
				//If the player is only wanting to display a specific herb and that herb is required for a recipe then only process that one list.
				if ( target_herb != '' )
				{
					//if we are targetting a specific herb, remove all harvesting grounds not of this type.
					this.remove_all_harvesting_grounds_except( target_herb );
					SleepOneFrame();
					
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
			
			BT_Logger("UI Update Loop took: " + (theGame.GetLocalTimeAsMilliseconds() - stt) + " milliseconds to run");
			Sleep(2);
		}
	}

	//---------------------------------------------------
	
	private function get_herb_requirements(current_region: BT_Herb_Region, new_usersettings: Botanist_UserSettings) : Botanist_HerbRequirements
	{	
		var output_data : Botanist_HerbRequirements;
		var output_name : name;
		var Idx, Edx, Rdx : int;

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
			//get the amount of this herb in the players inventory.
			Edx = thePlayer.inv.GetItemQuantityByName(output_data.names[Idx]);
			Rdx = parent.storage.get_currently_displayed_count( botanist_get_herb_enum_region(), botanist_get_herb_enum_from_name( output_data.names[Idx] ) );

			//Lower the quantity of the herbs needed for recipes by the amount the player already has in their inventory.
			output_data.quantities[Idx] -= (Edx + Rdx);

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
	
	private function clear_existing_ui_data() : void
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
	
	private function update_harvesting_grounds_with_new_settings() : void
	{
		parent.master.BT_PersistentStorage.BT_EventHandler.send_event( botanist_event_data( BT_HarvestingGrounds_Update ) );		
	}
	
	//---------------------------------------------------

    private function requirements_have_changed(old_data: Botanist_HerbRequirements, new_data : Botanist_HerbRequirements, target_herb : name) : bool
    {
        var Idx, Edx, Rdx, Sdx : int;
		
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
            //Get array position of current herb in the data from the last iteration.
            Sdx = old_data.names.FindFirst( new_data.names[Idx] );
			
            //Check if the current herb is missing or unalligned.
            if (Sdx != Idx) 
            {
                return true;
            }
            
            //Get Required Herb Quantity.
            Rdx = new_data.quantities[Idx];
			
			//Check if required quantity is greater than 0.
			//Check that there are harvestable plants left in the region that are not currently displayed.
			//Check that the quantity required does not match the old required quantity.
            if ( (Rdx > 0 && parent.storage.has_harvestable_plants_in_region(new_data.names[Idx])) || Rdx != old_data.quantities[Sdx] )
            {
                return true;
            }
        }
        return false;
    }
	
	//---------------------------------------------------

	private function settings_have_changed(old_data, new_data : Botanist_UserSettings) : bool
	{
		var Idx : int;
		
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
}//---------------------------------------------------
//-- Botanist User Settings Enums -------------------
//---------------------------------------------------

enum Botanist_UserSettings_Type
{
	BT_Config_User = 0,
	BT_Config_Discovery = 1,
	BT_Config_Tutorial = 2,
}

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
	BT_Config_Ols_Visible 	= 2,
	BT_Config_Ols_Fontsize 	= 3,
	BT_Config_Pin_Radius 	= 4,
	BT_Config_Hgr_Radius    = 5,
	BT_Config_Hgr_MinReq    = 6,
	BT_Config_Hgr_MaxAll    = 7,
	BT_Config_Hgr_MaxGrd    = 8,
	BT_Config_Mod_Quantity  = 9,
}

enum Botanist_UserSettings_Discovery
{
	BT_Config_Disc_Method = 0,
	BT_Config_Disc_Range = 1,
}

//---------------------------------------------------
//-- Botanist Tutorials Enum ------------------------
//---------------------------------------------------

enum Botanist_Tutorial_Enum
{
	Botanist_Tutorial_Installation = 0,
	Botanist_Tutorial_Discovery = 1,
	Botanist_Tutorial_HarvestingGrounds = 2,
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
	
	//Glassfish Herbs - https://www.nexusmods.com/witcher3/mods/8258
	BT_Belladonna           = 35,
	BT_Burmarigold          = 36,
	BT_Chamomile           	= 37,
	BT_Hemlock           	= 38,
	BT_Scleroderm           = 39,
	BT_Aloeleaves           = 40,
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
	BT_Herb_Reset = 1,
	BT_Herb_Clear_Except = 2,
	BT_HarvestingGrounds_Update = 3,
}
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