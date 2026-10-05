# frozen_string_literal: true

require "rails_helper"

describe "decidim/devise/registrations/new.html.erb" do
  let(:organization) { create(:organization) }
  let(:form) { Decidim::RegistrationForm.from_params(user: {}).with_context(current_organization: organization) }

  before do
    # helper for Decidim
    org = organization
    
    view.define_singleton_method(:current_organization) { org }
    view.define_singleton_method(:resource_name) { :user }
    view.define_singleton_method(:resource_class) { Decidim::User }
    view.define_singleton_method(:registration_path) { |*_args| "/users" }
    view.define_singleton_method(:devise_mapping) { Devise.mappings[:user] }
    view.define_singleton_method(:new_user_session_path) { "/login" }
    view.define_singleton_method(:form_required_explanation) { "" }
    view.define_singleton_method(:terms_of_service_summary_content_blocks) { [] }
    view.define_singleton_method(:page_path) { |*_args| "#" }
    view.define_singleton_method(:add_decidim_page_title) { |*_args| }
    view.define_singleton_method(:invisible_captcha) { "" }
    view.define_singleton_method(:normalize_provider_name) { |p| p }
    view.define_singleton_method(:icon) { |*_args| "" }
    view.define_singleton_method(:decidim_form_for) { |*args, &block| form_for(*args, &block) }
    view.define_singleton_method(:password_field_options_for) { |*_args| {} }
    view.define_singleton_method(:form_required_explanation) { "" }
    view.define_singleton_method(:invisible_captcha) { "" }

    # Mock omniauth buttons and links
    allow(view).to receive(:render).and_wrap_original do |m, *args, &block|
      if args.first == "decidim/devise/shared/omniauth_buttons" || args.first == "decidim/devise/shared/links"
        ""
      else
        m.call(*args, &block)
      end
    end
    
    assign(:form, form)
  end

  it "non espone il campo newsletter e lo imposta a 0" do
    render
    
    expect(rendered).to have_selector('input[name="user[newsletter]"][type="hidden"][value="0"]', visible: false)
    expect(rendered).not_to have_selector('input[name="user[newsletter]"][type="checkbox"]')
  end
end
