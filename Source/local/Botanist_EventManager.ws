
//---------------------------------------------------
//-- Botanist Event Manager Class -------------------
//---------------------------------------------------

class Botanist_EventHandler 
{
	private var on_herb_reset_registrations  : array< BT_Herb >;
	private var on_herb_looted_registrations : array< BT_Herb >;
	private var on_herb_looted_registrations_hg : array< BT_Harvesting_Ground >;
	private var on_herb_clear_except_registrations_hg : array< BT_Harvesting_Ground >;
	
	//-----------------------------------------------
	
	public function get_registration_count() : int
	{
		return 
			  on_herb_looted_registrations.Size() 
			+ on_herb_looted_registrations_hg.Size() 
			+ on_herb_reset_registrations.Size()
			+ on_herb_clear_except_registrations_hg.Size();
	}
	
	//-----------------------------------------------
	
	public function send_event( data : botanist_event_data ) : void
	{
		var Idx : int;
		
		var temp : array< BT_Herb >;
		var temp_hg : array< BT_Harvesting_Ground >;
		
		switch ( data.type )
		{
			case BT_Herb_Looted : 
			{
				for (Idx = 0; Idx < this.on_herb_looted_registrations.Size(); Idx += 1) 
				{
					this.on_herb_looted_registrations[Idx].On_herb_looted( data._int );
				}	
				
				for (Idx = 0; Idx < this.on_herb_looted_registrations_hg.Size(); Idx += 1) 
				{
					this.on_herb_looted_registrations_hg[Idx].On_herb_looted( data._int );
				}
				break;
			}

			case BT_Herb_Reset : 
			{
				for (Idx = 0; Idx < this.on_herb_reset_registrations.Size(); Idx += 1) 
				{
					this.on_herb_reset_registrations[Idx].On_herb_reset();
				}
				break;				
			}

			case BT_Herb_Clear_Except : 
			{
				temp_hg = on_herb_clear_except_registrations_hg;
				
				for (Idx = 0; Idx < temp_hg.Size(); Idx += 1) 
				{
					temp_hg[Idx].On_clear_except( data._name );
				}
				break;				
			}			

			default : 
				break;
		}
	}
	
	//-----------------------------------------------
	
	public function register_for_event( data : botanist_event_data ) : void
	{
		switch ( data.type )
		{
			case BT_Herb_Looted : 
			{
				if ( data.herb && !this.on_herb_looted_registrations.Contains(data.herb) ) {
					this.on_herb_looted_registrations.PushBack( data.herb );
				}	
				
				if ( data.harvesting_ground && !this.on_herb_looted_registrations_hg.Contains(data.harvesting_ground) ) {
					this.on_herb_looted_registrations_hg.PushBack( data.harvesting_ground );
				}
				break;
			}

			case BT_Herb_Reset : 
			{
				if ( data.herb && !this.on_herb_reset_registrations.Contains(data.herb) ) {
					this.on_herb_reset_registrations.PushBack( data.herb );
				}
				break;
			}

			case BT_Herb_Clear_Except : 
			{
				if ( data.harvesting_ground && !this.on_herb_clear_except_registrations_hg.Contains(data.harvesting_ground) ) {
					this.on_herb_clear_except_registrations_hg.PushBack( data.harvesting_ground );
				}
				break;				
			}
			
			default : break;
		}
	}
	
	//-----------------------------------------------
	
	public function unregister_for_event( data : botanist_event_data ) : void
	{
		switch ( data.type )
		{
			case BT_Herb_Looted : 
			{
				if ( data.herb ) {
					this.on_herb_looted_registrations.Remove( data.herb );
				}
				
				if ( data.harvesting_ground ) {
					this.on_herb_looted_registrations_hg.Remove( data.harvesting_ground );
				}
				break;
			}

			case BT_Herb_Reset : 
			{
				if ( data.herb ) {
					this.on_herb_reset_registrations.Remove( data.herb );
				}
				break;
			}

			case BT_Herb_Clear_Except : 
			{
				if ( data.harvesting_ground ) {
					this.on_herb_clear_except_registrations_hg.Remove( data.harvesting_ground );
				}
				break;				
			}
			
			default : break;
		}
	}
}
