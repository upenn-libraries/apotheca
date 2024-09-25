# frozen_string_literal: true

# Job to backup preservation file to S3 storage.
class PreservationBackupJob < TransactionJob
  sidekiq_options queue: :low

  def transaction(asset_id, updated_by)
    result = PreservationBackup.new.call(id: asset_id, updated_by: updated_by)
    # We return a success here if the asset resource is not found to avoid retrying the job,
    # since the asset will never be found
    if result.failure? && result.failure[:error] == :resource_not_found
      return Dry::Monads::Success("Asset #{asset_id} not found.")
    end

    result
  end
end
