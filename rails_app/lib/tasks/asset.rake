# frozen_string_literal: true

require './spec/support/valkyrie_persist_strategy'

namespace :apotheca do
  namespace :asset do
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
