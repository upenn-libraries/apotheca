# frozen_string_literal: true

# job to perform and save a bulk export
class ProcessImportJob < ApplicationJob
  queue_as :default

  def perform(import)
    return if import.cancelled?

    import.process!
  end
end
