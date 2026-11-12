# frozen_string_literal: true

module CSVImport
  class Normalize < Operation
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
      data = step normalize_item(data)
      data = step normalize_assets(data)
      data = step locate_files(data)

      data
    end

    private

    # Normalize Item metadata and options
    def normalize_item(data)
      data[:descriptive_metadata] = data.delete(:metadata) if data[:metadata]
      data[:structural_metadata] = data.delete(:structural) if data[:metadata]
      data[:publish] = data.fetch(:publish, 'false').casecmp('true').zero?

      Success(data)
    end

    # Normalize Asset data to one data structure. Data can be provided in two formats.
    # TODO: copy over more documentation from original import service
    def normalize_assets(data)
      return data if data[:assets].blank?

      assets = data[:assets]

      # Can't provide arranged/unarranged keys with arranged_filename/unarranged_filename keys
      if (assets[:arranged] || assets[:unarranged]) && (assets[:arranged_filenames] || assets[:unarranged_filenames])
        # TODO: need to map this error in locales instead of inlining it.
        return Failure(error: :invalid_asset_structure, message: 'arranged_filenames/unarranged_filenames cannot be used in conjunction with arranged/unarranged keys')
      end

      [:arranged, :unarranged].each do |key|
        filenames = assets.delete(:"#{key}_filenames")
        next if filenames.blank?

        assets[key] = filenames.split(';').map(&:strip).map { |f| { filename: f } }
      end

      data[:assets] = assets

      Success(data)
    end


    # Find each file in storage if storage data is provided. Does not validate the storage or paths.
    def locate_files(data)
      storage = WorkingStorage.find(data[:assets][:storage])
      paths = Array.wrap(data[:assets][:paths])

      return Success(data) if storage.nil? || paths.blank?

      searcher = storage.paths(paths)

      [:arranged, :unarranged].each do |key|
        assets[key].each do |asset|
          next unless asset[:filename]

          path = searcher.find(asset[:filename])

          asset[:key] = path
          asset[:storage] = storage.name
        end
      end

      Success(data)
    end
  end
end