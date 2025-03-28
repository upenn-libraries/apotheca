# frozen_string_literal: true

require './spec/support/valkyrie_persist_strategy'

namespace :apotheca do
  namespace :asset do
    desc 'Add dpi to technical metadata for all image assets without dpi'
    task add_dpi: :environment do
      query_service = Valkyrie::MetadataAdapter.find(:postgres).query_service
      assets = query_service.custom_queries.assets_without_dpi
      assets.each do |asset|
        AddDPI.new.call(id: asset.id.to_s, updated_by: Settings.system_user)
      rescue StandardError => e
        puts "Failed to add dpi to asset #{asset.id}. #{e.class}: #{e.message}"
      end
    end
  end
end
