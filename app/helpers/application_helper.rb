# frozen_string_literal: true

# Copyright (C) 2025 Sardegna IT
#
# This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation, version 3.
#
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License along with this program. If not, see <https://www.gnu.org/licenses/>

# Modificato per integrare mobile_assemblies_active? per verifica se ci siano assemblee pubbliche

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
