/***********************************************************************/
/** 	© 2015 CD PROJEKT S.A. All rights reserved.
/** 	THE WITCHER® is a trademark of CD PROJEKT S. A.
/** 	The Witcher game is based on the prose of Andrzej Sapkowski.
/***********************************************************************/





class W3Herb extends W3RefillableContainer 
{
	protected optional autobind foliageComponent : CSwitchableFoliageComponent = single;
	protected var isEmptyAppearance : bool;
	
	function  GetStaticMapPinTag( out tag : name )
	{
		var items : array< SItemUniqueId >;
		
		tag = '';
		
		
		
		
		
		
		
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
			AddTimer( 'Refill', 20, true );
		}
	
		if(lootInteractionComponent)
			lootInteractionComponent.SetEnabled( !inv || !inv.IsEmpty() ) ;
			
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
	
	// --= modBotanist Start =--
	function get_herb_name() : name
	{
		var items : array< SItemUniqueId >;
		
		inv.GetAllItems( items );
		if ( !items.Size() )
			return '';
		
		return inv.GetItemName( items[ 0 ] );
	}

	function is_empty() : bool
	{
		return inv.IsEmpty();
	}

	event OnInteractionActivated(interactionComponentName : string, activator : CEntity) 
	{		
		super.OnInteractionActivated(interactionComponentName, activator);
		BT_SetEntityKnown( this );
	}
	// --= modBotanist End =--
	
	protected function PreRefillContainer()
	{
		inv.ResetContainerData();
	}
}