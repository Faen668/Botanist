//---------------------------------------------------
//-- Botanist Main Class ----------------------------
//---------------------------------------------------

statemachine class Botanist extends SU_BaseBootstrappedMod 
{
	public saved var BT_PersistentStorage 	: Botanist_Storage;
	public var BT_ConfigSettings			: Botanist_Config;
	public var BT_RenderingLoop				: Botanist_UIRenderLoop;
	
	default tag 							= 'Botanist_BootStrapper';

	//-----------------------------------------------
	
	public function start() : void
	{					
		this.BT_ConfigSettings = new Botanist_Config in this;
		this.BT_RenderingLoop  = new Botanist_UIRenderLoop in this;

		this.GotoState('Initialising');
	}
	
	//-----------------------------------------------
	
	public function SetEntityKnown(potential_herb: W3RefillableContainer) : void
	{	
		var herb_entity		: W3Herb;
		var herb_tag		: name;
		var herb_guid		: int;
		var created_herb  	: BT_Herb;
		
		herb_entity = (W3Herb)potential_herb;
		herb_guid = herb_entity.GetGuidHash();
		herb_tag  = herb_entity.get_herb_name();
		
		if ( herb_entity && !this.BT_PersistentStorage.BT_HerbStorage.is_herb_excluded(herb_guid) && BT_IsValidHerb(herb_tag) && !this.BT_PersistentStorage.BT_HerbStorage.botanist_known_herbs_guid_hashes.Contains(herb_guid) )
		{
			created_herb = (new BT_Herb in this).create_new_herb(herb_entity, herb_entity.GetWorldPosition(), herb_tag, herb_guid, theGame.GetCommonMapManager().GetCurrentArea(), this);
		}
	}

	//-----------------------------------------------
	
	public function SetEntityLooted(potential_herb: W3RefillableContainer) : void
	{	
		BT_PersistentStorage.BT_EventHandler.send_event( botanist_event_data( BT_Herb_Looted, potential_herb.GetGuidHash() ) );
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
	}
}

//---------------------------------------------------
//-- Botanist Main Class - (Initialising State) -----
//---------------------------------------------------

state Initialising in Botanist 
{
	private var curVersionStr: string;
		default curVersionStr = "1.0.2";
		
	private var curVersionInt: int;
		default curVersionInt = 102;
	
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

		while (theGame.IsLoadingScreenVideoPlaying()) 
		{
		  Sleep(1);
		}
		
		BT_LoadStorageCollection(parent);
		
		this.SetModVersion();
		
		parent.BT_ConfigSettings 	.initialise(parent);
		parent.BT_RenderingLoop		.initialise(parent);
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
		var Idx, Edx, Rdx, Pdx, Sdx, Ldx, Qdx : int;
		
		if (FactsQuerySum(VersStr) < curVersionInt) 
		{
			//-----------------------------------------------
			
			if (FactsQuerySum(VersStr) < 101) { FactsSet(VersStr, 101); hasUpdated = true; }
			
			//-----------------------------------------------
			
			if (FactsQuerySum(VersStr) < 102) 
			{ 
				FactsSet(VersStr, 102);

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
				hasUpdated = true;
			}
		}
	}
}
