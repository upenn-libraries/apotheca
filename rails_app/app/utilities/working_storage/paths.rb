class WorkingStorage
  # Represents multiple filepaths in S3. Used to find a file within a set of paths.
  class Paths
    # @param storage [WorkingStorage]
    # @param paths [Array<String>]
    def initialize(storage, paths)
      @storage = storage
      @paths = paths.map { |p| storage.path(p) }
    end

    # @return [Hash]
    def directory
      @directory = paths.sum(&:filenames).group_by { |f| File.basename(f) }
    end

    # Files that are located in multiple paths.
    #
    # @return [Array<String>]
    def duplicates
      directory.select { |_, v| v.length > 1 }.keys
    end

    # Finds file.
    #
    # @param filename [String]
    # @return [nil] if file located in more than one place or none was located
    # @return [String] path/key to file if it was found
    def find(filename)
      directory[filename].length == 1 ? directory[filenames].first : nil
    end
  end
end