# config/initializers/wicked_pdf.rb
if defined?(WickedPdf)
  module WickedPdf::WickedPdfHelper::Assets
    def self.propshaft_enabled?
      true
    end
  end
end
