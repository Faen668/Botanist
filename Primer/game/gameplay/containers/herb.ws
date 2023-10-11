/***********************************************************************/
/** 	© 2015 CD PROJEKT S.A. All rights reserved.
/** 	THE WITCHER® is a trademark of CD PROJEKT S. A.
/** 	The Witcher game is based on the prose of Andrzej Sapkowski.
/***********************************************************************/





class W3Herb extends W3RefillableContainer
{
	protected optional autobind foliageComponent : CSwitchableFoliageComponent = single;
	protected var isEmptyAppearance : bool;
	public var adjusted_yield, growing : bool; //modPrimer

	// --= modBotanist =--
	function is_empty() : bool
	{
		return inv.IsEmpty();
	}
	// --= modBotanist =--
	
	function  GetStaticMapPinTag( out tag : name )
	{
		var items : array< SItemUniqueId >;

		tag = '';
		
		
		
		
		
		
		if (theGame.alchexts.hide_herbs) return ; //modPrimer
		if ( foliageComponent )
		{
			if ( foliageComponent.GetEntry() == 'empty' )
			{
				return;
			}
		}
		else if ( isEmptyAppearance )
		{
			return;
		}
		if ( IsEmpty() )
		{
			return;
		}
		if ( !inv )
		{
			return;
		}
		if ( inv.GetItemCount() == 0 )
		{
			return;
		}
		inv.GetAllItems( items );
		tag = inv.GetItemName( items[ 0 ] );
	}
	
	event OnSpawned( spawnData : SEntitySpawnData )
	{
		super.OnStreamIn();

		// --= modBotanist =--
		theGame.BT_AddSpawnedEntity(this);
		// --= modBotanist =--
		
		if( inv.IsEmpty() )
		{
			AddTimer('respawn_herb', theGame.alchexts.herbctrl.GetSeededRand(4096, 1024), true); growing = true;
		}	theGame.alchexts.herbctrl.OnHerbSpawnRequest(this); //modPrimer
	
		if(lootInteractionComponent)
			lootInteractionComponent.SetEnabled( inv && !inv.IsEmpty() ) ;//modPrimer vanilla logic-error fix
			
		if ( foliageComponent )
		{
			if ( inv.IsEmpty() )
			{
				foliageComponent.SetAndSaveEntry( 'empty' );
			}
			else
			{
				foliageComponent.SetAndSaveEntry( 'full' );
			}
		}
	}	

	function ApplyAppearance( appearanceName : string )
	{
		if ( appearanceName == "2_empty" )
		{
			isEmptyAppearance = true;
			// --= modBotanist =--
			BT_SetEntityLooted(this);
			// --= modBotanist =--
		}
		else
		{
			isEmptyAppearance = false;
		}
		super.ApplyAppearance( appearanceName );
	}

	// --= modBotanist =--
	function get_herb_name() : name
	{
		var items : array< SItemUniqueId >;
		
		inv.GetAllItems( items );
		if ( !items.Size() )
			return '';
		
		return inv.GetItemName( items[ 0 ] );
	}
	// --= modBotanist =--
	
	protected function PreRefillContainer()
	{
		inv.ResetContainerData();
	}

	timer function respawn_herb(elapsed : float, id : int) //modPrimer [
	{
		if (inv && inv.IsLootRenewable() )
			theGame.alchexts.herbctrl.OnRespawnTimerElapsed(this);
		else RemoveTimer('respawn_herb');
	}

	timer function get_area_name(elapsed : float, id : int)
	{
		theGame.alchexts.herbctrl.OnGameAreaLoaded(theGame.GetCommonMapManager().GetCurrentArea() );
	}

	event OnInteractionActivated(interactionComponentName : string, activator : CEntity) 
	{
		var herbs	: array<SItemUniqueId>;
		var herb	: SItemUniqueId;
		var yield	: int;
		var count	: int;

		if (adjusted_yield || activator != thePlayer || theGame.alchexts.ignore_spawns || inv.IsEmpty() )
			return (false);

		// --= modBotanist =--
		BT_SetEntityKnown( this );
		// --= modBotanist =--
		
		inv.GetAllItems(herbs);
		if (herbs.Size() > 1 || HasQuestItem() || focusModeHighlight == FMV_Clue)
		{	super.OnInteractionActivated(interactionComponentName, activator);
			return (false);
		}
		herb = herbs[0];
		count = inv.GetItemQuantity(herb);
		yield = theGame.alchexts.herbctrl.GetHerbYield() - count;
		switch ((int)(yield > 0) - (int)(yield < 0) )
		{	case -1:	inv.RemoveItem(herb, -yield);					break ;
			case 1:		inv.AddAnItem(inv.GetItemName(herb), yield);	break ;
			default:
			break ;
		}
		adjusted_yield = true;
	}
	
	event OnStreamIn()
	{
		if (growing && !theGame.alchexts.ignore_spawns)
			((CSwitchableFoliageComponent)GetComponentByClassName('CSwitchableFoliageComponent') ).SetAndSaveEntry('empty');
		else super.OnStreamIn();
	}

	event OnItemTaken(id : SItemUniqueId, count : int)
	{
		growing = true;
		super.OnItemTaken(id, count);
	}
	//modPrimer ]

}