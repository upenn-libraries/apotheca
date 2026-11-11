# frozen_string_literal: true

module CSVImport
  class CreateResources
    # @param data [Hash] data in one row of the CSV import
    def call(data)
      # normalize data to a structure that is easier for us to manage
      # resolves the storage path for each file referenced
      # will return failure if it cannot normalize the data properly
      # tries to avoid validating the data
      # return new data structure
      data = step normalize(data)

      # data validation for the data provided by the user
      # returns new data?
      data = step validation(data)

      # create assets
      data = create_assets(data) # assets get added to data hash?

      # create item
      item = create_item(data, assets)

      # publish item, if requested
    end

    def normalize(data)
      Normalize.call(data)
    end
  end
end