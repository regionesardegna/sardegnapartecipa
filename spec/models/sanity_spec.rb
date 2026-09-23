# frozen_string_literal: true

require "rails_helper"

RSpec.describe "RSpec Setup Sanity Check", type: :model do
  it "boots Rails test environment successfully" do
    expect(Rails.env).to eq("test")
  end

  it "creates a Decidim organization in the test database" do
    organization = create(:organization)
    expect(organization).to be_persisted
    expect(Decidim::Organization.exists?(organization.id)).to be(true)
  end

  it "creates a Decidim user in the test database" do
    organization = create(:organization)
    user = create(:user, organization: organization)
    expect(user).to be_persisted
    expect(user.organization).to eq(organization)
  end

  it "creates a participatory process using Decidim factories" do
    organization = create(:organization)
    process = create(:participatory_process, organization: organization)
    expect(process).to be_persisted
    expect(process.organization).to eq(organization)
  end
end
