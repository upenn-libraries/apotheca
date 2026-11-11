# frozen_string_literal: true

module CSVImport
  class CreateResources
    # @param data [Hash] data in one row of the CSV import
    def call(data)
      # "basic" data validation for the data provided by the user
      # does not resolve file locations or do any really computationally intensive tasks, but does do lookups
      # returns new data?
      data = step validation(data)

      # normalize data to a structure that is easier for us to manage
      # resolves the storage path for each file referenced
      # will return failure if it cannot normalize the data properly
      # tries to avoid validating the data
      # return new data structure
      data = step normalize(data)

      # Full validation of data, tried to catch any issues before starting to create the resources.
      # Mainly this would be to validate that all the assets are present and any other checks
      # that could not be done until this point.
      data = step other_validations(data) # check_filepaths (might be a more appropriate name)

      # create assets
      data = create_assets(data) # assets get added to data hash?

      # create item
      item = create_item(data, assets)

      # publish item, if requested
    end
  end
end