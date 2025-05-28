# frozen_string_literal: true

# Copyright (C) 2025 Sardegna IT
#
# This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation, version 3.
#
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License along with this program. If not, see <https://www.gnu.org/licenses/>

# Modificato per includere Decidim::FriendlySignup::AutoNickname per FriendlySignup

module Decidim
  # A form object used to fisnish signup from omniauth data
  class OmniauthRegistrationForm < Form
    include Decidim::FriendlySignup::AutoNickname
    mimic :user

    attribute :email, String
    attribute :name, String
    attribute :nickname, String
    attribute :provider, String
    attribute :uid, String
    attribute :tos_agreement, Boolean
    attribute :oauth_signature, String
    attribute :avatar_url, String
    attribute :raw_data, Hash

    validates :email, presence: true
    validates :name, presence: true
    validates :provider, presence: true
    validates :uid, presence: true

    def self.create_signature(provider, uid)
      Digest::MD5.hexdigest("#{provider}-#{uid}-#{Rails.application.secrets.secret_key_base}")
    end

    def normalized_nickname
      UserBaseEntity.nicknamize(nickname || name, organization: current_organization)
    end
  end
end