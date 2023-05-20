
//---------------------------------------------------
//-- Botanist Required Herbs Struct -----------------
//---------------------------------------------------

struct Botanist_RequiredHerbs
{
	var names		: array<name>;
	var quantities	: array<int>;
	var cookeditems	: array<array<name>>;
}

//---------------------------------------------------
//--Botanist Alchemy Manager Class ------------------
//---------------------------------------------------

class Botanist_AlchemyManager
{
	var master : Botanist;
	var storage : Botanist_KnownEntityStorage;
	
	//-----------------------------------------------
	
	public function initialise(master: Botanist) : void
	{
		this.master = master;
		this.storage = master.BT_PersistentStorage.BT_HerbStorage;
	}
	
	//-----------------------------------------------
	
	public function get_alchemy_data(m_alchemyManager : W3AlchemyManager) : Botanist_RequiredHerbs
	{
		var output_data  : Botanist_RequiredHerbs = initialise_struct();
		var m_recipeList : array<SAlchemyRecipe>;
		var blank_array	 : array<name>;
		var herb_name    : name;
		var item_name  	 : name;
		var herb_quantity : int;
		var Idx, Edx, Rdx : int;
		
		//Obtain a list of all known recipes.
		m_recipeList = m_alchemyManager.GetRecipes(false);

		//Traverse Recipe List.
		for( Idx = 0; Idx < m_recipeList.Size(); Idx += 1 )
		{
			//Traverse Recipe Lists Required Ingredients.
			for( Edx = 0; Edx < m_recipeList[Idx].requiredIngredients.Size(); Edx += 1 )
			{	
				item_name = m_recipeList[Idx].cookedItemName;
				herb_name = m_recipeList[Idx].requiredIngredients[Edx].itemName;
				herb_quantity = m_recipeList[Idx].requiredIngredients[Edx].quantity;

				//If we have not discovered any plants in the current region of this type then ignore it.
				if ( !this.storage.has_discovered_plants_in_region( herb_name ) )
				{
					continue;
				}

				//Check to see if we need this herb for a previous recipe.
				Rdx = output_data.names.FindFirst( herb_name );

				if (Rdx != -1)
				{
					//If we know we already need this herb, increase the quantity for it and record the recipe its used for.
					output_data.quantities[Rdx] += herb_quantity;
					output_data.cookeditems[Rdx].PushBack( item_name );
				}
				else
				{
					//If we need this herb then record its name, quantity and the recipe its used for.
					output_data.names.PushBack( herb_name );
					output_data.quantities.PushBack( herb_quantity );
					
					blank_array = get_blank_name_array();
					blank_array.PushBack( item_name );
					output_data.cookeditems.PushBack( blank_array );
				}
			}
		}

		//Traverse output List.
		for( Idx = output_data.names.Size()-1; Idx >= 0; Idx -= 1 )
		{
			//Lower the quantity of the herbs needed for recipes by the amount the player already has in their inventory.
			output_data.quantities[Idx] -= thePlayer.inv.GetItemQuantityByName(output_data.names[Idx]);

			if ( output_data.quantities[Idx] <= 0 )
			{
				//If the quantity we need drops below or equal to 0, remove the herb from consideration as it's not needed.
				output_data.names.EraseFast(Idx);
				output_data.quantities.EraseFast(Idx);
				output_data.cookeditems.EraseFast(Idx);
			}
		}
		
		//Finished. Return the data.
		return output_data;
	}

	//-----------------------------------------------

	private function initialise_struct() : Botanist_RequiredHerbs
	{
		var output_data : Botanist_RequiredHerbs;
		return output_data;
	}

	//-----------------------------------------------

	private function get_blank_name_array() : array<name>
	{
		var output : array<name>;
		return output;
	}
}
