module DerivativeService
  module Asset
    # Wrapper around Valkyrie::StorageAdapter::StreamFile that creates a Tempfile if access to a file on
    # the filesystem is required.
    #
    # Note: The current `Valkyrie::StorageAdapter::StreamFile` does provide a way to generate a tmpfile, but does not
    #       provide an easy way to clean it up.
    class SourceFile
      # @param file [Valkyrie::StorageAdapter::StreamFile]
      def initialize(file)
        @file = file
      end

      def read
        @file.rewind # Always rewind before reading.
        @file.read
      end

      # Creates a Tempfile that can be used by processes that require a file to be present in the filesystem.
      #
      # Requires that a block be provided to use the temp file. The block is invoked with the filepath and ensures
      # that the Tempfile is cleaned up after it is used. The call returns the value of the block.
      #
      # @example
      #   f = DerivativeService::Asset::SourceFile.new(file)
      #   f.tmp_file do |path|
      #     # processing of tempfile at path
      #   end
      def tmp_file
        @file.rewind

        Tempfile.create('derivative-source-file-') do |t|
          IO.copy_stream(@file.io, t)
          yield(t.path)
        end
      end
    end
  end
end
