# frozen_string_literal: true

module ImportService
  # Wrapper around S3 working storage.
  class S3Storage
    REQUIRED_CONFIG_KEYS = [:access_key_id, :secret_access_key, :endpoint, :region].freeze
    attr_reader :name

    def initialize(storage_name)
      @name = storage_name
      # TODO: Optional bucket param
    end

    def config
      @config ||= self.class.all[name]
    end

    def client
      @client ||= Aws::S3::Client.new(
        access_key_id: config[:access_key_id],
        secret_access_key: config[:secret_access_key],
        endpoint: config[:endpoint],
        region: config[:region],
        force_path_style: true
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
    # @return [Tempfile]
    def file(key)
      tempfile = Tempfile.new
      client.get_object({ bucket: bucket, key: key }, target: tempfile.path)

      File.new(tempfile: tempfile, key: key)
    end

    # Returns true if the given path exists within the bucket. Checks for valid filepaths and directories.
    def valid_path?(path)
      list = client.list_objects_v2(
        bucket: bucket,
        max_keys: 1,
        prefix: path
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

      loop do
        list = client.list_objects_v2(
          bucket: bucket, prefix: path, continuation_token: continuation_token
        )
        keys.concat(list.contents.map(&:key).delete_if { |k| k.delete_prefix(path).delete_prefix('/').include?('/') })
        continuation_token = list.next_continuation_token
        break unless list.is_truncated
      end

      keys
    end

    # Represents file retrieved from S3.
    #
    # Combines together a tempfile and other information about the file retrieved. This class
    # delegates most of its behavior to the tempfile and adds in some additional methods. Was
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
