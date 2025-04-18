# frozen_string_literal: true

module ImportService
  # Wrapper around S3 working storage.
  class S3Storage
    REQUIRED_CONFIG_KEYS = %i[access_key_id secret_access_key region].freeze

    attr_reader :name

    delegate :client, to: :shrine

    def initialize(storage_name, bucket = nil)
      @name = storage_name
      @bucket = bucket
    end

    def config
      @config ||= self.class.all[name].to_h.deep_symbolize_keys
    end

    def shrine
      @shrine ||= Shrine::Storage::S3.new(
        bucket: bucket, **config.except(:bucket)
      )
    end

    # Bucket name.
    #
    # @return [String] bucket name
    def bucket
      @bucket ||= config[:bucket]
    end

    # Returns file at the given location.
    #
    # Using Shrine's open method is more efficient for downloading a file in AWS.
    #
    # @return [ImportService::S3Storage::File]
    def file(key)
      tempfile = Tempfile.new(binmode: true)
      io = shrine.open(key, rewindable: false)
      io.each_chunk { |chunk| tempfile.write(chunk) }
      io.close
      tempfile.rewind

      File.new(tempfile: tempfile, key: key) # TODO: We might want to think about caching this
    end

    # Returns the sha256 checksum for a file at the given location. AWS S3 does not automatically calculate
    # checksums, so we will be calculating them manually as needed.
    #
    # @param [String] key
    # @return [String] sha256 checksum
    def checksum_sha256(key)
      io = shrine.open(key, rewindable: false) # Using Shrine's open method to fetch file in chunks.

      checksum = Digest::SHA256.new
      io.each_chunk { |chunk| checksum.update(chunk) }
      io.close

      checksum
    end

    # Returns true if the given path exists within the bucket. Checks for valid filepaths and directories.
    def valid_path?(path)
      list = client.list_objects_v2(
        bucket: bucket,
        max_keys: 1,
        prefix: modify_path(path)
      )
      list.key_count == 1
    end

    # Returns all the files available at the given path. Ignores subdirectories.
    #
    # @param [String] path
    # @return [Array<String>]
    def files_at(path)
      keys = []
      continuation_token = nil
      modified_path = modify_path(path)

      loop do
        list = client.list_objects_v2(
          bucket: bucket, prefix: modified_path, continuation_token: continuation_token
        )
        new_keys = keys_for_display(modified_path, list)
        keys.concat(new_keys)
        continuation_token = list.next_continuation_token
        break unless list.is_truncated
      end

      keys
    end

    # Mimics a file directory structure in S3 by normalizing the path. This method assumes that all files have
    # extensions. Removes / at the beginning, adds / to the end.  Always remove / at the beginning of the string, but
    # return if the string is a filename. This regular expression matches a string if it contains a period (.) followed
    # by one or more characters that are not slashes (/) until the end of the string.
    #
    # @param [String] path
    # @return [String]
    def modify_path(path)
      path = path.delete_prefix('/')
      return path if %r{\.[^/]+$}.match?(path)

      path += '/' if path.present? && !path.end_with?('/')
      path
    end

    # Remove top level directory, any subdirectories, and dotfiles from the display list.
    #
    # @param [String] path
    # @param [Hash] files
    # @return [Array]
    def keys_for_display(path, files)
      files.contents.map(&:key).delete_if do |k|
        (k == path && k.ends_with?('/')) ||
          k.delete_prefix(path).include?('/') ||
          k.delete_prefix(path).starts_with?('.')
      end
    end

    # Represents file retrieved from S3.
    #
    # Combines together a Tempfile object and other information about the file retrieved. This class
    # delegates most of its behavior to the Tempfile object and adds in some additional methods. Was
    # inspired by ActionDispatch::Http::UploadedFile.
    class File
      attr_reader :tempfile, :key

      delegate_missing_to :tempfile

      def initialize(tempfile:, key:)
        @tempfile = tempfile
        @key = key
      end

      def original_filename
        key.split('/').last
      end
    end

    # Returns true if the given store is configured.
    def self.valid?(storage_name)
      all.key?(storage_name) && REQUIRED_CONFIG_KEYS.all? { |k| all[storage_name][k].present? }
    end

    # Returns all configured working storage buckets.
    def self.all
      Settings.working_storage.to_h.with_indifferent_access
    end
  end
end
