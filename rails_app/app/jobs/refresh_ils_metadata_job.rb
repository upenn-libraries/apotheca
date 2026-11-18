# frozen_string_literal: true

# Job to refresh ILS metadata
class RefreshIlsMetadataJob < OperationJob
  sidekiq_options queue: :high

  def operation(item_id, updated_by)
    Item::RefreshIlsMetadata.call(item_id, updated_by)
  end
end
