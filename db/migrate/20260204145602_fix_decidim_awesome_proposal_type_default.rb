# frozen_string_literal: true

class FixDecidimAwesomeProposalTypeDefault < ActiveRecord::Migration[6.1]
  def up
    # 1. Impostiamo il default a livello di database
    change_column_default :decidim_awesome_proposal_extra_fields, 
                         :decidim_proposal_type, 
                         from: nil, 
                         to: "Decidim::Proposals::Proposal"

    # 2. Rendiamo la colonna NOT NULL se non lo fosse già (sicurezza extra)
    change_column_null :decidim_awesome_proposal_extra_fields, :decidim_proposal_type, false

    # 3. Sanatorie sui dati (nel caso in cui record nulli fossero sfuggiti)
    execute <<~SQL.squish
      UPDATE decidim_awesome_proposal_extra_fields
      SET decidim_proposal_type = 'Decidim::Proposals::Proposal'
      WHERE decidim_proposal_type IS NULL OR decidim_proposal_type = '';
    SQL
  end

  def down
    change_column_default :decidim_awesome_proposal_extra_fields, :decidim_proposal_type, from: "Decidim::Proposals::Proposal", to: nil
  end
end