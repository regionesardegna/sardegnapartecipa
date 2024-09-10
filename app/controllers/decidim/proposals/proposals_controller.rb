# Copyright (C) 2022 Formez PA
# This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation, version 3.
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
# You should have received a copy of the GNU Affero General Public License along with this program. If not, see <https://www.gnu.org/licenses/>

# Override necessario per poter gestire il flusso personalizzato dei nuovi stati in caso di moderazione abilitata.

# frozen_string_literal: true

require_dependency Decidim::Proposals::Engine.root.join('app', 'controllers', 'decidim', 'proposals', 'proposals_controller').to_s

module Decidim
  module Proposals
    class ProposalsController
     include ActionController::Helpers
     include AbstractController::Callbacks

      def index
        if component_settings.participatory_texts_enabled?
          @proposals = Decidim::Proposals::Proposal
                         .where(component: current_component)
                         .published
                         .not_hidden
                         .only_amendables
                         .includes(:category, :scope)
                         .order(position: :asc)
          render "decidim/proposals/proposals/participatory_texts/participatory_text"
        else
          if current_user
            @base_query = search.results.published.not_hidden.or(search.results.in_review_for_user(current_user).not_hidden)
            @base_query = @base_query.where.not(id: Proposal.not_in_moderation_rejected_for_user(current_user).ids)
            if current_component.try(:current_settings).try(:moderation_amendment_enabled)
              @base_query = @base_query.where.not(id: (Proposal.in_review_accepted - Proposal.in_acceptance_for_user(current_user)).map(&:id))
            end
          else
            @base_query = search
                            .results
                            .not_in_review
                            .not_in_moderation_rejected
                            .not_in_review_accepted
                            .or(search.results.where(state: nil))
                            .published
                            .not_hidden
          end

          @proposals = @base_query.includes(:component, :coauthorships)
          @all_geocoded_proposals = @base_query.geocoded

          @voted_proposals = if current_user
                               ProposalVote.where(
                                 author: current_user,
                                 proposal: @proposals.pluck(:id)
                               ).pluck(:decidim_proposal_id)
                             else
                               []
                             end
          @proposals = paginate(@proposals)
          @proposals = reorder(@proposals)
        end
      end

      def new
        enforce_permission_to :create, :proposal
        @step = :step_1
        if proposal_draft.present?
          if proposal_draft.review?
            redirect_back fallback_location: :index, flash: { alert: I18n.t("proposals.create.already_in_review", scope: "decidim") }
          else
            redirect_to edit_draft_proposal_path(proposal_draft, component_id: proposal_draft.component.id, question_slug: proposal_draft.component.participatory_space.slug)
          end
        else
          @form = form(ProposalWizardCreateStepForm).from_params(body: translated_proposal_body_template)
        end
      end

      def preview
        enforce_permission_to :edit, :proposal, proposal: @proposal
        @step = is_review_mode? ? :step_5 : :step_4
        @form = form(ProposalForm).from_model(@proposal)
        render @step == :step_5 ? :review : :preview
      end

      def publish
        enforce_permission_to :edit, :proposal, proposal: @proposal
        @step = is_review_mode? ? :step_5 : :step_4
        if is_review_mode?
          ReviewProposal.call(@proposal, current_user) do
            on(:ok) do
              flash[:notice] = I18n.t("proposals.review.success", scope: "decidim")
              redirect_to proposal_path(@proposal)
            end

            on(:invalid) do
              flash.now[:alert] = I18n.t("proposals.review.error", scope: "decidim")
              render :edit_draft
            end
          end
        else
          PublishProposal.call(@proposal, current_user) do
            on(:ok) do
              flash[:notice] = I18n.t("proposals.publish.success", scope: "decidim")
              redirect_to proposal_path(@proposal)
            end

            on(:invalid) do
              flash.now[:alert] = I18n.t("proposals.publish.error", scope: "decidim")
              render :edit_draft
            end
          end
        end
      end

      def edit
        enforce_permission_to :update, :proposal, proposal: @proposal
      end

      def update
        enforce_permission_to :update, :proposal, proposal: @proposal

        @form = form_proposal_params
        UpdateProposal.call(@form, current_user, @proposal) do
          on(:ok) do |proposal|
            flash[:notice] = I18n.t("proposals.update.success", scope: "decidim")
            redirect_to Decidim::ResourceLocatorPresenter.new(proposal).path
          end

          on(:invalid) do
            flash.now[:alert] = I18n.t("proposals.update.error", scope: "decidim")
            render :edit
          end
        end
      end

      def permission_class_chain
        [Decidim::ProposalModeration::Permissions] + super
      end

      def set_proposal
        @proposal = Proposal.published.not_hidden.where(component: current_component).find_by(id: params[:id]) ||
          Proposal.in_review.not_hidden.where(component: current_component).find_by(id: params[:id])
      end

      def can_show_proposal?
        return false if current_component.current_settings.try(:moderation_amendment_enabled) && @proposal.acceptance? && (!@proposal.authors.include?(current_user) && !current_user&.admin? && !@proposal.try(:amendable).try(:authors).try(:include?, current_user))
        return false if current_component.current_settings.try(:moderation_enabled) && @proposal && @proposal.review_failed? && (!@proposal.authors.include?(current_user) && !current_user&.admin?)
        return false if current_component.current_settings.try(:moderation_enabled) && @proposal && @proposal.review? && (!@proposal.authors.include?(current_user) && !current_user&.admin?)
        return true if @proposal&.amendable? || current_user&.admin?

        Proposal.only_visible_emendations_for(current_user, current_component).published.include?(@proposal) ||
          Proposal.only_visible_emendations_for(current_user, current_component).in_review.include?(@proposal) ||
          Proposal.only_visible_emendations_for(current_user, current_component).in_moderation_rejected.include?(@proposal)
      end

      protected

      def is_review_mode?
        current_component.current_settings.try(:moderation_enabled) && current_user && !current_user&.admin?
      end
      helper_method :is_review_mode?

    end
  end
end
