# Copyright (C) 2024 Sardegna IT
# This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation, version 3.
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
# You should have received a copy of the GNU Affero General Public License along with this program. If not, see <https://www.gnu.org/licenses/>

# Modificata per integrare le nuove policies relative alla password in caso di registrazione su form
# aggiunti i seguenti metodi :no_capital_letters?, :no_lower_letters?, :no_numbers?, :no_symbols?
# in modo da rendere obbligatori almeno
# 12 caratteri minimo
# 1 maiuscola
# 1 minuscola
# 1 simbolo
# 1 numero

# frozen_string_literal: true

# Class is used to verify that the user's password is strong enough
class PasswordValidator < ActiveModel::EachValidator
  MINIMUM_LENGTH = 12 #originale 10
  MAX_LENGTH = 256
  MIN_UNIQUE_CHARACTERS = 5
  IGNORE_SIMILARITY_SHORTER_THAN = 4
  VALIDATION_METHODS = [
    :password_too_short?,
    :password_too_long?,
    :not_enough_unique_characters?,
    :name_included_in_password?,
    :nickname_included_in_password?,
    :email_included_in_password?,
    :domain_included_in_password?,
    :password_too_common?,
    :blacklisted?,
	:no_capital_letters?,
	:no_lower_letters?,
	:no_numbers?,
	:no_symbols?
  ].freeze

  # Check if user's password is strong enough
  #
  # record - Instance of a form (e.g. Decidim::RegistrationForm) or model
  # attribute - "password"
  # value - Actual password
  # Returns true if password is strong enough
  def validate_each(record, attribute, value)
    return false if value.blank?

    @record = record
    @attribute = attribute
    @value = value
    @weak_password_reasons = []

    return true if strong?

    @weak_password_reasons.each do |reason|
      record.errors[attribute] << get_message(reason)
    end

    false
  end

  private

  attr_reader :record, :attribute, :value

  def get_message(reason)
    I18n.t "password_validator.#{reason}"
  end

  def organization
    @organization ||= organization_from_record
  end

  def organization_from_record
    return record.current_organization if record.respond_to?(:current_organization)
    return record.organization if record.respond_to?(:organization)
  end

  def strong?
    VALIDATION_METHODS.each do |method|
      @weak_password_reasons << method.to_s.sub(/\?$/, "").to_sym if send(method.to_s)
    end

    @weak_password_reasons.empty?
  end

  def password_too_short?
    value.length < MINIMUM_LENGTH
  end

  def password_too_long?
    value.length > MAX_LENGTH
  end

  def not_enough_unique_characters?
    value.chars.uniq.length < MIN_UNIQUE_CHARACTERS
  end

  def name_included_in_password?
    return false if !record.respond_to?(:name) || record.name.blank?
    return true if value.include?(record.name.delete(" "))

    record.name.split(" ").each do |part|
      next if part.length < IGNORE_SIMILARITY_SHORTER_THAN

      return true if value.include?(part)
    end

    false
  end

  def nickname_included_in_password?
    return false if !record.respond_to?(:nickname) || record.nickname.blank?

    value.include?(record.nickname)
  end

  def email_included_in_password?
    return false if !record.respond_to?(:email) || record.email.blank?

    name, domain, _whatever = record.email.split("@")
    value.include?(name) || (domain && value.include?(domain.split(".").first))
  end

  def domain_included_in_password?
    return false unless organization && organization.host
    return true if value.include?(organization.host)

    organization.host.split(".").each do |part|
      next if part.length < IGNORE_SIMILARITY_SHORTER_THAN

      return true if value.include?(part)
    end

    false
  end

  def blacklisted?
    Array(Decidim.password_blacklist).each do |expression|
      return true if expression.is_a?(Regexp) && value.match?(expression)
      return true if expression.to_s == value
    end

    false
  end

  def password_too_common?
    Decidim::CommonPasswords.instance.passwords.include?(value)
  end
  
  def no_capital_letters?
	value.downcase == value
  end
  
  def no_lower_letters?
    value.upcase == value
  end
  
  def no_numbers?
    value.scan(/\d+/).empty?
  end
  
  def no_symbols?
	value.scan(/[!@#$%^&*()_+{}\[\]:;'"\/\\?><.,-]/).empty?
  end
end