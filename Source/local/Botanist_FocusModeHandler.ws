
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