
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
