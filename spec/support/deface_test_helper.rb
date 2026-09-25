# spec/support/deface_test_helper.rb
require 'deface'

RSpec.configure do |config|
  config.before(:each) do
    # Deface deve essere caricato dall'ambiente Rails
    if defined?(Deface)
      puts "DEBUG: Deface è definito"
      # Deface::Config.disabled = false
      # Deface::Override.all.clear
      # Deface::DSL::Loader.load_arguments
    else
      puts "DEBUG: Deface non è definito"
    end
  end
end
