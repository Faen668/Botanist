
//---------------------------------------------------
//-- Class ------------------------------------------
//---------------------------------------------------		

statemachine class Botanist_UIDisplayCreator
{	
	public var region         : BT_Herb_Region;
	public var type           : BT_Herb_Enum;
	public var quantity       : int;
	public var user_settings  : Botanist_UserSettings;
	public var storage        : Botanist_KnownEntityStorage;
	
	public function create_and_set_variables(data : Botanist_DataTransferStruct) : Botanist_UIDisplayCreator
	{
		this.region        = data.region;
		this.type          = data.type;
		this.quantity      = data.quantity;
		this.user_settings = data.user_settings;
		this.storage       = data.storage;

		this.GotoState('Processing');
		return this;
	}
}

//---------------------------------------------------
//-- Botanist Display Class - (idle State) ----------
//---------------------------------------------------

state idle in Botanist_UIDisplayCreator 
{
	event OnEnterState(previous_state_name: name) 
	{
		super.OnEnterState(previous_state_name);
	}
}

//---------------------------------------------------
//-- Botanist Display Class - (Processing State) ----
//---------------------------------------------------

state Processing in Botanist_UIDisplayCreator 
{	
	event OnEnterState(previous_state_name: name) 
	{
		super.OnEnterState(previous_state_name);		
		this.Processing();
	}

	//---------------------------------------------------

	entry function Processing()
	{
		var node 		 : CNode;
		var Idx, Edx	 : int;
		var known_nodes  : array<CNode>;
		var known_herbs	 : array<BT_Herb> = parent.storage.botanist_known_herbs[parent.region][parent.type];

		if ( parent.storage.get_currently_displayed_count(parent.region, parent.type) >= parent.quantity )
		{
			return;
		}
		
		for( Idx = 0; Idx < known_herbs.Size(); Idx += 1 )
		{
			if ( known_herbs[Idx].is_eligible_for_normal_display() )
			{
				known_nodes.PushBack( (CNode)known_herbs[Idx].herb_entity );
			}
		}
		
		SortNodesByDistance(thePlayer.GetWorldPosition(), known_nodes);
		for( Idx = 0; Idx < Min(known_nodes.Size(), parent.quantity); Idx += 1 )
		{
			for ( Edx = 0; Edx < known_herbs.Size(); Edx += 1 )
			{
				if (known_nodes[Idx].GetWorldPosition() == known_herbs[Edx].herb_entity.GetWorldPosition())
				{
					known_herbs[Edx].set_displayed();
				}
			}
		}
		
		if ( parent.user_settings.bools[BT_Config_Hgr_Enabled] )
		{
			this.check_for_eligible_grounds(parent.region, parent.type, parent.user_settings);
		}
		
		parent.GotoState('idle');
	}

	//---------------------------------------------------
	//-- Harvesting Grounds -----------------------------
	//---------------------------------------------------
	
	private function check_for_eligible_grounds(region : BT_Herb_Region, type : BT_Herb_Enum, user_settings : Botanist_UserSettings) : void
	{		
		var hg_all_nodes        : array<Botanist_NodePairing>;
		
		var hg_result_01        : Botanist_HarvestGroundResults;
		var hg_result_02        : Botanist_HarvestGroundResults;
		var hg_result_03        : Botanist_HarvestGroundResults;
		
		var hg_maxground		: int = user_settings.ints[BT_Config_Hgr_MaxGrd];
		var hg_displayed		: int = parent.storage.botanist_displayed_harvesting_grounds[region][type].Size();
		
		//Generate an array of nodes and their matching botanist herb classes.		
		hg_all_nodes = parent.storage.generate_herb_node_pairing_for_harvesting_grounds(region, type);
		
		if ( hg_displayed < hg_maxground && hg_all_nodes.Size() > 0 )
		{
			hg_result_01 = this.findHarvestingGround(user_settings, hg_all_nodes);
			this.create_harvesting_grounds(region, type, user_settings, hg_result_01);
			
			if ( hg_displayed < hg_maxground && hg_maxground > 1 )
			{
				hg_result_02 = this.findHarvestingGround(user_settings, hg_result_01.filtered_nodes);
				this.create_harvesting_grounds(region, type, user_settings, hg_result_02);			
			}
			
			if ( hg_displayed < hg_maxground && hg_maxground > 2 )
			{
				hg_result_03 = this.findHarvestingGround(user_settings, hg_result_02.filtered_nodes);
				this.create_harvesting_grounds(region, type, user_settings, hg_result_03);			
			}
		}
	}
	
	//---------------------------------------------------
	
	private function findHarvestingGround(user_settings : Botanist_UserSettings, node_pairings: array<Botanist_NodePairing>) : Botanist_HarvestGroundResults
	{	
		var output : Botanist_HarvestGroundResults;
		var Edx    : int = RandRange(node_pairings.Size(), 0);
		var Rdx    : int = user_settings.ints[BT_Config_Hgr_Radius];
		var Pdx    : int = user_settings.ints[BT_Config_Hgr_MaxAll];
		var Idx    : int;

		for (Idx = 0; Idx < node_pairings.Size(); Idx += 1) 
		{				
			if ( output.harvesting_nodes.Size() < Pdx && VecDistanceSquared2D(node_pairings[Edx].node.GetWorldPosition(), node_pairings[Idx].node.GetWorldPosition()) <= (Rdx * Rdx) )
			{
				output.harvesting_nodes.PushBack( Botanist_NodePairing(node_pairings[Idx].node, node_pairings[Idx].herb) );
			}
			else
			{
				output.filtered_nodes.PushBack( Botanist_NodePairing(node_pairings[Idx].node, node_pairings[Idx].herb) );
			}
		}
		return output;
	}

	//---------------------------------------------------
	
	private function generate_map_pin_position_from_results(hg_result: Botanist_HarvestGroundResults) : Vector
	{
		var current_distance, new_distance: float;
		var first, last : Vector;
		var Idx, Edx, Rdx : int;
	  
		Rdx = hg_result.harvesting_nodes.Size();
		
		first = hg_result.harvesting_nodes[0].node.GetWorldPosition();
		last  = hg_result.harvesting_nodes[0].node.GetWorldPosition();
		current_distance = 0;

		for (Idx = 0; Idx < Rdx; Idx += 1)
		{
			for (Edx = 0; Edx < Rdx; Edx += 1) 
			{
				new_distance = VecDistanceSquared2D(hg_result.harvesting_nodes[Idx].node.GetWorldPosition(), hg_result.harvesting_nodes[Edx].node.GetWorldPosition());

				if (new_distance > current_distance) 
				{
					first = hg_result.harvesting_nodes[Idx].node.GetWorldPosition();
					last  = hg_result.harvesting_nodes[Edx].node.GetWorldPosition();
					current_distance = new_distance;
				}
			}
		}
		return (first + last) / 2;
	}
	
	//---------------------------------------------------
	
	private function get_furthermost_point_from_centre(mappin_position : Vector, hg_result: Botanist_HarvestGroundResults) : float
	{
		var current_distance, new_distance: float;
		var Idx : int;

		current_distance = 0;

		for (Idx = 0; Idx < hg_result.harvesting_nodes.Size(); Idx += 1)
		{
			new_distance = VecDistanceSquared2D(hg_result.harvesting_nodes[Idx].node.GetWorldPosition(), mappin_position);

			if (new_distance > current_distance) 
			{
				current_distance = new_distance;
			}
		}		
		return SqrtF(current_distance) + 10;
	}

	//---------------------------------------------------
	
	private function create_harvesting_grounds(region : BT_Herb_Region, type : BT_Herb_Enum, user_settings : Botanist_UserSettings, hg_result: Botanist_HarvestGroundResults)
	{
		var position : Vector;
		var radius	 : float;		
		
		if ( hg_result.harvesting_nodes.Size() >= user_settings.ints[BT_Config_Hgr_MinReq] )
		{
			//Calculate the centre position and radius of the map pin for the harvesting grounds.
			position = this.generate_map_pin_position_from_results(hg_result);
			
			//Obtain the furthest herb from the centre point on the map pin within range.
			radius = this.get_furthermost_point_from_centre(position, hg_result);
			
			//Create the farming spot and display it on the map.
			( (new BT_Harvesting_Ground in this).create(hg_result, region, type, radius, position, parent.storage.master, user_settings) );
		}
	}
}
