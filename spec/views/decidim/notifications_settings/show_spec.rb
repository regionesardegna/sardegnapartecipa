# frozen_string_literal: true

require "rails_helper"

describe "decidim/notifications_settings/show.html.erb" do
  let(:user) { create(:user) }

  class NotificationSettings
    include ActiveModel::Model
    attr_accessor :notifications_from_own_activity, :notifications_from_followed, :newsletter_notifications, :allow_public_contact, :email_on_moderations, :meet_push_notifications_requirements, :notification_settings
    
    def meet_push_notifications_requirements? = meet_push_notifications_requirements
    def persisted? = true
  end

  let(:notifications_settings) { NotificationSettings.new(
    notifications_from_own_activity: true,
    notifications_from_followed: true,
    newsletter_notifications: false,
    allow_public_contact: true,
    email_on_moderations: false,
    meet_push_notifications_requirements: false,
    notification_settings: {}
  ) }

  before do
    allow(view).to receive(:current_user).and_return(user)
    
    # helper for Decidim
    view.define_singleton_method(:notifications_settings_path) { "/notifications_settings" }
    view.define_singleton_method(:frequencies_collection) { [] }
    view.define_singleton_method(:icon) { |*_args| "" }
    view.define_singleton_method(:user_menu) { "" }
    view.define_singleton_method(:add_decidim_page_title) { |*_args| }
    view.define_singleton_method(:content_for) { |*_args, &block| block.call if block }

    allow(view).to receive(:render).and_wrap_original do |m, *args, &block|
      if args.first.is_a?(Hash) && args.first[:layout] == "layouts/decidim/shared/layout_user_profile"
        block.call
      else
        m.call(*args, &block)
      end
    end
    
    assign(:notifications_settings, notifications_settings)
  end

  it "nasconde il campo newsletter" do
    render
    
    # Check for the style="display:none" in the label or div
    expect(rendered).to have_selector('label[style*="display:none"]', text: "Le Newsletter", visible: false)
    expect(rendered).to have_selector('div[style*="display:none"]', text: "Voglio ricevere le newsletter", visible: false)
  end
end
