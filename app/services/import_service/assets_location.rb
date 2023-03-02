# frozen_string_literal: true

module ImportService
  # Class to aggregate all the files available at the given storage locations.
  class AssetsLocation
    attr_reader :storage_name, :paths, :errors

    def initialize(options = {})
      options = options.deep_symbolize_keys

      @storage_name = options[:storage]
      @paths = Array.wrap(options[:path]).compact_blank!

      @errors = []
    end

    # Check that the configuration contains all the necessary
    # information. This does not check the validity of the paths
    def valid?
      @errors << "assets storage invalid: '#{storage_name}'" if storage_name && !S3Storage.valid?(storage_name)
      @errors << 'assets must contain at least one path' if paths.empty?

      # TODO: might want an error that list the invalid paths
      @errors << 'asset path invalid' unless valid_paths?

      if valid_paths?
        dups = duplicate_filenames
        @errors << "duplicate filenames found in storage location: #{dups.join(', ')}" if dups.present?
      else
        @errors << 'asset path invalid'
      end

      errors.empty?
    end

    def storage
      @storage ||= S3Storage.new(storage_name)
    end

    # Checks that the given paths are valid paths.
    #
    # @return [FalseClass] if there are no assets paths or if one of them is invalid
    # @return [TrueClass] if there are asset paths present and they are all valid
    def valid_paths?
      !paths.empty? && paths.all? { |p| storage.valid_path?(p) }
    end

    # Returns all the filenames available.
    def filenames
      file_locations.keys
    end

    def file_for(filename)
      storage.file(file_locations[filename])
    end

    private

    def all_filepaths
      @all_filepaths ||= paths.map { |path| storage.files_at(path) }.flatten
    end

    # Mapping of filename to filepath (s3 key).
    #
    # @return [Hash<String, String>]
    def file_locations # TODO: need to check for duplicate filenames
      @file_locations ||= all_filepaths.index_by { |path| path.split('/').last }
    end

    # List any duplicate files present in any of the storage locations.
    #
    # @return [Array<String>] list of duplicate filenames duplicate filenames
    def duplicate_filenames
      all_filenames = all_filepaths.map { |path| path.split('/').last }
      all_filenames.select { |f| all_filenames.count(f) > 1 }.uniq
    end
  end
end


