# frozen_string_literal: true

module CSVImport
  class Normalize < Dry::Operation
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
    #     storage: 'key', # leave this in for validation
    #     paths: '', # leave this in for validation
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
      data = step normalize_metadata(data)

      # TODO: normalize asset data format
      data = step normalize_assets(data)

      # TODO: find each file in storage or have a separate step to do that?
      data = step locate_files(data)

      # TODO: if updating an item retrieve the current assets and match them with the asset data given?

      data
    end

    def normalize_metadata(data)
      data[:descriptive_metadata] = data.delete(:metadata)
      data[:structural_metadata] = data.delete(:structural)
      data[:publish] = data.fetch(:publish, 'false').casecmp('true').zero?

      Success(data)
    end

    def normalize_assets(data)
      return data if data[:assets].blank?

      # Can't provide arranged/unarranged keys with arranged_filename/unarranged_filename keys
      if (data[:arranged] || data[:unarranged]) && (data[:arranged_filenames] || data[:unarranged_filenames])
        return Failure('arranged_filenames/unarranged_filenames cannot be used in conjunction with arranged/unarranged keys')
      end

      [:arranged_filenames, :unarranged_filenames].each do |key|
        filenames = data[:assets].delete(key)
        next if filenames.blank?

        assets[key] = filenames.split(';').map(&:strip).map { |f| { filename: f } }
      end

      data
    end

    def locate_files(data)
      storage = WorkingStorage.find(data[:assets][:storage])

      return if storage.nil?

      paths = Array.wrap(data[:assets][:paths])

      searcher = storage.paths(paths)

      [:arranged, :unarranged].each do |key|
        assets[key].each do |asset|
          next unless asset[:filename]

          path = searcher.find(asset[:filename])

          asset[:key] = path
          asset[:storage] = storage.name
        end
      end
    end
  end
end