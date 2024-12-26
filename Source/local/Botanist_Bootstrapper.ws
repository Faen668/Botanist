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


