# frozen_string_literal: true

module CSVImport
  class Validate < Dry::Operation
    skip_prepending

    # CSV data validator
    ##### for now only focusing on :create
    # Open question: how would we do this for :update? how to we share among the two?
    class CreateContract < Dry::Validation::Contract
      schema do
        required(:action).value(included_in?: [:create, :update])
        required(:imported_by).filled(:string)
        optional(:unique_identifier).filled(:string) # or uuid if action == :update
        required(:human_readable_name).filled(:string)

        required(:descriptive_metadata).filled(:hash) # todo: should return error as "metadata"

        # optional(:published) # TODO: needs to be a boolean
        # TODO: check bibnumber is value
        # TODO: check asset data structure
        # TODO: ensure some metadata is present
      end

      rule(:unique_identifier) do
        item = Query.postgres.custom_queries.find_by_unique_identifier(unique_identifier: value)
        key.failure('already assigned to an item') if item
        # todo: check ark is minted and not assigned to an item
      end
    end

    def call(data)
      result = CreateContract.new.call(data)

      if result.success?
        Success(data)
      else
        # todo: could probably use a better way to retrieve the detailed messages
        Failure(error: :validation_error, details: result.errors(full: true).to_h.values.flatten)
      end
    end
  end
end