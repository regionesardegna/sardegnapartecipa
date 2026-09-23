# frozen_string_literal: true

require "factory_bot"

FactoryBot.modify do
  factory :organization do
    reference_prefix { "ORG" }
  end

  factory :user do
    password { "Decidim123456789!" }
    password_confirmation { "Decidim123456789!" }
  end
end
