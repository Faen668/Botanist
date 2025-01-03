
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