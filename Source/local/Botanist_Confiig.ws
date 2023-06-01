
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
		 case 9: return 'Botanist_Mod_Quantity';
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
		output_data.ints.PushBack(StringToInt(config_wrapper.GetVarValue('Botanist_GeneralSettings', 'Botanist_Mod_Quantity')));
		
		return output_data;
	}
}
