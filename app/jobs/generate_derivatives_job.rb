# frozen_string_literal: true

# Job to generate or regenerate derivatives for an asset.
class GenerateDerivativesJob < ApplicationJob
  def perform(asset_id)
    GenerateDerivatives.new.call(id: asset_id)
  end
end
