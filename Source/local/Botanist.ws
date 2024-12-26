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
