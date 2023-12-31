# frozen_string_literal: true

module Steps
  # Sets updated by to the same as created_by. To be used when creating a resource.
  class SetUpdatedBy
    include Dry::Monads[:result]

    def call(change_set)
      change_set.updated_by = change_set.created_by if change_set.updated_by.blank?

      Success(change_set)
    end
  end
end
