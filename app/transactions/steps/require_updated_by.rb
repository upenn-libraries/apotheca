# frozen_string_literal: true

module Steps
  # Required that updated_by attribute is provided.
  class RequireUpdatedBy
    include Dry::Monads[:result]

    def call(attributes)
      if attributes[:updated_by].blank?
        Failure(error: :missing_updated_by)
      else
        Success(attributes)
      end
    end
  end
end
