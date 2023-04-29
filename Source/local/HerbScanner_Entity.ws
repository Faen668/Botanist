//---------------------------------------------------
//-- Entity Class -----------------------------------
//---------------------------------------------------

class HSC_Preview_Data 
{
	var radius			: int;
	var filename		: name;
	var uuid			: string;
	var label			: string;
	var description		: string;
	var position		: Vector;
	var region			: string;
	var container		: W3Herb;
	
	var minimap			: bool;
	var pointer			: bool;
	var highlight		: bool;
	
	default filename = 'HSC Entity';
	
	function create() : HSC_Preview_Data 
	{
		return this;
	}
	
	function setUUID(value: string) : HSC_Preview_Data 
	{
		this.uuid = value;
		return this;
	}

	function setPosition(value: Vector) : HSC_Preview_Data 
	{
		this.position = value;
		return this;
	}

	function setLabel(value: string) : HSC_Preview_Data 
	{
		this.label = value;
		return this;
	}	
	
	function setDescription(recipe: string, optional override: bool) : HSC_Preview_Data 
	{
		if (override)
		{
			this.description = "A common herb used in Alchemy for various recipes";
			return this;
		}
		
		this.description = "A common alchemy ingredient used to create <font color='#D7D23A'>" + recipe + "</font>";
		return this;
	}	

	function setRegion(value: string) : HSC_Preview_Data 
	{
		this.region = value;
		return this;
	}	

	function setContainer(value: W3Herb) : HSC_Preview_Data 
	{
		this.container = value;
		return this;
	}	

	function setRadius(value: int) : HSC_Preview_Data 
	{
		this.radius = value;
		return this;
	}

	function setMinimap(value: bool) : HSC_Preview_Data 
	{
		this.minimap = value;
		return this;
	}

	function setPointer(value: bool) : HSC_Preview_Data 
	{
		this.pointer = value;
		return this;
	}

	function setHighlight(value: bool) : HSC_Preview_Data 
	{
		this.highlight = value;
		return this;
	}
	
	function DisplayPin(manager: CHerbScanner_MapPins) : HSC_Preview_Data 
	{
		manager.RefreshPin(this);
		
		HSC_Logger("Entity created with map pin: " + this.uuid + " " + this.description + " " + this.region, , this.filename);
		return this;
	}		
}