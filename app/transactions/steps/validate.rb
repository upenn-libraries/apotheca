# frozen_string_literal: true

module Steps
  # Validates ChangeSet.
  class Validate
    include Dry::Monads[:result]

    def call(change_set)
      if change_set.valid?
        Success(change_set)
      else
        Failure([:validation_failed, change_set.errors])
      end
    end
  end
end
