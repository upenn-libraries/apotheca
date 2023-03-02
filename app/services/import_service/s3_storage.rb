# frozen_string_literal: true

module ImportService
  # Wrapper around S3 digitization storage.
  class S3Storage
    attr_reader :name

    def initialize(storage_name) # TODO: optional bucket param
      @name = storage_name
    end

    def config
      @config ||= self.class.all[name]
    end

    def client
      @client ||= Aws::S3::Client.new(
        access_key_id: config[:access_key_id],
        secret_access_key: config[:secret_access_key],
        endpoint: config[:endpoint],
        region: 'us-east-1', # using default region
        force_path_style: true
      )
    end

    # Bucket name.
    #
    # @return [String] bucket name
    def bucket
      @bucket ||= config[:bucket]
    end

    # @return [StringIO]
    def file(key)
      client.get_object(bucket: bucket, key: key).body # TODO: reading into memory, probably want to read into a temp file
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

    # Returns true if the given store is configured.
    def self.valid?(storage_name)
      all.key?(storage_name) && [:access_key_id, :secret_access_key, :endpoint].all? { |k| all[storage_name][k].present? }
    end

    # Returns all configured digitization stores.
    def self.all
      Settings.digitization_storage.to_h.with_indifferent_access
    end
  end
end
