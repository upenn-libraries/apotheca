# frozen_string_literal: true

module CSVImport
  module Steps
    class Normalize

      # {
      #   action: 'update',
      #   publish: true,
      #   human_readable_name: '',
      #   unique_identifier: '',
      #   descriptive_metadata: {
      #     title: {},
      #     bibnumber: {}
      #   },
      #   structural_metadata: {
      #     viewing_direction: '',
      #   },
      #   internal_notes: [],
      #   assets: {
      #     storage: 'key', # this will be removed as part of normalization
      #     paths: '', # this will be removed as part of normalization
      #     arranged: [
      #       {
      #         file: object,
      #         annotations: {},
      #         label: {}, # other metadata
      #         id: '' # if updating asset
      #       }
      #     ],
      #     unarranged: [{}]
      #   }
      # }

      def call(data)

        data[:descriptive_metadata] = data.delete(:metadata)

        # TODO: normalize asset data format
        # TODO: find each file in storage or have a separate step to do that?

        Success(data)
      end


    end
  end
end