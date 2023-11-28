# frozen_string_literal: true

# Job to generate or regenerate derivatives for an asset.
class GenerateDerivativesJob < TransactionJob
  sidekiq_options queue: :high

  def transaction(asset_id, updated_by)
    GenerateDerivatives.new.call(id: asset_id, updated_by: updated_by)
  end
end
