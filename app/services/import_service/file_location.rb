# frozen_string_literal: true

module ImportService
  # Class to represent where one file is stored.
  class FileLocation
    attr_reader :storage, :path

    def initialize(storage:, path:)
      @storage = storage
      @path = path
    end

    # Returns file.
    def file
      storage.file(path)
    end

    # Return checksum for file.
    def checksum_sha256
      storage.checksum_sha256(path)
    end
  end
end
