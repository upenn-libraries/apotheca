# frozen_string_literal: true

# Job to regenerate derivatives for all of an Item's child Assets and then publish the Item (which will also
# regenerates the IIIF manifest and PDF). Publish action to regenerate Item-level derivatives will
# only be run the Item has been previously published.
class GenerateAllDerivativesJob < TransactionJob
  include Sidekiq::Job

  sidekiq_options queue: :medium

  def transaction(item_id, updated_by)
    GenerateAllDerivatives.new.call(id: item_id, updated_by: updated_by)
  end
end
