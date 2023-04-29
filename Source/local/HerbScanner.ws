//---------------------------------------------------
//-- Base Mod Class ---------------------------------
//---------------------------------------------------

statemachine class CHerbScanner extends SU_BaseBootstrappedMod 
{
	public var filename: name;
	default filename = 'Herb Scanner';
		
	public var HSC_PinManager: CHerbScanner_MapPins;
	public var HSC_HrbMonitor: CHerbScanner_KnownHerbsMonitor;
	public var HSC_HrbListener: CHerbScanner_ContainerListener;
	
	public saved var current_pins: array<HSC_Preview_Data>;
	public saved var known_herbs: array<name>;

	public var LastUpdateTime: float;
	default LastUpdateTime = 0;
		
	default tag = 'CHerbScanner_BootStrapper';

	//---------------------------------------------------
	
	public function start() 
	{			
		HSC_Logger("Bootstrapped successfully with Magic, prayers and wishful thinking...", , this.filename);
		
		theInput.RegisterListener(this, 'ScanForHerbs', 'ScanForHerbs');
		theInput.RegisterListener(this, 'ClearHerbPins', 'ClearHerbPins');
		
		HSC_PinManager 		= new CHerbScanner_MapPins in this;
		HSC_HrbMonitor	 	= new CHerbScanner_KnownHerbsMonitor in this;
		HSC_HrbListener 	= new CHerbScanner_ContainerListener in this;
		
		this.GotoState('Initialising');
	}	

//---------------------------------------------------
	
	private function CreateEntry() : HSC_Preview_Data
	{
		return new HSC_Preview_Data in this; 
	}

//---------------------------------------------------
	
	public function ClearHerbPins(action : SInputAction) 
	{	
		var predicate: CHerbScanner_RemoveAllMapPins;
		
		predicate = new CHerbScanner_RemoveAllMapPins in thePlayer;
		SU_removeCustomPinByPredicate(predicate);	
	}
	
//---------------------------------------------------
	
	public function ScanForHerbs(action : SInputAction) 
	{ 
		var m_alchemyManager : W3AlchemyManager;
		var predicate: CHerbScanner_RemoveAllMapPins;
		var ents: array<CGameplayEntity>;
		var herbs: array<W3Herb>;
		var Entity: HSC_Preview_Data;
		var herb: W3Herb;
		var tag: name;
		var Idx, Edx: int;
		var m_recipeList 	: array<SAlchemyRecipe>;
		var m_partsList 	: array<SItemParts>;
		var m_namesList		: array<name>;
		var m_recipList		: array<string>;
		var m_quantList		: array<int>;
		var m_name			: name;
		var m_quan			: int;
		
		//Settings
		var m_enabled		: bool  = (bool)   HSC_GetSetting('HerbScanner_Mod_Enabled');
		var m_onlyneeded	: bool 	= (bool)   HSC_GetSetting('HerbScanner_DynamicMode_OnlyNeededQty');
		var m_override		: float = (float)  HSC_GetSetting('HerbScanner_DynamicMode_OverrideTarget');
		var m_minimap		: bool 	= (bool)   HSC_GetSetting('HerbScanner_DynamicMode_ShowMiniMap');
		var m_pointer		: bool 	= (bool)   HSC_GetSetting('HerbScanner_DynamicMode_ArrowPointers');
		var m_highlight		: bool 	= (bool)   HSC_GetSetting('HerbScanner_DynamicMode_Highlighted');	
		
		var m_searchradius	: float = (float)  HSC_GetSetting('HerbScanner_Global_SearchRadius');
		var m_maxresults	: int 	= (int)    HSC_GetSetting('HerbScanner_Global_MaximumResults');
		var m_pinsize		: int	= (int)	   HSC_GetSetting('HerbScanner_Global_MapPinSize');

		if (!m_enabled)
		{
			return;
		}
		
		if ((theGame.GetEngineTimeAsSeconds() - this.LastUpdateTime) > 5) 
		{
			this.LastUpdateTime = theGame.GetEngineTimeAsSeconds();
				
			// Remove all existing map pins.
			predicate = new CHerbScanner_RemoveAllMapPins in thePlayer;
			SU_removeCustomPinByPredicate(predicate);
			HSC_HrbListener.GotoState('Disabled');
			current_pins.Clear();
			
			// Return if the player has not yet discovered any herbs or has the option enabled to only display pins for known herbs.
			if (known_herbs.Size() == 0)
			{
				GetWitcherPlayer().DisplayHudMessage("Herb Scanner: No Herbs Known...");
				return;			

			}
			
			HSC_PinManager.InitialiseBuilder();
			
			//Find all gameplay entities within range.
			FindGameplayEntitiesCloseToPoint(ents, GetWitcherPlayer().GetWorldPosition(), m_searchradius, 99999, , , ,'W3Container');
			HSC_Logger("Got " + ents.Size() + " Gameplay entities...", , this.filename); 
			
			//Dynamic Mode Start
			if (m_override == 0)
			{
				// Initialise the map pin builder and Alchemy Manager.
				m_alchemyManager = new W3AlchemyManager in this;
				m_alchemyManager.Init();
				
				// Obtain a list of all player Recipes.
				m_recipeList = m_alchemyManager.GetRecipes(false);
				HSC_Logger("Got " + m_recipeList.Size() + " Alchemy Recipes...", , this.filename);
				
				// Traverse the recipe list looking for recipes with valid ingredients the player needs.
				for( Idx = 0; Idx < m_recipeList.Size(); Idx += 1 )
				{
					for( Edx = 0; Edx < m_recipeList[Idx].requiredIngredients.Size(); Edx += 1 )
					{
						m_name = m_recipeList[Idx].requiredIngredients[Edx].itemName;
						if ( known_herbs.Contains(m_name) && m_alchemyManager.CanCookRecipe(m_recipeList[Idx].recipeName) == EAE_NotEnoughIngredients && thePlayer.inv.GetItemQuantityByName(m_name) < m_recipeList[Idx].requiredIngredients[Edx].quantity )
						{
							m_quan = m_recipeList[Idx].requiredIngredients[Edx].quantity - thePlayer.inv.GetItemQuantityByName(m_name);
							
							if (m_namesList.Contains(m_name)) {
								m_quantList[m_namesList.FindFirst(m_name)] += m_quan;
								HSC_Logger("Need A Further " + m_quan + " " + m_name + " For Recipe - [" + m_recipeList[Idx].recipeName + "]", , this.filename);
							}
							else {
								m_namesList.PushBack(m_name);
								m_quantList.PushBack(m_quan);
								m_recipList.PushBack(GetLocStringByKeyExt(theGame.GetDefinitionsManager().GetItemLocalisationKeyName(m_recipeList[Idx].cookedItemName)));
								HSC_Logger("Need " + m_quan + " " + m_name + " For Recipe - [" + m_recipeList[Idx].recipeName + "]", , this.filename);
							}
						}
					}
				}

				//Traverse list for eligible herb containers.
				for( Idx = 0; Idx < ents.Size(); Idx += 1 )
				{
					herb = (W3Herb)(W3Container)ents[Idx];
					
					if (herb) 
					{
						herb.GetStaticMapPinTag(tag);

						if ( m_namesList.Contains(tag) && (m_quantList[m_namesList.FindFirst(tag)] > 0) )
						{
							if (current_pins.Size() < m_maxresults) 
							{
								current_pins.PushBack(CreateEntry()
									.setUUID("HSC_HerbPin_" + IntToString(Idx))
									.setPosition(ents[Idx].GetWorldPosition())
									.setRegion(SUH_getCurrentRegion())
									.setLabel(GetLocStringByKeyExt(theGame.GetDefinitionsManager().GetItemLocalisationKeyName(tag)))
									.setDescription(m_recipList[m_namesList.FindFirst(tag)])
									.setContainer(herb)
									.setRadius(m_pinsize)
									.setMinimap(m_minimap)
									.setPointer(m_pointer)
									.setHighlight(m_highlight)
									.DisplayPin(HSC_PinManager)
								);
								
								if (m_onlyneeded)
								{
									m_quantList[m_namesList.FindFirst(tag)] -= 1;
								}
							}
						}
					}			
				}

				if (current_pins.Size() > 0)
				{
					HSC_PinManager.Build();
					GetWitcherPlayer().DisplayHudMessage("Herb Scanner: Added Map Pins for " + current_pins.Size() + " Herbs.");
					HSC_HrbListener.GotoState('Checking');
					return;
				}
				
				GetWitcherPlayer().DisplayHudMessage("Herb Scanner: No herbs found within search parameters...");
			}
			else
			{
				m_name = HSC_GetOverrideItemName(m_override);
				if( m_name == '' )
				{
					return;
				}
				
				HSC_Logger("Request Override - " + NameToString(m_name), true, this.filename);

				//Traverse list for override herb containers.
				for( Idx = 0; Idx < ents.Size(); Idx += 1 )
				{
					herb = (W3Herb)(W3Container)ents[Idx];
					
					if (herb) 
					{
						herb.GetStaticMapPinTag(tag);

						if ( HSC_IsValidHerb(tag) && tag == m_name )
						{
							if (current_pins.Size() < m_maxresults) 
							{
								current_pins.PushBack(CreateEntry()
									.setUUID("HSC_HerbPin_" + IntToString(Idx))
									.setPosition(ents[Idx].GetWorldPosition())
									.setRegion(SUH_getCurrentRegion())
									.setLabel(GetLocStringByKeyExt(theGame.GetDefinitionsManager().GetItemLocalisationKeyName(tag)))
									.setDescription("", true)
									.setContainer(herb)
									.setRadius(m_pinsize)
									.setMinimap(false)
									.setPointer(false)
									.setHighlight(false)
									.DisplayPin(HSC_PinManager)
								);
							}
						}
					}			
				}
				
				if (current_pins.Size() > 0)
				{
					HSC_PinManager.Build();
					GetWitcherPlayer().DisplayHudMessage("Herb Scanner: Added Map Pins for " + current_pins.Size() + " Herbs.");
					HSC_HrbListener.GotoState('Checking');
					return;
				}
				
				GetWitcherPlayer().DisplayHudMessage("Herb Scanner: No herbs found within search parameters...");
				
			}
		}
	}

//---------------------------------------------------
	
	public function SetHerbKnown(herb: name) 
	{
		if (known_herbs.Contains(herb))
		{
			return;
		}
		
		known_herbs.PushBack(herb);
		HSC_Logger("Player Knows Herb: " + GetLocStringByKeyExt(theGame.GetDefinitionsManager().GetItemLocalisationKeyName(herb)), ,this.filename);
	}
}

//---------------------------------------------------
//-- Herb Scanner Idle State ------------------------
//---------------------------------------------------

state Idle in CHerbScanner 
{
	event OnEnterState(previous_state_name: name) 
	{
		super.OnEnterState(previous_state_name);
		HSC_Logger("Entered state [Idle]", , parent.filename);
	}
}

//---------------------------------------------------
//-- Herb Scanner Initialising State ----------------
//---------------------------------------------------

state Initialising in CHerbScanner 
{
	private var curVersionStr: string;
		default curVersionStr = "1.0.0";
		
	private var curVersionInt: int;
		default curVersionInt = 100;
	
	private var hasUpdated: bool;
		default hasUpdated = false;
	
	private var initStr: string;
		default initStr = "HSC_Initialised";
		
	private var VersStr: string;
		default VersStr = "HerbScanner_CurrentModVersion";

//---------------------------------------------------
		
	event OnEnterState(previous_state_name: name) 
	{
		super.OnEnterState(previous_state_name);
		HSC_Logger("Entered state [Initialising]", , parent.filename);
		
		this.Initialising_Main();
	}

//---------------------------------------------------
	
	entry function Initialising_Main() 
	{	
		var Idx: int;
	
		while (theGame.IsLoadingScreenVideoPlaying()) 
		{
		  Sleep(1);
		}
		
		HSC_Logger("Loading Screen Finished", , parent.filename);

		parent.HSC_PinManager	.initialise(parent);
		parent.HSC_HrbMonitor	.initialise(parent);
		parent.HSC_HrbListener	.initialise(parent);
	
		this.SetModVersion();
		
		if (parent.current_pins.Size() > 0)
		{
			parent.HSC_PinManager.InitialiseBuilder();
			
			HSC_Logger("Loading Stored Pins", true , parent.filename);
			
			for( Idx = 0; Idx < parent.current_pins.Size(); Idx += 1 )
			{
				parent.current_pins[Idx].DisplayPin(parent.HSC_PinManager);		
			}
			
			parent.HSC_PinManager.Build();
			
			parent.HSC_HrbListener.GotoState('Checking');
		}
		parent.GotoState('Idle');
	}
	
	//---------------------------------------------------

	latent function SetModVersion() 
	{		
		if (FactsQuerySum(initStr) != 1) 
		{
			FactsSet(initStr, 1);
			FactsSet(VersStr, curVersionInt);
			return;
		}

		this.UpdateMod();	
		
		if (hasUpdated) 
		{
			GetWitcherPlayer().DisplayHudMessage("Herb Scanner: Updated To Version " + curVersionStr);
		}
	}
	
	//---------------------------------------------------
	
	latent function UpdateMod() 
	{
		if (FactsQuerySum(VersStr) < curVersionInt) 
		{
			if (FactsQuerySum(VersStr) < 100) { FactsSet(VersStr, 100); hasUpdated = true; }
		}
	}
}
