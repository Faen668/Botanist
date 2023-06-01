
class Botanist_RemoveAllMapPins extends SU_PredicateInterfaceRemovePin 
{
	function predicate(pin: SU_MapPin): bool {
		return StrStartsWith(pin.tag, "Botanist_");
	}
}

//---------------------------------------------------
//-- Botanist Persistent Storage Class --------------
//---------------------------------------------------

class Botanist_Storage
{
	var BT_HerbStorage  : Botanist_KnownEntityStorage;
	var BT_EventHandler : Botanist_EventHandler;
}
	
//---------------------------------------------------
//-- Storage Functions ------------------------------
//---------------------------------------------------

function BT_LoadStorageCollection(master: Botanist)
{
	if (!master.BT_PersistentStorage)
	{
		master.BT_PersistentStorage = new Botanist_Storage in master;
		BT_Logger("New Master Storage Instance Created.");
	}
	else
	{
		BT_Logger("Existing Master Storage Instance Loaded.");
	}

//---------------------------------------------------

	if (!master.BT_PersistentStorage.BT_HerbStorage)
	{
		master.BT_PersistentStorage.BT_HerbStorage = new Botanist_KnownEntityStorage in master.BT_PersistentStorage;
		master.BT_PersistentStorage.BT_HerbStorage.inititalise(master);
		BT_Logger("New Herb Storage Instance Created.");
	}
	else
	{
		master.BT_PersistentStorage.BT_HerbStorage.inititalise(master);
		BT_Logger("Existing Herb Storage Instance Loaded With A Size Of: " + master.BT_PersistentStorage.BT_HerbStorage.get_known_herbs_count());
	}

//---------------------------------------------------

	if (!master.BT_PersistentStorage.BT_EventHandler)
	{
		master.BT_PersistentStorage.BT_EventHandler = new Botanist_EventHandler in master.BT_PersistentStorage;
		BT_Logger("New Event Handler Instance Created.");
	}
	else
	{
		BT_Logger("Existing Event Handler Instance Loaded With: " + master.BT_PersistentStorage.BT_EventHandler.get_registration_count() + " registrations");
	}
}

//---------------------------------------------------
//-- Entity Storage Class ---------------------------
//---------------------------------------------------

class Botanist_KnownEntityStorage
{
	var master: Botanist;		
	var botanist_master_herbs: array<BT_Herb>;
	var botanist_master_hashs: array<int>;
	var botanist_master_names: array<name>;
	var botanist_master_world: array<Vector>;
	
	var botanist_known_herbs : array<array<array<BT_Herb>>>;
	var botanist_known_herbs_guid_hashes : array<int>;
	var botanist_known_herbs_initialised : bool;
	
	var botanist_displayed_herbs : array<array<array<BT_Herb>>>;
	var botanist_displayed_herbs_guid_hashes : array<int>;
	
	var botanist_displayed_harvesting_grounds : array<array<array<BT_Harvesting_Ground>>>;
	var botanist_displayed_harvesting_grounds_guid_hashes : array<int>;
	var botanist_displayed_harvesting_grounds_initialised : bool;
	
	var excluded_herbs : array<int>;
	
	var predicate: Botanist_RemoveAllMapPins;

	//---------------------------------------------------
	//-- Entity Storage Functions -----------------------
	//---------------------------------------------------
	
	function inititalise(master: Botanist) : void
	{	
		this.master = master;	
		this.init_exclussion_list();
		this.attach_herb_pointers();
		this.attach_shared_util_pointers();
		
		this.initialise_storage_arrays();
		this.initialise_displayed_harvesting_grounds_arrays();

		predicate = new Botanist_RemoveAllMapPins in thePlayer;
		SU_removeCustomPinByPredicate(predicate);
			
		this.initialise_temporary_displayed_arrays();
		this.initialise_saved_harvesting_grounds();
	}
	
	function init_exclussion_list() : void
	{
		// Keira's Hideout
		this.excluded_herbs.PushBack( 1338875484 );
		this.excluded_herbs.PushBack( 549522696 );
		this.excluded_herbs.PushBack( -541392408 );
		this.excluded_herbs.PushBack( -1078211475 );
		this.excluded_herbs.PushBack( -559926266 );
		this.excluded_herbs.PushBack( -1791854638 );
		this.excluded_herbs.PushBack( -2006234737 );
		this.excluded_herbs.PushBack( -484491973 );
		this.excluded_herbs.PushBack( 963451185 );
		this.excluded_herbs.PushBack( 1270212183 );
		this.excluded_herbs.PushBack( -1606184739 );
	}
	
	function reset_and_clerar() : void
	{
		botanist_master_herbs.Clear();
		botanist_master_hashs.Clear();
		botanist_master_names.Clear();
		botanist_master_world.Clear();
		
		botanist_known_herbs.Clear();
		botanist_known_herbs_guid_hashes.Clear();
		botanist_known_herbs_initialised = false;
		
		botanist_displayed_herbs.Clear();
		botanist_displayed_herbs_guid_hashes.Clear();
		
		botanist_displayed_harvesting_grounds.Clear();
		botanist_displayed_harvesting_grounds_guid_hashes.Clear();
		botanist_displayed_harvesting_grounds_initialised = false;
		
		this.initialise_storage_arrays();
		this.initialise_temporary_displayed_arrays();
	}
	
	function is_herb_excluded(hash : int) : bool
	{
		return excluded_herbs.Contains(hash);
	}
	
	//---------------------------------------------------
	//-- Array Initialisation Functions -----------------
	//---------------------------------------------------

	function initialise_saved_harvesting_grounds() : void
	{
		var Idx, Edx : int;
		var region   : BT_Herb_Region = botanist_get_herb_enum_region();
		var settings : Botanist_UserSettings = this.master.BT_ConfigSettings.get_user_settings();
		
		for (Idx = 0; Idx < this.botanist_displayed_harvesting_grounds[region].Size(); Idx += 1) 
		{
			for (Edx = 0; Edx < this.botanist_displayed_harvesting_grounds[region][Idx].Size(); Edx += 1) 
			{			
				this.botanist_displayed_harvesting_grounds[region][Idx][Edx].load(settings);
			}
		}
	}
	
	//---------------------------------------------------
	
	function initialise_storage_arrays() : void
	{
		var Idx : int;

		if ( this.botanist_known_herbs_initialised )
		{
			return;
		}
		
		this.botanist_known_herbs.Clear();
		this.botanist_known_herbs_guid_hashes.Clear();

		for (Idx = 0; Idx < EnumGetMax('BT_Herb_Region')+1; Idx += 1) 
		{
			this.botanist_known_herbs.PushBack( this.get_blank_region_array() );
		}
		
		this.botanist_known_herbs_initialised = true;
	}

	//---------------------------------------------------
	
	function initialise_displayed_harvesting_grounds_arrays() : void
	{
		var Idx : int;
		
		if ( this.botanist_displayed_harvesting_grounds_initialised )
		{
			return;
		}
		
		this.botanist_displayed_harvesting_grounds.Clear();
		this.botanist_displayed_harvesting_grounds_guid_hashes.Clear();
		
		for (Idx = 0; Idx < EnumGetMax('BT_Herb_Region')+1; Idx += 1) 
		{
			this.botanist_displayed_harvesting_grounds.PushBack( this.get_blank_farming_region_array() );
		}
		
		this.botanist_displayed_harvesting_grounds_initialised = true;
	}
	
	//---------------------------------------------------
	
	function initialise_temporary_displayed_arrays() : void
	{
		var Idx : int;
		
		this.botanist_displayed_herbs.Clear();
		this.botanist_displayed_herbs_guid_hashes.Clear();
		
		for (Idx = 0; Idx < EnumGetMax('BT_Herb_Region')+1; Idx += 1) 
		{
			this.botanist_displayed_herbs.PushBack( this.get_blank_region_array() );
		}
	}

	//---------------------------------------------------
	
	function get_blank_region_array() : array<array<BT_Herb>>
	{
		var output : array<array<BT_Herb>>;
		var Idx : int;

		for (Idx = 0; Idx < EnumGetMax('BT_Herb_Enum')+1; Idx += 1)
		{
		  output.PushBack( this.get_blank_herb_array() );
		}

		return output;	
	}

	//---------------------------------------------------
	
	function get_blank_farming_region_array() : array<array<BT_Harvesting_Ground>>
	{
		var output : array<array<BT_Harvesting_Ground>>;
		var Idx : int;

		for (Idx = 0; Idx < EnumGetMax('BT_Herb_Enum')+1; Idx += 1)
		{
		  output.PushBack( this.get_blank_farming_herb_array() );
		}

		return output;	
	}
	
	//---------------------------------------------------
	
	function get_blank_herb_array() : array<BT_Herb>
	{
		var output : array<BT_Herb>;
		return output;
	}	

	//---------------------------------------------------
	
	function get_blank_farming_herb_array() : array<BT_Harvesting_Ground>
	{
		var output : array<BT_Harvesting_Ground>;
		return output;
	}
	
	//---------------------------------------------------
	//-- Botanist Array Functions -----------------------
	//---------------------------------------------------
	
	function get_known_herbs_count() : int
	{
		return botanist_master_herbs.Size();
	}
	
	//---------------------------------------------------
	
	function has_discovered_plants_in_region(val : name) : bool
	{
		return this.botanist_known_herbs[botanist_get_herb_enum_region()][botanist_get_herb_enum_from_name(val)].Size() > 0;
	}

	//---------------------------------------------------
	
	function get_currently_displayed_count(region : BT_Herb_Region, type : BT_Herb_Enum) : int
	{
		var Idx, harvesting_grounds_count : int;

		for( Idx = 0; Idx < this.botanist_displayed_harvesting_grounds[region][type].Size(); Idx += 1 )
		{
			harvesting_grounds_count += this.botanist_displayed_harvesting_grounds[region][type][Idx].spot_herbs.Size();
		}
		
		return harvesting_grounds_count + this.botanist_displayed_herbs[region][type].Size();
	}
	
	//---------------------------------------------------
	
	function has_harvestable_plants_in_region(herb_name : name) : bool
	{
		var region : BT_Herb_Region = botanist_get_herb_enum_region();
		var type   : BT_Herb_Enum = botanist_get_herb_enum_from_name(herb_name);
		var Idx    : int;
		
		for( Idx = 0; Idx < this.botanist_known_herbs[region][type].Size(); Idx += 1 )
		{
			if ( this.botanist_known_herbs[region][type][Idx].is_eligible_for_normal_display() )
			{
				return true;
			}
		}
		
		return false;
	}	
	
	//---------------------------------------------------
	
	function generate_herb_node_pairing_for_harvesting_grounds(region :  BT_Herb_Region, type : BT_Herb_Enum) : array<Botanist_NodePairing>
	{
		var pairings : array<Botanist_NodePairing>;		
		var Idx      : int;

		for( Idx = 0; Idx < this.botanist_known_herbs[region][type].Size(); Idx += 1 )
		{
			if ( this.botanist_known_herbs[region][type][Idx].is_eligible_for_harvesting_grounds() )
			{
				pairings.PushBack( Botanist_NodePairing( (CNode)this.botanist_known_herbs[region][type][Idx].herb_entity, this.botanist_known_herbs[region][type][Idx] ) );
			}
		}

		return pairings;
	}
	
	//---------------------------------------------------
	//-- Utility Re-Point Function ----------------------
	//---------------------------------------------------
	
	function attach_herb_pointers() : void
	{
		var vspawned_herbs  : array<W3Herb> = theGame.BT_GetArray();
		var Idx, Edx, Rdx, Pdx   : int;
		
		BT_Logger("Running Pointer Attachment On " + vspawned_herbs.Size() + " Herbs...");
		for( Idx = 0; Idx < vspawned_herbs.Size(); Idx += 1 )
		{
			Edx = botanist_master_hashs.FindFirst(vspawned_herbs[Idx].GetGuidHash());
			if (Edx != -1)
			{
				if (  botanist_master_herbs[Edx].reset_entity( vspawned_herbs[Idx] ) )
				{
					Rdx += 1;
					continue;
				}
				
				Pdx += 1;
			}
		}
		
		BT_Logger("Re-attached Entity Pointers On [" + Rdx + " / " + get_known_herbs_count() + "] Known Herbs With [" + Pdx + "] Failures.");
		theGame.BT_ClearArray();		
	}
	
	function list_known_herbs() : void
	{
		var Idx : int;
		
		BT_Logger("Processing Known Herbs List With A Size Of: " + get_known_herbs_count());
		for( Idx = 0; Idx < botanist_master_herbs.Size(); Idx += 1 )
		{
			botanist_master_herbs[Idx].print_info();
		}	
	}

	//---------------------------------------------------
	//-- Shared Utils Re-Point Function -----------------
	//---------------------------------------------------
	
	function attach_shared_util_pointers() : void
	{
		var Idx, Edx, Pdx, Rdx : int;
		var marker_manager : SUOL_Manager = SUOL_getManager();
		var mappin_manager : SUMP_Manager = SUMP_getManager();
		
		for (Idx = 0; Idx < this.botanist_master_herbs.Size(); Idx += 1) 
		{	
			if ( this.botanist_master_herbs[Idx].attach_shared_util_pointers( marker_manager, mappin_manager ) )
			{
				Rdx += 1;
				continue;
			}

			Pdx += 1;
		}
		
		BT_Logger("Re-attached Shared Util Pointers On [" + Rdx + " / " + get_known_herbs_count() + "] Known Herbs With [" + Pdx + "] Failures.");		
	}

	//---------------------------------------------------
	//-- Shared Utils Verification Function -------------
	//---------------------------------------------------
	
	function verify_su_pointers() : void
	{
		var Idx, Edx, Pdx, Rdx : int;
		
		for (Idx = 0; Idx < this.botanist_master_herbs.Size(); Idx += 1) 
		{	
			if ( this.botanist_master_herbs[Idx].are_shared_util_pointers_attached() )
			{
				Rdx += 1;
				continue;
			}

			Pdx += 1;
		}
		
		GetWitcherPlayer().DisplayHudMessage("Shared Util Pointers Verified On [" + Rdx + " / " + get_known_herbs_count() + "] Known Herbs With [" + Pdx + "] Failures.");	
	}
}