
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