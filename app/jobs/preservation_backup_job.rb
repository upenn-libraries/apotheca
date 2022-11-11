# frozen_string_literal: true

# Job to backup preservation file to S3 storage.
class PreservationBackupJob < ApplicationJob
  def perform(asset_id)
    PreservationBackup.new.call(id: asset_id)
  end
end
