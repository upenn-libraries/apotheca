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

    desc 'Regenerate derivatives for video assets'
    task regenerate_derivative_for_video: :environment do
      query_service = Valkyrie::MetadataAdapter.find(:postgres).query_service

      # Query for all video assets
      video_mime_types = DerivativeService::Asset::Generator::Video::VALID_MIME_TYPES
      video_assets = query_service.custom_queries.assets_by_mime_types(*video_mime_types)

      # Enqueue job to regenerate derivatives for all video assets
      video_assets.each do |asset|
        GenerateDerivativesJob.perform_async(asset.id.to_s, Settings.system_user)
      end
    end
  end
end
