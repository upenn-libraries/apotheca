class WorkingStorage
  # Represents a path in S3. Can be a path to a file or a directory.
  #
  # @use storage = WorkingStorage.new('sceti')
  #      path = storage.path('/very-important/folder')
  #      path.valid?
  class Path
    attr_reader :storage, :path

    delegate :client, to: :storage

    # @param storage [WorkingStorage]
    # @param path [String]
    def initialize(storage, path)
      @storage = storage
      @path = path
    end

    # Check if path is valid.
    #
    # TODO: check if this is the desired behavior:
    #   This will return true even if files aren't present at this exact directory. There could be files lower down the tree
    #
    def valid? # TODO: or empty?
      list = client.list_objects_v2(
        bucket: bucket,
        max_keys: 1,
        prefix: normalized_path
      )
      list.key_count.one?
    end

    # Returns all the S3 keys at the given path. Does not follow subdirectories. Includes files, dotfiles,
    # subdirectories, and the original path itself.
    #
    # @return [Array<String>]
    def keys
      keys = []
      continuation_token = nil

      loop do
        list = client.list_objects_v2(
          bucket: bucket, prefix: normalized_path, continuation_token: continuation_token
        )
        keys.concat(list.contents.map(&:key))
        continuation_token = list.next_continuation_token
        break unless list.is_truncated
      end

      keys
    end

    # File paths for files present at this path. Assumes a key is a file if it has a file extension. Does not
    # follow subdirectories and does not include dotfiles.
    #
    # TODO: not sure if this is something that is needed
    # @return [Array<String]
    def filepaths
      keys.delete_if do |k|
        (k == path && k.ends_with?('/')) ||
          k.delete_prefix(path).include?('/') ||
          k.delete_prefix(path).starts_with?('.')
      end
    end

    # Filenames for all files present at this path. Assumes a key is a file if it has a file extension. Does not
    # follow subdirectories and does not include dotfiles.
    #
    # @return [Array<String>]
    def filenames
      filepaths.map { |f| File.basename(f) }
    end

    # Remove top level directory, any subdirectories, and dotfiles from the display list.
    #
    # @param [String] path
    # @param [Hash] files
    # @return [Array]
    # def keys_for_display(path, files)
    #   files.contents.map(&:key).delete_if do |k|
    #     (k == path && k.ends_with?('/')) ||
    #       k.delete_prefix(path).include?('/') ||
    #       k.delete_prefix(path).starts_with?('.')
    #   end
    # end

    private

    # Mimics a file directory structure in S3 by normalizing the path.
    #
    # @return [String]
    def normalize_path
      @normalized_path ||= create_normalized_path
    end

    # Generates normalized path for S3. This method assumes that all files have extensions.
    # Removes / at the beginning. Adds / to the end if it's a directory.
    #
    # @return [String]
    def create_normalized_path
      path = path.delete_prefix('/')
      return path if %r{\.[^/]+$}.match?(path)

      path += '/' if path.present? && !path.end_with?('/')
      path
    end
  end
end