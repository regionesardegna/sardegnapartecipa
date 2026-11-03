# frozen_string_literal: true

require "rails_helper"

module Decidim
  module AdminLog
    RSpec.describe Decidim::AdminLog::UserPresenter do
      subject { described_class.new(action_log, helper) }

      let(:helper) { double(:helper) }
      let(:action_log) do
        instance_double(
          Decidim::ActionLog,
          extra: { "user" => { "ip" => "192.168.1.50" } }
        )
      end

      context "quando l'IP è presente nell'hash extra" do
        it "restituisce l'indirizzo IP" do
          expect(subject.send(:ip)).to eq("192.168.1.50")
        end
      end

      context "quando la chiave 'user' o 'ip' non è presente" do
        let(:action_log) do
          instance_double(Decidim::ActionLog, extra: {})
        end

        it "restituisce una stringa vuota" do
          expect(subject.send(:ip)).to eq("")
        end
      end

      context "quando extra è nil" do
        let(:action_log) do
          instance_double(Decidim::ActionLog, extra: nil)
        end

        it "gestisce il nil senza sollevare eccezioni" do
          expect(subject.send(:ip)).to eq("")
        end
      end
    end
  end
end