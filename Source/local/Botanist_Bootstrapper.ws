
//---------------------------------------------------
//-- Botanist Bootstrapper Class --------------------
//---------------------------------------------------

state Botanist_BootStrapper in SU_TinyBootstrapperManager extends BaseMod 
{
	public function getTag(): name 
	{
		return 'Botanist_BootStrapper';
	}
	
	//-----------------------------------------------
	
	public function getMod(): SU_BaseBootstrappedMod 
	{
		return new Botanist in parent;
	}
}
