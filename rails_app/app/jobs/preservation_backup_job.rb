# frozen_string_literal: true

# Job to backup preservation file to S3 storage.
class PreservationBackupJob < OperationJob
  sidekiq_options queue: :low

  def operation(asset_id, updated_by)
    result = Asset::PreservationBackup.call(asset_id, updated_by)
    # We return a success here if the asset resource is not found to avoid retrying the job,
    # since the asset will never be found
    if result.failure? && result.failure[:error] == :resource_not_found
      return Dry::Monads::Success("Asset #{asset_id} not found.")
    end

    result
  end
end
