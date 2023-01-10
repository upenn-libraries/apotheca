# frozen_string_literal: true

# Model for an asynchronous item import.
class Import < ApplicationRecord
  include Queueable

  # This method will run the import and set the status of the import to a success or failure.
  def run
    raise '#run still needs to be implemented'
  end
end
