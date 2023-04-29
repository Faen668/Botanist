
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
}