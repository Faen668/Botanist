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
//---------------------------------------------------
//-- Bootstrapper Class -----------------------------
//---------------------------------------------------

state CHerbScanner_BootStrapper in SU_TinyBootstrapperManager extends BaseMod 
{
	public function getTag(): name 
	{
		return 'CHerbScanner_BootStrapper';
	}
	
	public function getMod(): SU_BaseBootstrappedMod 
	{
		return new CHerbScanner in parent;
	}
}//---------------------------------------------------
//-- Entity Class -----------------------------------
//---------------------------------------------------

class HSC_Preview_Data 
{
	var radius			: int;
	var filename		: name;
	var uuid			: string;
	var label			: string;
	var description		: string;
	var position		: Vector;
	var region			: string;
	var container		: W3Herb;
	
	var minimap			: bool;
	var pointer			: bool;
	var highlight		: bool;
	
	default filename = 'HSC Entity';
	
	function create() : HSC_Preview_Data 
	{
		return this;
	}
	
	function setUUID(value: string) : HSC_Preview_Data 
	{
		this.uuid = value;
		return this;
	}

	function setPosition(value: Vector) : HSC_Preview_Data 
	{
		this.position = value;
		return this;
	}

	function setLabel(value: string) : HSC_Preview_Data 
	{
		this.label = value;
		return this;
	}	
	
	function setDescription(recipe: string, optional override: bool) : HSC_Preview_Data 
	{
		if (override)
		{
			this.description = "A common herb used in Alchemy for various recipes";
			return this;
		}
		
		this.description = "A common alchemy ingredient used to create <font color='#D7D23A'>" + recipe + "</font> recipe";
		return this;
	}	

	function setRegion(value: string) : HSC_Preview_Data 
	{
		this.region = value;
		return this;
	}	

	function setContainer(value: W3Herb) : HSC_Preview_Data 
	{
		this.container = value;
		return this;
	}	

	function setRadius(value: int) : HSC_Preview_Data 
	{
		this.radius = value;
		return this;
	}

	function setMinimap(value: bool) : HSC_Preview_Data 
	{
		this.minimap = value;
		return this;
	}

	function setPointer(value: bool) : HSC_Preview_Data 
	{
		this.pointer = value;
		return this;
	}

	function setHighlight(value: bool) : HSC_Preview_Data 
	{
		this.highlight = value;
		return this;
	}
	
	function DisplayPin(manager: CHerbScanner_MapPins) : HSC_Preview_Data 
	{
		manager.RefreshPin(this);
		
		HSC_Logger("Entity created with map pin: " + this.uuid + " " + this.description + " " + this.region, , this.filename);
		return this;
	}		
}
//---------------------------------------------------
//-- Functions --------------------------------------
//---------------------------------------------------

function Get_HerbScanner(out master: CHerbScanner, optional caller: string): bool 
{
	HSC_Logger("Get_HerbScanner Called by [" + caller + "]");
	master = (CHerbScanner)SUTB_getModByTag('CHerbScanner_BootStrapper');
	
	if (master)
	{
		return true;
	}
	return false;
}

//---------------------------------------------------
//-- Functions --------------------------------------
//---------------------------------------------------

function HSC_Logger(message: string, optional ShowInGUI: bool, optional filename: name) 
{	
	if (filename == '') 
	{
		filename = 'HSC';
	}
	
	LogChannel(filename, message);
  
	if (ShowInGUI)
	{
		GetWitcherPlayer().DisplayHudMessage(NameToString(filename) + ": " + message);
	}
}

//---------------------------------------------------
//-- Settings Access Functions ----------------------
//---------------------------------------------------

function HSC_GetSetting(variable: name) : string
{
	return theGame.GetInGameConfigWrapper().GetVarValue('HerbScanner_GeneralSettings', variable);
}

//---------------------------------------------------
//-- Settings Access Functions ----------------------
//---------------------------------------------------

function HSC_IsValidHerb(itemName : name) : bool
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
	case 'Buckthorn':
		return true;
	
	default: 
		return false;
	}
}

function HSC_GetOverrideItemName(value: float) : name
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
	default: return '';
	}
}        

//---------------------------------------------------
//-- Functions --------------------------------------
//---------------------------------------------------

exec function findherbs(optional ftag: name) 
{
	var ents: array<CGameplayEntity>;
	var herb: W3Herb;
	var tag: name;
	var i: int;
	
	FindGameplayEntitiesInRange(ents, thePlayer, 999999999, 999999999, );

	for( i = 0; i < ents.Size(); i += 1 )
	{
		if( ents.Size() > 0 )
		{
			herb = (W3Herb)(W3Container)ents[i];
			
			if (herb) {
				herb.GetStaticMapPinTag(tag);
				if (tag != '') {
					LogChannel('Herb', "Found Herb: " + GetLocStringByKeyExt( theGame.GetDefinitionsManager().GetItemLocalisationKeyName( tag ) ) + " with tag: " + NameToString(tag) );
				}
			}
		}
	}
}

//---------------------------------------------------
//-- Functions --------------------------------------
//---------------------------------------------------

exec function logherbs() 
{
	var ents: array<CGameplayEntity>;
	var ents2: array<name>;
	var ents3: array<W3Herb>;

	var herb: W3Herb;
	var tag: name;
	var pos: Vector;
	var i: int;
	
	ents.Clear();
	ents2.Clear();
	ents3.Clear();
	
	FindGameplayEntitiesInRange(ents, thePlayer, 100000, 999);

	for( i = 0; i < ents.Size(); i += 1 )
	{
		if( ents.Size() > 0 )
		{
			herb = (W3Herb)(W3Container)ents[i];
			
			if (herb) {
				herb.GetStaticMapPinTag(tag);
				if (tag != '' && !ents2.Contains(tag)) {
					ents2.PushBack(tag);
					ents3.PushBack(herb);
				}
			}
		}
	}

	for( i = 0; i < ents2.Size(); i += 1 )
	{
		pos = ents3[i].GetWorldPosition();
		LogChannel('Herb', "Found Herb: " + GetLocStringByKeyExt( theGame.GetDefinitionsManager().GetItemLocalisationKeyName( ents2[i] ) ) + " with tag: " + NameToString(ents2[i]) + " at position: " + pos.X + " " + pos.Y + " " + pos.Z + " " + pos.W);
	}
}

//---------------------------------------------------
//-- Functions --------------------------------------
//---------------------------------------------------

exec function hsc_herbnames() 
{
	LogChannel('HSC', GetLocStringByKeyExt(theGame.GetDefinitionsManager().GetItemLocalisationKeyName('Allspice root')));
	LogChannel('HSC', GetLocStringByKeyExt(theGame.GetDefinitionsManager().GetItemLocalisationKeyName('Arenaria')));
	LogChannel('HSC', GetLocStringByKeyExt(theGame.GetDefinitionsManager().GetItemLocalisationKeyName('Balisse fruit')));
	LogChannel('HSC', GetLocStringByKeyExt(theGame.GetDefinitionsManager().GetItemLocalisationKeyName('Beggartick blossoms')));
	LogChannel('HSC', GetLocStringByKeyExt(theGame.GetDefinitionsManager().GetItemLocalisationKeyName('Berbercane fruit')));
	LogChannel('HSC', GetLocStringByKeyExt(theGame.GetDefinitionsManager().GetItemLocalisationKeyName('Bloodmoss')));
	LogChannel('HSC', GetLocStringByKeyExt(theGame.GetDefinitionsManager().GetItemLocalisationKeyName('Blowbill')));
	LogChannel('HSC', GetLocStringByKeyExt(theGame.GetDefinitionsManager().GetItemLocalisationKeyName('Bryonia')));
	LogChannel('HSC', GetLocStringByKeyExt(theGame.GetDefinitionsManager().GetItemLocalisationKeyName('Buckthorn')));
	LogChannel('HSC', GetLocStringByKeyExt(theGame.GetDefinitionsManager().GetItemLocalisationKeyName('Celandine')));
	LogChannel('HSC', GetLocStringByKeyExt(theGame.GetDefinitionsManager().GetItemLocalisationKeyName('Cortinarius')));
	LogChannel('HSC', GetLocStringByKeyExt(theGame.GetDefinitionsManager().GetItemLocalisationKeyName('Crows eye')));
	LogChannel('HSC', GetLocStringByKeyExt(theGame.GetDefinitionsManager().GetItemLocalisationKeyName('Ergot seeds')));
	LogChannel('HSC', GetLocStringByKeyExt(theGame.GetDefinitionsManager().GetItemLocalisationKeyName('Fools parsley leaves')));
	LogChannel('HSC', GetLocStringByKeyExt(theGame.GetDefinitionsManager().GetItemLocalisationKeyName('Ginatia petals')));
	LogChannel('HSC', GetLocStringByKeyExt(theGame.GetDefinitionsManager().GetItemLocalisationKeyName('Green mold')));
	LogChannel('HSC', GetLocStringByKeyExt(theGame.GetDefinitionsManager().GetItemLocalisationKeyName('Han')));
	LogChannel('HSC', GetLocStringByKeyExt(theGame.GetDefinitionsManager().GetItemLocalisationKeyName('Hellebore petals')));
	LogChannel('HSC', GetLocStringByKeyExt(theGame.GetDefinitionsManager().GetItemLocalisationKeyName('Honeysuckle')));
	LogChannel('HSC', GetLocStringByKeyExt(theGame.GetDefinitionsManager().GetItemLocalisationKeyName('Hop umbels')));
	LogChannel('HSC', GetLocStringByKeyExt(theGame.GetDefinitionsManager().GetItemLocalisationKeyName('Hornwort')));
	LogChannel('HSC', GetLocStringByKeyExt(theGame.GetDefinitionsManager().GetItemLocalisationKeyName('Longrube')));
	LogChannel('HSC', GetLocStringByKeyExt(theGame.GetDefinitionsManager().GetItemLocalisationKeyName('Mandrake root')));
	LogChannel('HSC', GetLocStringByKeyExt(theGame.GetDefinitionsManager().GetItemLocalisationKeyName('Mistletoe')));
	LogChannel('HSC', GetLocStringByKeyExt(theGame.GetDefinitionsManager().GetItemLocalisationKeyName('Moleyarrow')));
	LogChannel('HSC', GetLocStringByKeyExt(theGame.GetDefinitionsManager().GetItemLocalisationKeyName('Nostrix')));
	LogChannel('HSC', GetLocStringByKeyExt(theGame.GetDefinitionsManager().GetItemLocalisationKeyName('Pigskin puffball')));
	LogChannel('HSC', GetLocStringByKeyExt(theGame.GetDefinitionsManager().GetItemLocalisationKeyName('Pringrape')));
	LogChannel('HSC', GetLocStringByKeyExt(theGame.GetDefinitionsManager().GetItemLocalisationKeyName('Ranogrin')));
	LogChannel('HSC', GetLocStringByKeyExt(theGame.GetDefinitionsManager().GetItemLocalisationKeyName('Ribleaf')));
	LogChannel('HSC', GetLocStringByKeyExt(theGame.GetDefinitionsManager().GetItemLocalisationKeyName('Sewant mushrooms')));
	LogChannel('HSC', GetLocStringByKeyExt(theGame.GetDefinitionsManager().GetItemLocalisationKeyName('Verbena')));
	LogChannel('HSC', GetLocStringByKeyExt(theGame.GetDefinitionsManager().GetItemLocalisationKeyName('White myrtle')));
	LogChannel('HSC', GetLocStringByKeyExt(theGame.GetDefinitionsManager().GetItemLocalisationKeyName('Wolfsbane')));
}

//---------------------------------------------------
//-- Functions --------------------------------------
//---------------------------------------------------

exec function hsc_leanrherbs() 
{
	var master : CHerbScanner;

	if (!Get_HerbScanner(master, 'hsc_leanrherbs'))
	{
		return;
	}

	master.SetHerbKnown('Allspice root');
	master.SetHerbKnown('Arenaria');
	master.SetHerbKnown('Balisse fruit');
	master.SetHerbKnown('Beggartick blossoms');
	master.SetHerbKnown('Berbercane fruit');
	master.SetHerbKnown('Bloodmoss');
	master.SetHerbKnown('Blowbill');
	master.SetHerbKnown('Bryonia');
	master.SetHerbKnown('Buckthorn');
	master.SetHerbKnown('Celandine');
	master.SetHerbKnown('Cortinarius');
	master.SetHerbKnown('Crows eye');
	master.SetHerbKnown('Ergot seeds');
	master.SetHerbKnown('Fools parsley leaves');
	master.SetHerbKnown('Ginatia petals');
	master.SetHerbKnown('Green mold');
	master.SetHerbKnown('Han');
	master.SetHerbKnown('Hellebore petals');
	master.SetHerbKnown('Honeysuckle');
	master.SetHerbKnown('Hop umbels');
	master.SetHerbKnown('Hornwort');
	master.SetHerbKnown('Longrube');
	master.SetHerbKnown('Mandrake root');
	master.SetHerbKnown('Mistletoe');
	master.SetHerbKnown('Moleyarrow');
	master.SetHerbKnown('Nostrix');
	master.SetHerbKnown('Pigskin puffball');
	master.SetHerbKnown('Pringrape');
	master.SetHerbKnown('Ranogrin');
	master.SetHerbKnown('Ribleaf');
	master.SetHerbKnown('Sewant mushrooms');
	master.SetHerbKnown('Verbena');
	master.SetHerbKnown('White myrtle');
	master.SetHerbKnown('Wolfsbane');
}
//---------------------------------------------------
//-- Herb Monitor Class -----------------------------
//---------------------------------------------------

statemachine class CHerbScanner_KnownHerbsMonitor extends IInventoryScriptedListener
{
	public var filename: name; 
		default filename = 'HSC Herb Monitor';
	
	public var master: CHerbScanner;
	public var inventory: CInventoryComponent;
	
	//---------------------------------------------------

	public function initialise(master: CHerbScanner)
	{
		this.master = master;
		this.inventory = thePlayer.inv;
		
		inventory.AddListener(this);
	}

	//---------------------------------------------------
	
	event OnInventoryScriptedEvent( eventType : EInventoryEventType, itemId : SItemUniqueId, quantity : int, fromAssociatedInventory : bool ) 
	{
		HSC_Logger("Event Receieved", , this.filename);

		if (eventType == IET_ItemAdded) 
		{
			ProcessItem(itemId);
		}
	}
	
	//---------------------------------------------------
	
	private function ProcessItem(itemId: SItemUniqueId) : void
	{	
		var itemName: name = inventory.GetItemName(itemId);
		
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
			master.SetHerbKnown(itemName);
			break;
		
		default: 
			break;
		}
	}
}//---------------------------------------------------
//-- Class ------------------------------------------
//---------------------------------------------------		

statemachine class CHerbScanner_ContainerListener
{
	
	public var filename: name; 
		default filename = 'HSC Container Listener';
	
	public var master: CHerbScanner;
	
	//---------------------------------------------------

	public function initialise(master: CHerbScanner)
	{
		this.master = master;
	}
}

//---------------------------------------------------
//-- States -----------------------------------------
//---------------------------------------------------

state Disabled in CHerbScanner_ContainerListener 
{
	event OnEnterState(previous_state_name: name) 
	{
		super.OnEnterState(previous_state_name);
		HSC_Logger("Entered state [Disabled]", , parent.filename);
	}
}

//---------------------------------------------------
//-- States -----------------------------------------
//---------------------------------------------------

state Idle in CHerbScanner_ContainerListener 
{
	event OnEnterState(previous_state_name: name) 
	{
		super.OnEnterState(previous_state_name);
		HSC_Logger("Entered state [Idle]", , parent.filename);

		this.Idle_Main();
	}

//---------------------------------------------------

	entry function Idle_Main() { 
		
		Sleep(2);		
		parent.GotoState('Checking');
	}
}

//---------------------------------------------------
//-- States -----------------------------------------
//---------------------------------------------------

state Checking in CHerbScanner_ContainerListener 
{
	event OnEnterState(previous_state_name: name) 
	{
		super.OnEnterState(previous_state_name);
		HSC_Logger("Entered state [Checking]", , parent.filename);
		
		this.Checking_Main();
	}

//---------------------------------------------------

	entry function Checking_Main()
	{	
		var Idx: int;
		var tag: name;

		for( Idx = parent.master.current_pins.Size()-1; Idx >= 0; Idx -= 1 )
		{
			parent.master.current_pins[Idx].container.GetStaticMapPinTag( tag );

			if (tag == '')
			{
				SU_removeCustomPinByPosition(parent.master.current_pins[Idx].position);
				parent.master.current_pins.EraseFast(Idx);
			}
		}
		
		parent.GotoState('Idle');
	}
}

//---------------------------------------------------
//-- Pin Manager Class ------------------------------
//---------------------------------------------------

statemachine class CHerbScanner_MapPins extends SU_MapPin 
{
	public var filename: name;
		default filename = 'HSC Map Pin Manager';

	public var master: CHerbScanner;
	public var builder: SU_MapPinsBuilder;

	//---------------------------------------------------

	public function initialise(master: CHerbScanner)
	{
		this.master = master;
	}

	//---------------------------------------------------
	
	public function InitialiseBuilder() 
	{
		builder = new SU_MapPinsBuilder in thePlayer;
	}

	//---------------------------------------------------
	
	public function Build() 
	{
		builder.build();
	}
	
	//---------------------------------------------------
	
	public function RefreshPin(entry_data: HSC_Preview_Data)
	{		
		builder.tag_prefix("HSC_")
		.pin()
			.tag				(entry_data.uuid)
			.label				(entry_data.label)
			.description		(entry_data.description)
			.type				("Herb")
			.radius				(entry_data.radius)
			.position			(entry_data.position)
			.region 			(entry_data.region)
			.is_quest			(false)
			.appears_on_minimap	(entry_data.minimap)
			.pointed_by_arrow	(entry_data.pointer)
			.highlighted		(entry_data.highlight)
		.add();
		HSC_Logger("Herb Scanner: Added Map Pin: " + entry_data.uuid, , this.filename);
	}
}

//---------------------------------------------------
//-- Pin Predicate Class ----------------------------
//---------------------------------------------------

class CHerbScanner_RemoveAllMapPins extends SU_PredicateInterfaceRemovePin 
{
	function predicate(pin: SU_MapPin): bool {
		return StrStartsWith(pin.tag, "HSC_");
	}
}