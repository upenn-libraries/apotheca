# frozen_string_literal: true

class PreservationBackupJob < ApplicationJob
  def perform(asset_id)
    PreservationBackup.new.call(id: asset_id)
  end
end
