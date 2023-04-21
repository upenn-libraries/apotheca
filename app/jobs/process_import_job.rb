# frozen_string_literal: true

# Job to change the state of a given Import to 'processing' if eligible
class ProcessImportJob < ApplicationJob
  queue_as :default

  def perform(import)
    return if import.cancelled?

    import.process!
  end
end
