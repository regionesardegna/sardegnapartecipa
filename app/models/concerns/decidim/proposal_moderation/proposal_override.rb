# Copyright (C) 2024 Sardegna IT
# This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation, version 3.
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
# You should have received a copy of the GNU Affero General Public License along with this program. If not, see <https://www.gnu.org/licenses/>

# Aggiunti helper per la proposta e gli emendamenti e i relativi nuovi stati

module Decidim
  module ProposalModeration
    module ProposalOverride

      extend ActiveSupport::Concern

      included do

        scope :in_moderation_rejected, -> { where(state: "moderation_rejected") }
        scope :not_in_moderation_rejected, -> { where.not(state: "moderation_rejected") }
        scope :in_moderation_rejected_for_user, -> (user) do
          where({state: "moderation_rejected"}.merge(user.admin? ? {} : { id: ::Decidim::Proposals::Proposal.user_collection(user).ids }))
        end
        scope :in_review, -> { where(published_at: nil, state: "review") }
        scope :not_in_review, -> { where.not(state: "review") }
        scope :not_in_moderation_rejected_for_user, -> (user) do
          # Relation passed to #or must be structurally compatible. Incompatible values: [:join]
          where(state: "moderation_rejected").where.not(id: ::Decidim::Proposals::Proposal.in_moderation_rejected_for_user(user).ids)
        end
        scope :in_review_for_user, -> (user) do
          # Relation passed to #or must be structurally compatible. Incompatible values: [:join]
          where({published_at: nil, state: "review"}.merge(user.admin? ? {} : { id: ::Decidim::Proposals::Proposal.user_collection(user).ids }))
        end
        scope :not_in_review_accepted, -> { where.not(state: "review_accepted") }
        scope :in_review_accepted, -> { where(state: "review_accepted") }
        scope :in_acceptance_for_user, -> (user) do
          # Relation passed to #or must be structurally compatible. Incompatible values: [:join]
          where({state: "review_accepted"}.merge(user.admin? ? {} : { id: ::Decidim::Proposals::Proposal.user_collection(user).ids }))
        end

        def state
          return amendment.state if emendation?
          return nil unless published_state? || withdrawn? || review? || review_failed?

          super
        end

        def review?
          internal_state == "review"
        end

        def acceptance?
          internal_state == "review_accepted"
        end

        def review_failed?
          internal_state == "moderation_rejected"
        end

        def editable_by?(user)
          return false if review? || review_failed?
          return true if draft? && created_by?(user)

          !published_state? && within_edit_time_limit? && !copied_from_other_component? && created_by?(user)
        end

      end

    end
  end
end
