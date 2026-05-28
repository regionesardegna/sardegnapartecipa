# frozen_string_literal: true

Rake::Task["decidim:content_blocks:initialize_default_content_blocks"].clear

namespace :decidim do
  namespace :content_blocks do
    desc "Initializes content blocks using the exact manifest names for Decidim 0.28"
    task :initialize_default_content_blocks, [:space_id, :override, :custom_blocks, :include_components] => :environment do |_task, args|
      
      space_id = args[:space_id]&.to_i
      override_existing = args[:override].nil? ? true : args[:override] != "false"
      include_components = args[:include_components] == "true"

      # ---------------------------------------------------------------------
      # CONFIGURAZIONE CON I NOMI REALI DEI MANIFEST (DECIDIM 0.28)
      # ---------------------------------------------------------------------
      DEFAULT_BLOCKS = ["hero", "main_data", "extra_data", "related_documents"].freeze
      
      allowed_blocks = if args[:custom_blocks].present?
                         args[:custom_blocks].split(";").map(&:strip)
                       else
                         DEFAULT_BLOCKS
                       end
      
      TARGET_SCOPE = "participatory_process_homepage"

      puts "=== INIZIO RIGENERAZIONE CONTENT BLOCKS (MAPPATURA 0.28) ==="
      puts "Blocchi che verranno inseriti: #{allowed_blocks.join(', ')}"

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

        # Rimozione pulita dei vecchi blocchi (compresi quelli con i nomi errati)
        if existing_blocks_count > 0
          Decidim::ContentBlock.where(
            decidim_organization_id: process.decidim_organization_id,
            scope_name: TARGET_SCOPE,
            scoped_resource_id: process.id
          ).destroy_all
        end

        # Inserimento SQL pulito con i manifest corretti e il cast jsonb
        allowed_blocks.each_with_index do |block_name, index|
          weight = (index + 1) * 10
          now = Time.current.to_s(:db)

          query = <<-SQL
            INSERT INTO decidim_content_blocks 
            (decidim_organization_id, scope_name, scoped_resource_id, manifest_name, weight, settings, published_at, created_at, updated_at)
            VALUES 
            (#{process.decidim_organization_id}, '#{TARGET_SCOPE}', #{process.id}, '#{block_name}', #{weight}, '{}'::jsonb, '#{now}', '#{now}', '#{now}')
          SQL

          ActiveRecord::Base.connection.execute(query)
        end

        if include_components
          begin
            content_blocks_creator = Decidim::ContentBlocksCreator.new(process)
            content_blocks_creator.create_components_blocks!
          rescue => e
            puts "   -> [AVVISO] Impossibile creare i blocchi dei componenti: #{e.message}"
          end
        end

        creati = Decidim::ContentBlock.where(scoped_resource_id: process.id, scope_name: TARGET_SCOPE).order(:weight).map(&:manifest_name)
        puts "   -> Blocchi registrati nell'Admin: #{creati.join(', ')}"
      end

      puts "=== FINE PROCESSO ==="
    end
  end
end