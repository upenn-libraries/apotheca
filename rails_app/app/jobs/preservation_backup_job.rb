# frozen_string_literal: true

# Job to backup preservation file to S3 storage.
class PreservationBackupJob < TransactionJob
  sidekiq_options queue: :low

  def transaction(asset_id)
    PreservationBackup.new.call(id: asset_id)
  end
end
