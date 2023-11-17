# frozen_string_literal: true

module ImportService
  # Object containing the file location, metadata and structure for a set of assets
  class AssetSet
    include Enumerable

    attr_reader :errors, :data, :file_locations

    # Asset information can be provided in different structures. Filenames and asset metadata can be
    # provided in two ways:
    #   1. { arranged: [ { filename: 'file1.tif', label: '1' }, { filename: 'file2.tif', label: '2' }],
    #        unarranged: [ { filename: 'reference_shot.tif' }] }
    #   2. { arranged_filenames: 'file1.tif;file2.tif', unarranged_filenames: 'reference_shot.tif' }
    #   3. { structural: [{ filename: 'file1.tif', label: '1' }, { filename: 'file2.tif', label: '2'}] }
    #
    # File locations can be provided via :storage and :path keys:
    #   { storage: 'sceti-completed-n', path: 'object_3' }
    def initialize(**args)
      @data = args.deep_symbolize_keys.compact_blank # Store raw asset data provided.
      @file_locations = args.key?(:path) || args.key?(:storage) ? FileLocations.new(**args) : nil

      @errors = []
    end

    # Validate raw asset data provided.
    def valid?
      # Can't provide arranged/unarranged keys with arranged_filename/unarranged_filename keys
      if (data[:arranged] || data[:unarranged]) && (data[:arranged_filenames] || data[:unarranged_filenames])
        @errors << 'arranged_filenames/unarranged_filenames cannot be used in conjunction with arranged/unarranged keys'
      end

      # arranged_filename/unarranged_filename or arranged/unarranged keys can't be present when using asset spreadsheet
      if data[:spreadsheet] && (asset_data_in_array? || asset_data_in_string?)
        @errors << '(arranged/unarranged)_filename or arranged/unarranged keys used alongside asset spreadsheet'
      end

      # Ensure all arranged/unarranged assets have a filename
      @errors << 'arranged assets missing filename(s)'   if data[:arranged] && !filenames_present?(data[:arranged])
      @errors << 'unarranged assets missing filename(s)' if data[:unarranged] && !filenames_present?(data[:unarranged])

      # Ensure every row of asset spreadsheet has a filename
      @errors << 'asset filename(s) missing' if data[:spreadsheet] && !filenames_present?(data[:spreadsheet])

      # Ensure at least one asset is defined
      unless %i[arranged_filenames unarranged_filenames arranged unarragned spreadsheet].any? { |k| data.key?(k) }
        @errors << 'no assets defined'
      end

      @errors.concat(file_locations.errors) if file_locations&.invalid?

      errors.empty?
    end

    def invalid?
      !valid?
    end

    # Allow enumerating over all the asset data hashes.
    def each(&)
      all.each(&)
    end

    def file_locations?
      file_locations.present?
    end

    def all
      arranged + unarranged
    end

    def arranged
      @arranged ||= asset_data_objects_for(:arranged)
    end

    def unarranged
      @unarranged ||= asset_data_objects_for(:unarranged)
    end

    private

    # @param [Array<Hash>] asset_data
    # @return [TrueClass|FalseClass] whether all asset data hashes include a filename
    def filenames_present?(asset_data)
      asset_data.all? { |a| a.key?(:filename) }
    end

    # Creating AssetData objects for a given asset type.
    #
    # @param [Symbol] type of asset
    def asset_data_objects_for(type)
      if data.key?(:"#{type}_filenames")
        filenames = data[:"#{type}_filenames"]
        filenames.blank? ? [] : filenames.split(';').map(&:strip).map { |f| asset_data_object(filename: f) }
      elsif data.key?(type.to_sym)
        data[type.to_sym].map { |a| asset_data_object(**a) }
      elsif data.key?(:spreadsheet)
        asset_data_from_spreadsheet(type)
      else
        []
      end
    end

    def asset_data_object(**attributes)
      metadata = attributes.deep_dup

      AssetData.new(
        file_location: file_locations&.file_location_for(metadata[:filename]),
        **metadata
      )
    end

    # @return [Array<ImportService::AssetData>]
    def asset_data_from_spreadsheet(type)
      sequence_criteria = {
        arranged: ->(a) { a[:sequence].present? },
        unarranged: ->(a) { a[:sequence].blank? }
      }

      selected_data = data[:spreadsheet].select(&sequence_criteria[type.to_sym])

      sorted_data = type == :arranged ? selected_data.sort_by { |a| a[:sequence].to_i } : selected_data

      sorted_data.map { |a| asset_data_object(**a.except(:sequence)) }
    end

    def asset_data_in_array?
      data[:arranged] || data[:unarranged]
    end

    def asset_data_in_string?
      data[:arranged_filenames] || data[:unarranged_filenames]
    end
  end
end
