
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