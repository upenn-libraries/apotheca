# frozen_string_literal: true

# Job to refresh ILS metadata
class RefreshIlsMetadataJob
  include Sidekiq::Job

  sidekiq_options queue: :high

  def perform(item_id)
    RefreshIlsMetadata.new.call(id: item_id)
  end
end
