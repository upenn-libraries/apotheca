# frozen_string_literal: true

# Job to change the state of a given Import to 'processing' if eligible
class ProcessImportJob
  include Sidekiq::Job

  sidekiq_options queue: :import_medium

  def perform(import_id)
    import = Import.find(import_id) # Will raise an error if missing.

    return if import.cancelled?

    import.process!
  end
end
