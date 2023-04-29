//---------------------------------------------------
//-- Bootstrapper Class -----------------------------
//---------------------------------------------------

state CHerbScanner_BootStrapper in SU_TinyBootstrapperManager extends BaseMod 
{
	public function getTag(): name 
	{
		return 'CHerbScanner_BootStrapper';
	}
	
	public function getMod(): SU_BaseBootstrappedMod 
	{
		return new CHerbScanner in parent;
	}
}