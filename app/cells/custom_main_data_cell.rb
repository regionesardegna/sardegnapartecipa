
class CustomMainDataCell < Decidim::ParticipatoryProcesses::ContentBlocks::MainDataCell
  def show
    # 1. Recuperiamo l'HTML originale generato dinamicamente da Decidim
    html = super.to_s

    # 2. Generiamo il codice del pulsante Segui per il processo corrente
    follow_button = cell("decidim/follow_button", resource).to_s

    # 3. Usiamo una Regex per catturare l'H2 del titolo (qualsiasi testo contenga)
    #    \s*.*? significa: "prendi tutto il testo tradotto che c'è dentro"
    regex = /(<h2 class="h2 decorator">)(\s*.*?)(<\/h2>)/

    # 4. Sostituiamo dinamicamente iniettando il wrapper Flexbox di Tailwind
    html_modificato = html.gsub(regex) do |_match|
      testo_titolo = $2 # Recupera il testo originale del titolo (es. "Informazioni su questo processo")
      
      <<-HTML.strip_heredoc
        <div class="flex flex-col md:flex-row md:items-center md:justify-between gap-4 w-full mb-6 pb-4 border-b">
          <h2 class="h2 decorator" style="margin-bottom: 0 !important;">#{testo_titolo}</h2>
          <div class="main-data__actions">
            #{follow_button}
          </div>
        </div>
      HTML
    end

    html_modificato.html_safe
  end
end