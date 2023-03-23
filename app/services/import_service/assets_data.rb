# frozen_string_literal: true

module ImportService
  # Object containing asset location, metadata and structure.
  class AssetsData
    attr_reader :errors, :data, :location

    delegate :file_for, to: :location

    # Asset information can be provided in different structures. Filenames and asset metadata can be
    # provided in two ways:
    #   1. { arranged: [ { filename: 'file1.tif', label: '1' }, { filename: 'file2.tif', label: '2' }],
    #        unarranged: [ { filename: 'reference_shot.tif' }] }
    #   2. { arranged_filenames: 'file1.tif;file2.tif', unarranged_filenames: 'reference_shot.tif' }
    #
    # File locations can be provided via :storage and :path keys:
    #   { storage: 'sceti-completed-n', path: 'object_3' }
    def initialize(**args)
      @data = args.deep_symbolize_keys.compact_blank # Store raw asset data provided.
      @location = AssetsLocation.new(**args)

      @errors = []
    end

    # Validate raw asset data provided.
    def valid?
      # Can't provide arranged/unarranged keys with arranged_filename/unarranged_filename keys
      if (data[:arranged] || data[:unarranged]) && (data[:arranged_filenames] || data[:unarranged_filenames])
        @errors << 'arranged_filenames/unarranged_filenames cannot be used in conjunction with arranged/unarranged keys'
      end

      # Ensure all arranged/unarranged assets have a filename
      @errors << 'arranged assets missing filename(s)'   if data[:arranged] && !filenames_present?(data[:arranged])
      @errors << 'unarranged assets missing filename(s)' if data[:unarranged] && !filenames_present?(data[:unarranged])

      # Ensure at least one asset is defined
      unless [:arranged_filenames, :unarranged_filenames, :arranged, :unarragned].any? { |k| data.key?(k) }
        @errors << 'no assets defined'
      end

      @errors.concat(location.errors) unless location.valid?

      errors.empty?
    end

    def all
      arranged + unarranged
    end

    def arranged
      @arranged ||= data_for(:arranged)
    end

    def unarranged
      @unarranged ||= data_for(:unarranged)
    end

    # Return any files that are not present in storage.
    def missing_files
      all_filenames = all.pluck(:original_filename)
      all_filenames - location.filenames
    end

    private

    # @param [Array<Hash>] asset_data
    # @return [TrueClass|FalseClass] whether all asset data hashes include a filename
    def filenames_present?(asset_data)
      asset_data.all? { |a| a.key?(:filename) }
    end

    # Extracts and normalizes the data for the given asset type.
    #
    # @param [Symbol] type of asset
    def data_for(type)
      if data.key?(:"#{type}_filenames")
        filenames = data[:"#{type}_filenames"]
        filenames.blank? ? [] : filenames.split(';').map(&:strip).map { |f| { original_filename: f } }
      elsif data.key?(type.to_sym)
        data[type.to_sym].map { |a| normalize_data(a) }
      else
        []
      end
    end

    # Convert asset data provided in CSV to the fields/format expected by the asset model.
    def normalize_data(asset)
      asset = asset.deep_dup
      asset[:original_filename] = asset.delete(:filename)
      asset[:annotations]       = asset.delete(:annotation)&.map { |t| { text: t } }
      asset[:transcriptions]    = asset.delete(:transcription)&.map { |t| { mime_type: 'text/plain', contents: t } }
      asset
    end
  end
end
