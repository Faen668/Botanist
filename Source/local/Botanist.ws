//---------------------------------------------------
//-- Botanist Main Class ----------------------------
//---------------------------------------------------

statemachine class Botanist extends SU_BaseBootstrappedMod 
{
	public saved var BT_PersistentStorage 	: Botanist_Storage;
	public var BT_ConfigSettings			: Botanist_Config;
	public var BT_RenderingLoop				: Botanist_UIRenderLoop;
	public var BT_AlchemyManager			: Botanist_AlchemyManager;
	default tag 							= 'Botanist_BootStrapper';

	//-----------------------------------------------
	
	public function start() : void
	{					
		this.BT_ConfigSettings = new Botanist_Config in this;
		this.BT_RenderingLoop  = new Botanist_UIRenderLoop in this;
		this.BT_AlchemyManager = new Botanist_AlchemyManager in this;
		
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
		herb_entity.GetStaticMapPinTag(herb_tag);
		
		if ( herb_entity && BT_IsValidHerb(herb_tag) && !this.BT_PersistentStorage.BT_HerbStorage.botanist_known_herbs_guid_hashes.Contains(herb_guid) )
		{
			created_herb = (new BT_Herb in this).create_new_herb(herb_entity, herb_entity.GetWorldPosition(), herb_tag, herb_guid, theGame.GetCommonMapManager().GetCurrentArea(), this);
		}
	}

	//-----------------------------------------------
	
	public function SetEntityLooted(potential_herb: W3RefillableContainer) : void
	{	
		var herb_entity    : W3Herb;
		var hash, Idx      : int;

		herb_entity = (W3Herb)potential_herb;
		hash = herb_entity.GetGuidHash();
		
		if ( herb_entity && this.BT_PersistentStorage.BT_HerbStorage.botanist_known_herbs_guid_hashes.Contains(hash) )
		{
			Idx = this.BT_PersistentStorage.BT_HerbStorage.botanist_master_hashs.FindFirst(hash);
			if ( Idx != -1 )
			{
				this.BT_PersistentStorage.BT_HerbStorage.botanist_master_herbs[Idx].set_herb_looted();
			}
		}
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
		BT_Logger("Main Class Entered state [Idle]");
		
		//this.test_entities();
	}
	
	//-----------------------------------------------
	
	entry function test_entities() : void // Only For Testing
	{
		var ents : array<CGameplayEntity>;
		var Idx : int;
		
		FindGameplayEntitiesCloseToPoint(ents, GetWitcherPlayer().GetWorldPosition(), 100000000, 100000000, , , ,'W3Container');
		
		for( Idx = 0; Idx < ents.Size(); Idx += 1 )
		{
			parent.SetEntityKnown( (W3Herb)ents[Idx] );
		}
		GetWitcherPlayer().DisplayHudMessage(ents.Size());
	}
}

//---------------------------------------------------
//-- Botanist Main Class - (Initialising State) -----
//---------------------------------------------------

state Initialising in Botanist 
{
	private var curVersionStr: string;
		default curVersionStr = "1.0.0";
		
	private var curVersionInt: int;
		default curVersionInt = 100;
	
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
		BT_Logger("Main Class Entered state [Initialising]");
		
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
		
		this.SetModVersion();
		BT_Logger("1");
		BT_LoadStorageCollection(parent);
		BT_Logger("2");
		
		parent.BT_AlchemyManager	.initialise(parent);
		BT_Logger("3");
		parent.BT_ConfigSettings 	.initialise(parent);
		BT_Logger("4");
		parent.BT_RenderingLoop		.initialise(parent);
		BT_Logger("5");
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
			if (FactsQuerySum(VersStr) < 100) { FactsSet(VersStr, 100); hasUpdated = true; }
		}
	}
}
