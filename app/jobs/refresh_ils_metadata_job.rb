# frozen_string_literal: true

# Job to refresh ILS metadata
class RefreshIlsMetadataJob < ApplicationJob
  def perform(item_id)
    RefreshIlsMetadata.new.call(id: item_id)
  end
end
