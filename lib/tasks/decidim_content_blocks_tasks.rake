# frozen_string_literal: true

Rake::Task["decidim:content_blocks:initialize_default_content_blocks"].clear

namespace :decidim do
  namespace :content_blocks do
    desc "Initializes content blocks writing directly via SQL to bypass gem manifest validations"
    task :initialize_default_content_blocks, [:space_id, :override, :custom_blocks, :include_components] => :environment do |_task, args|
      
      space_id = args[:space_id]&.to_i
      override_existing = args[:override].nil? ? true : args[:override] != "false"
      include_components = args[:include_components] == "true"

      # ---------------------------------------------------------------------
      # CONFIGURAZIONE DEI BLOCCHI RICHIESTI
      # ---------------------------------------------------------------------
      DEFAULT_BLOCKS = ["hero", "main_data", "timeline", "documents"].freeze
      
      allowed_blocks = if args[:custom_blocks].present?
                         args[:custom_blocks].split(";").map(&:strip)
                       else
                         DEFAULT_BLOCKS
                       end
      
      TARGET_SCOPE = "participatory_process_homepage"

      puts "=== INIZIO RIGENERAZIONE DIRETTA SQL CONTENT BLOCKS ==="
      puts "Configurazione -> Override: #{override_existing} | Blocchi richiesti: #{allowed_blocks.join(', ')}"

      processes = if space_id.present?
                    Decidim::ParticipatoryProcess.where(id: space_id)
                  else
                    Decidim::ParticipatoryProcess.all
                  end

      if processes.empty?
        puts "Nessun processo trovato con i filtri forniti."
        next
      end

      processes.each do |process|
        puts "Elaborazione Processo ID: #{process.id} - Titolo: #{process.title['it'] || process.title.values.first}"

        existing_blocks_count = Decidim::ContentBlock.where(
          scope_name: TARGET_SCOPE,
          scoped_resource_id: process.id
        ).count

        if existing_blocks_count > 0 && !override_existing
          puts "   -> [SALTATO] Il processo ha già #{existing_blocks_count} blocchi esistenti (override = false)."
          next
        end

        # 1. Pulizia preventiva sul database
        if existing_blocks_count > 0
          deleted_count = Decidim::ContentBlock.where(
            decidim_organization_id: process.decidim_organization_id,
            scope_name: TARGET_SCOPE,
            scoped_resource_id: process.id
          ).destroy_all.count
          puts "   -> Rimossi #{deleted_count} vecchi blocchi."
        end

        # 2. Prepariamo l'array di hash per la scrittura diretta in SQL
        blocks_to_insert = allowed_blocks.map.with_index do |block_name, index|
          {
            decidim_organization_id: process.decidim_organization_id,
            scope_name: TARGET_SCOPE,
            scoped_resource_id: process.id,
            manifest_name: block_name,
            weight: (index + 1) * 10,
            published_at: Time.current,
            created_at: Time.current,
            updated_at: Time.current
          }
        end

        # 3. Scrittura di massa a database bypassando i modelli ActiveRecord (Zero callback, zero crash)
        if blocks_to_insert.any?
          Decidim::ContentBlock.insert_all!(blocks_to_insert)
        end

        # 4. Gestione opzionale dei componenti (se richiesto dall'utente)
        if include_components
          begin
            content_blocks_creator = Decidim::ContentBlocksCreator.new(process)
            content_blocks_creator.create_components_blocks!
          rescue => e
            puts "   -> [AVVISO] Impossibile creare i blocchi dei componenti: #{e.message}"
          end
        end

        # 5. Verifica finale leggendo l'esatto stato del database
        creati = Decidim::ContentBlock.where(scoped_resource_id: process.id, scope_name: TARGET_SCOPE).order(:weight).map(&:manifest_name)
        puts "   -> Nuovi blocchi salvati a DB: #{creati.join(', ')}"
      end

      puts "=== FINE PROCESSO ==="
    end
  end
end