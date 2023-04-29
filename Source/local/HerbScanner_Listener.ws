//---------------------------------------------------
//-- Class ------------------------------------------
//---------------------------------------------------		

statemachine class CHerbScanner_ContainerListener
{
	
	public var filename: name; 
		default filename = 'HSC Container Listener';
	
	public var master: CHerbScanner;
	
	//---------------------------------------------------

	public function initialise(master: CHerbScanner)
	{
		this.master = master;
	}
}

//---------------------------------------------------
//-- States -----------------------------------------
//---------------------------------------------------

state Disabled in CHerbScanner_ContainerListener 
{
	event OnEnterState(previous_state_name: name) 
	{
		super.OnEnterState(previous_state_name);
		HSC_Logger("Entered state [Disabled]", , parent.filename);
	}
}

//---------------------------------------------------
//-- States -----------------------------------------
//---------------------------------------------------

state Idle in CHerbScanner_ContainerListener 
{
	event OnEnterState(previous_state_name: name) 
	{
		super.OnEnterState(previous_state_name);
		HSC_Logger("Entered state [Idle]", , parent.filename);

		this.Idle_Main();
	}

//---------------------------------------------------

	entry function Idle_Main() { 
		
		Sleep(2);		
		parent.GotoState('Checking');
	}
}

//---------------------------------------------------
//-- States -----------------------------------------
//---------------------------------------------------

state Checking in CHerbScanner_ContainerListener 
{
	event OnEnterState(previous_state_name: name) 
	{
		super.OnEnterState(previous_state_name);
		HSC_Logger("Entered state [Checking]", , parent.filename);
		
		this.Checking_Main();
	}

//---------------------------------------------------

	entry function Checking_Main()
	{	
		var Idx: int;
		var tag: name;

		for( Idx = parent.master.current_pins.Size()-1; Idx >= 0; Idx -= 1 )
		{
			parent.master.current_pins[Idx].container.GetStaticMapPinTag( tag );

			if (tag == '')
			{
				SU_removeCustomPinByPosition(parent.master.current_pins[Idx].position);
				parent.master.current_pins.EraseFast(Idx);
			}
		}
		
		parent.GotoState('Idle');
	}
}

