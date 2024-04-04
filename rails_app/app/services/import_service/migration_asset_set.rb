# frozen_string_literal: true

module ImportService
  # Object containing the file location, metadata and structure for a set of assets. This class
  # is specifically tailored for the migration of assets.
  class MigrationAssetSet
    include Enumerable

    attr_reader :errors, :data, :skip_assets

    # Asset information when migrating assets should be provided in the following format:
    #   {
    #      storage: 'ceph',
    #      bucket: 'arkblahblah',
    #      arranged: [
    #        { filename: 'file1.tif', label: '1', path: 'file1.tif' },
    #        { filename: 'file2.tif', label: '2', path: 'file2.tif' }
    #      ],
    #      unarranged: [
    #        { filename: 'reference_shot.tif', path: 'reference_shot.tif' },
    #        { filename: 'reference_shot.jpg', path: 'reference_shot.jpg' }
    #      ],
    #      skip_assets: ['reference_shot.jpg']
    #   }
    #
    #   Bucket and storage keys should be provided as a top level key. Each file should contain the path of the file
    #   within the bucket.
    def initialize(skip_assets: [], **args)
      @skip_assets = skip_assets
      @data = args.deep_symbolize_keys.compact_blank # Store raw asset data provided.
      @errors = []
    end

    # Validate raw asset data provided.
    def valid?
      # Ensure all arranged/unarranged assets have a filename
      @errors << 'arranged assets missing data'   if data[:arranged] && !asset_valid?(data[:arranged])
      @errors << 'unarranged assets missing data' if data[:unarranged] && !asset_valid?(data[:unarranged])

      # Ensure at least one asset is defined
      unless %i[arranged unarragned].any? { |k| data.key?(k) }
        @errors << 'no assets defined'
      end

      @errors << 'asset storage name is blank' if data[:storage].blank?
      @errors << "assets storage invalid: '#{data[:storage]}'" if data[:storage].present? && !S3Storage.valid?(data[:storage])

      # Check that skipped assets are listed.
      all_filenames = data.fetch(:arranged, []).pluck(:filename) + data.fetch(:unarranged, []).pluck(:filename)
      missing = skip_assets - all_filenames
      @errors << "cannot skip assets that are not present: #{missing.join(', ')}" if missing.present?

      return false if errors.present?

      (data.fetch(:unarranged, []) + data.fetch(:arranged, [])).each do |a|
        @errors << "path invalid for #{a[:filename]}" unless storage.valid_path?(a[:path])
      end

      errors.empty?
    end

    def invalid?
      !valid?
    end

    def storage
      @storage ||= S3Storage.new(data[:storage], data[:bucket])
    end

    # Allow enumerating over all the asset data hashes.
    def each(&)
      all.each(&)
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
    # @return [TrueClass|FalseClass] whether all asset data hashes include a filename, path and checksum
    def asset_valid?(asset_data)
      asset_data.all? { |a| a.key?(:filename) && a.key?(:path) && a.key?(:checksum) }
    end

    # Creating AssetData objects for a given asset type.
    #
    # @param [Symbol] type of asset
    def asset_data_objects_for(type)
      if data.key?(type.to_sym)
        data[type.to_sym].reject { |a| skip_assets.include?(a[:filename]) }
                         .map { |a| asset_data_object(**a) }
      else
        []
      end
    end

    def asset_data_object(**attributes)
      metadata = attributes.deep_dup
      path = metadata.delete(:path)

      AssetData.new(
        file_location: FileLocation.new(storage: storage, path: path),
        **metadata
      )
    end
  end
end
