# frozen_string_literal: true

module DerivativeService
  module Generator
    # Super class from which all Generator classes should inherit from.
    class Base
      # @param file [Valkyrie::StorageAdapter::StreamFile] # TODO: or file-like object that responds, to #read, #rewind and #disk_path
      def initialize(file)
        @file = file
      end

      def file
        @file.rewind # Ensure file is rewinded before reading
        @file
      end

      def thumbnail
        raise NotImplementedError
      end

      def access
        raise NotImplementedError
      end
    end
  end
end
