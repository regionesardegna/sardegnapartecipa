module ApplicationHelper

  def mobile_assemblies_active?
    return false unless Gem.loaded_specs.has_key?("decidim-assemblies")

    # 1. Prendiamo solo le assemblee pubblicate
    published_assemblies = Decidim::Assembly.published

    # 2. Controlliamo se ce n'è almeno una attiva.
    # In Decidim, un'assemblea è considerata attiva se la sua data di fine (duration) 
    # è nel futuro, oppure se non ha una data di fine ed è semplicemente pubblicata.
    published_assemblies.where(
      "duration >= ? OR duration IS NULL", 
      Date.current
    ).exists?
  end
  
end
