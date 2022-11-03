# frozen_string_literal: true

class GenerateDerivativesJob < ApplicationJob
  def perform(asset_id)
    GenerateDerivatives.new.call(id: asset_id)
  end
end