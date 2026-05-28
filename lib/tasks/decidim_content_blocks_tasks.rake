# frozen_string_literal: true

Rake::Task["decidim:content_blocks:initialize_default_content_blocks"].clear

namespace :decidim do
  namespace :content_blocks do
    desc "Initializes content blocks by injecting clean JSON structures to prevent to_h string crashes"
    task :initialize_default_content_blocks, [:space_id, :override, :custom_blocks, :include_components] => :environment do |_task, args|
      
      space_id = args[:space_id]&.to_i
      override_existing = args[:override].nil? ? true : args[:override] != "false"
      include_components = args[:include_components] == "true"

      DEFAULT_BLOCKS = ["hero", "main_data", "timeline", "documents"].freeze
      
      allowed_blocks = if args[:custom_blocks].present?
                         args[:custom_blocks].split(";").map(&:strip)
                       else
                         DEFAULT_BLOCKS
                       end
      
      TARGET_SCOPE = "participatory_process_homepage"

      puts "=== INIZIO RIGENERAZIONE CONTENT BLOCKS (FIX SETTINGS) ==="

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
          puts "   -> [SALTATO] Il processo ha già #{existing_blocks_count} blocchi esistenti."
          next
        end

        # 1. Pulisce i vecchi record corrotti
        if existing_blocks_count > 0
          Decidim::ContentBlock.where(
            decidim_organization_id: process.decidim_organization_id,
            scope_name: TARGET_SCOPE,
            scoped_resource_id: process.id
          ).destroy_all
        end

        # 2. Inserimento tramite SQL nativo standardizzato per evitare i filtri dei modelli
        allowed_blocks.each_with_index do |block_name, index|
          weight = (index + 1) * 10
          now = Time.current.to_s(:db)

          # Eseguiamo una query nativa. Usiamo lo sdoppiamento di apici o l'hash vuoto
          # che Postgres digerisce come tipo JSON nativo.
          query = <<-SQL
            INSERT INTO decidim_content_blocks 
            (decidim_organization_id, scope_name, scoped_resource_id, manifest_name, weight, settings, published_at, created_at, updated_at)
            VALUES 
            (#{process.decidim_organization_id}, '#{TARGET_SCOPE}', #{process.id}, '#{block_name}', #{weight}, '{}'::jsonb, '#{now}', '#{now}', '#{now}')
          SQL

          ActiveRecord::Base.connection.execute(query)
        end

        # 3. Componenti opzionali
        if include_components
          begin
            content_blocks_creator = Decidim::ContentBlocksCreator.new(process)
            content_blocks_creator.create_components_blocks!
          rescue => e
            puts "   -> [AVVISO] Impossibile creare i blocchi dei componenti: #{e.message}"
          end
        end

        creati = Decidim::ContentBlock.where(scoped_resource_id: process.id, scope_name: TARGET_SCOPE).order(:weight).map(&:manifest_name)
        puts "   -> Nuovi blocchi salvati: #{creati.join(', ')}"
      end

      puts "=== FINE PROCESSO ==="
    end
  end
end