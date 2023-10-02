
//---------------------------------------------------
//-- Functions --------------------------------------
//---------------------------------------------------

function Get_Botanist(out master: Botanist, optional caller: string): bool 
{
	if (BT_Mod_Not_Ready())
	{
		return false;
	}
	
	BT_Logger("Get_Botanist Called by [" + caller + "]");
	master = (Botanist)SUTB_getModByTag('Botanist_BootStrapper');
	
	if (master)
	{
		return true;
	}
	
	return false;
}

//---------------------------------------------------
//-- Functions --------------------------------------
//---------------------------------------------------

function BT_SetEntityKnown(ent: W3RefillableContainer) : void
{
	var master : Botanist;
	
	if (Get_Botanist(master, 'BT_SetEntityKnown'))
		master.SetEntityKnown(ent);
}
	
//---------------------------------------------------
//-- Functions --------------------------------------
//---------------------------------------------------

function BT_SetEntityLooted(ent: W3RefillableContainer) : void
{
	var master : Botanist;

	if (Get_Botanist(master, 'BT_SetEntityLooted'))
		master.SetEntityLooted(ent);
}

//---------------------------------------------------
//-- Functions --------------------------------------
//---------------------------------------------------

function BT_SetFocussing() : void
{
	var master : Botanist;

	if (Get_Botanist(master, 'BT_SetFocussing'))
		master.BT_FocusModeHander.start();
}

//---------------------------------------------------
//-- Functions --------------------------------------
//---------------------------------------------------

function BT_Logger(message: string, optional ShowInGUI: bool) : void
{	
	LogChannel('Botanist', message);
  
	if (ShowInGUI)
	{
		GetWitcherPlayer().DisplayHudMessage("Botanist: " + message);
	}
}

//---------------------------------------------------
//-- Functions --------------------------------------
//---------------------------------------------------

function BT_Mod_Not_Ready(): bool 
{
	return thePlayer.IsInNonGameplayCutscene()
		|| theGame.IsLoadingScreenVideoPlaying()
		|| thePlayer.IsInGameplayScene()
		|| thePlayer.IsCiri()
		|| theGame.IsDialogOrCutscenePlaying()
		|| theGame.IsCurrentlyPlayingNonGameplayScene()
		|| theGame.IsFading()
		|| theGame.IsBlackscreen()
		|| thePlayer.IsInFistFightMiniGame()
		|| !thePlayer.IsAlive();
}

//---------------------------------------------------
//-- Functions --------------------------------------
//---------------------------------------------------

function BT_VectorToString(vec : Vector): string 
{
	return vec.X + ", " + vec.Y + ", " + vec.Z + ", " + vec.W;
}

//---------------------------------------------------
//-- Enum Return Functions --------------------------
//---------------------------------------------------

function botanist_get_herb_enum_from_name(herb_tag : name) : BT_Herb_Enum
{
	switch(herb_tag)
	{
	case 'Allspice root':        { return BT_Allspiceroot; }
	case 'Arenaria':             { return BT_Arenaria; }
	case 'Balisse fruit':        { return BT_Balissefruit; }
	case 'Beggartick blossoms':  { return BT_Beggartickblossoms; }
	case 'Berbercane fruit':     { return BT_Berbercanefruit; }
	case 'Bloodmoss':            { return BT_Bloodmoss; }
	case 'Blowbill':             { return BT_Blowbill; }
	case 'Bryonia':              { return BT_Bryonia; }
	case 'Buckthorn':            { return BT_Buckthorn; }
	case 'Celandine':            { return BT_Celandine; }
	case 'Cortinarius':          { return BT_Cortinarius; }
	case 'Crows eye':            { return BT_Crowseye; }
	case 'Ergot seeds':          { return BT_Ergotseeds; }
	case 'Fools parsley leaves': { return BT_Foolsparsleyleaves; }
	case 'Ginatia petals':       { return BT_Ginatiapetals; }
	case 'Green mold':           { return BT_Greenmold; }
	case 'Han':                  { return BT_Han; }
	case 'Hellebore petals':     { return BT_Helleborepetals; }
	case 'Honeysuckle':          { return BT_Honeysuckle; }
	case 'Hop umbels':           { return BT_Hopumbels; }
	case 'Hornwort':             { return BT_Hornwort; }
	case 'Longrube':             { return BT_Longrube; }
	case 'Mandrake root':        { return BT_Mandrakeroot; }
	case 'Mistletoe':            { return BT_Mistletoe; }
	case 'Moleyarrow':           { return BT_Moleyarrow; }
	case 'Nostrix':              { return BT_Nostrix; }
	case 'Pigskin puffball':     { return BT_Pigskinpuffball; }
	case 'Pringrape':            { return BT_Pringrape; }
	case 'Ranogrin':             { return BT_Ranogrin; }
	case 'Ribleaf':              { return BT_Ribleaf; }
	case 'Sewant mushrooms':     { return BT_Sewantmushrooms; }
	case 'Verbena':              { return BT_Verbena; }
	case 'White myrtle':         { return BT_Whitemyrtle; }
	case 'Wolfsbane':            { return BT_Wolfsbane; }
	
	//Glassfish Herbs - https://www.nexusmods.com/witcher3/mods/8258
	case 'Belladonna':           { return BT_Belladonna; }
	case 'Burmarigold':          { return BT_Burmarigold; }
	case 'Chamomile':            { return BT_Chamomile; }
	case 'Hemlock':            	 { return BT_Hemlock; }
	case 'Scleroderm':           { return BT_Scleroderm; }
	case 'Aloe leaves':          { return BT_Aloeleaves; }

	default : return BT_Invalid_Herb_Type;
	}
}

//---------------------------------------------------
//-- Enum Return Functions --------------------------
//---------------------------------------------------

function botanist_get_herb_name_from_enum(value : int) : name
{
	switch(value)
	{
	case BT_Allspiceroot:        return 'Allspice root';        
	case BT_Arenaria:            return 'Arenaria';             
	case BT_Balissefruit:        return 'Balisse fruit';        
	case BT_Beggartickblossoms:  return 'Beggartick blossoms';  
	case BT_Berbercanefruit:     return 'Berbercane fruit';     
	case BT_Bloodmoss:           return 'Bloodmoss';            
	case BT_Blowbill:            return 'Blowbill';             
	case BT_Bryonia:             return 'Bryonia';              
	case BT_Buckthorn:           return 'Buckthorn';            
	case BT_Celandine:           return 'Celandine';            
	case BT_Cortinarius:         return 'Cortinarius';          
	case BT_Crowseye:            return 'Crows eye';            
	case BT_Ergotseeds:          return 'Ergot seeds';          
	case BT_Foolsparsleyleaves:  return 'Fools parsley leaves'; 
	case BT_Ginatiapetals:       return 'Ginatia petals';       
	case BT_Greenmold:           return 'Green mold';           
	case BT_Han:                 return 'Han';                  
	case BT_Helleborepetals:     return 'Hellebore petals';     
	case BT_Honeysuckle:         return 'Honeysuckle';          
	case BT_Hopumbels:           return 'Hop umbels';           
	case BT_Hornwort:            return 'Hornwort';             
	case BT_Longrube:            return 'Longrube';             
	case BT_Mandrakeroot:        return 'Mandrake root';        
	case BT_Mistletoe:           return 'Mistletoe';            
	case BT_Moleyarrow:          return 'Moleyarrow';           
	case BT_Nostrix:             return 'Nostrix';              
	case BT_Pigskinpuffball:     return 'Pigskin puffball';     
	case BT_Pringrape:           return 'Pringrape';            
	case BT_Ranogrin:            return 'Ranogrin';             
	case BT_Ribleaf:             return 'Ribleaf';              
	case BT_Sewantmushrooms:     return 'Sewant mushrooms';     
	case BT_Verbena:             return 'Verbena';              
	case BT_Whitemyrtle:         return 'White myrtle';         
	case BT_Wolfsbane:           return 'Wolfsbane';    
	
	//Glassfish Herbs - https://www.nexusmods.com/witcher3/mods/8258
	case BT_Belladonna:          return 'Belladonna';
	case BT_Burmarigold:         return 'Burmarigold';
	case BT_Chamomile:         	 return 'Chamomile';
	case BT_Hemlock:             return 'Hemlock';
	case BT_Scleroderm:          return 'Scleroderm';
	case BT_Aloeleaves:     	 return 'Aloe leaves';
	
	default : return '';
	}
}

//---------------------------------------------------
//-- Enum Return Functions --------------------------
//---------------------------------------------------

function botanist_get_herb_int_from_enum(value : BT_Herb_Enum) : int
{
	switch(value)
	{
	case BT_Allspiceroot:        return 0;
	case BT_Arenaria:            return 1;
	case BT_Balissefruit:        return 2;
	case BT_Beggartickblossoms:  return 3;
	case BT_Berbercanefruit:     return 4;
	case BT_Bloodmoss:           return 5;
	case BT_Blowbill:            return 6;
	case BT_Bryonia:             return 7;
	case BT_Buckthorn:           return 8;
	case BT_Celandine:           return 9;
	case BT_Cortinarius:         return 10;
	case BT_Crowseye:            return 11;
	case BT_Ergotseeds:          return 12;
	case BT_Foolsparsleyleaves:  return 13;
	case BT_Ginatiapetals:       return 14;
	case BT_Greenmold:           return 15;
	case BT_Han:                 return 16;
	case BT_Helleborepetals:     return 17;
	case BT_Honeysuckle:         return 18;
	case BT_Hopumbels:           return 19;
	case BT_Hornwort:            return 20;
	case BT_Longrube:            return 21;
	case BT_Mandrakeroot:        return 22;
	case BT_Mistletoe:           return 23;
	case BT_Moleyarrow:          return 24;
	case BT_Nostrix:             return 25;
	case BT_Pigskinpuffball:     return 26;
	case BT_Pringrape:           return 27;
	case BT_Ranogrin:            return 28;
	case BT_Ribleaf:             return 29;
	case BT_Sewantmushrooms:     return 30;
	case BT_Verbena:             return 31;
	case BT_Whitemyrtle:         return 32;
	case BT_Wolfsbane:           return 33;
	
	//Glassfish Herbs - https://www.nexusmods.com/witcher3/mods/8258
	case BT_Belladonna:          return 34;
	case BT_Burmarigold:         return 35;
	case BT_Chamomile:           return 36;
	case BT_Hemlock:             return 37;
	case BT_Scleroderm:          return 38;
	case BT_Aloeleaves:     	 return 39;

	default : return -1;               
	}
}

//---------------------------------------------------
//-- Enum Return Functions --------------------------
//---------------------------------------------------

function botanist_get_herb_enum_region() : BT_Herb_Region
{
	switch( AreaTypeToName(theGame.GetCommonMapManager().GetCurrentArea()) )
	{
		case "novigrad"			: return BT_NoMansLand;
		case "no_mans_land"		: return BT_NoMansLand;
		case "skellige"			: return BT_Skellige;
		case "kaer_morhen"		: return BT_KaerMorhen;
		case "prolog_village"	: return BT_WhiteOrchard;
		case "bob"				: return BT_Toussaint;
		default 				: return BT_Invalid_Location;
	}
}

//---------------------------------------------------
//-- Enum Return Functions --------------------------
//---------------------------------------------------

function botanist_get_herb_region_from_int_debug_function(value: int) : string
{
	switch( value )
	{
		case 0: return "Invalid Location";
		case 1: return "White Orchard";
		case 2: return "No Mans Land";
		case 3: return "Skellige";
		case 4: return "Kaer Morhen";
		case 5: return "Toussaint";
		default: return "";
	}
}

//---------------------------------------------------
//-- Herb Validity Functions ------------------------
//---------------------------------------------------

function BT_IsValidHerb(itemName : name) : bool
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
	
	//Glassfish Herbs - https://www.nexusmods.com/witcher3/mods/8258
	case 'Belladonna':
	case 'Burmarigold':
	case 'Chamomile':
	case 'Hemlock':
	case 'Scleroderm':
	case 'Aloe leaves':
		return true;
	
	default: 
		return false;
	}
}
	
//---------------------------------------------------
//-- Herb Override Functions ------------------------
//---------------------------------------------------

function BT_GetOverrideEnumValue( herb_name : name ) : BT_Herb_Enum
{
	return botanist_get_herb_enum_from_name( herb_name );
}

//---------------------------------------------------
//-- Herb Override Functions ------------------------
//---------------------------------------------------

function BT_GetOverrideItemName(value: float) : name
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
	
	//Glassfish Herbs - https://www.nexusmods.com/witcher3/mods/8258
	case 35: return 'Belladonna';
	case 36: return 'Burmarigold';
	case 37: return 'Chamomile';
	case 38: return 'Hemlock';
	case 39: return 'Scleroderm';
	case 40: return 'Aloe leaves';

	default: return '';
	}
}        

exec function bt_reset()
{
	var master : Botanist;
	
	if (!Get_Botanist(master, 'bt_reset'))
	{
		return;
	}
	master.BT_PersistentStorage.BT_HerbStorage.reset_and_clerar();
}

exec function bt_verify_su()
{
	var master : Botanist;
	
	if (!Get_Botanist(master, 'bt_reset'))
	{
		return;
	}
	master.BT_PersistentStorage.BT_HerbStorage.verify_su_pointers();
}