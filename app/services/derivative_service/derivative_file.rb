# frozen_string_literal: true

module DerivativeService
  # Wrapper class around TempFile with additional derivative-specific variables and helper methods.
  class DerivativeFile
    attr_reader :mime_type, :file, :iiif

    delegate_missing_to :@file

    # @param [String] mime_type
    # @param [String, NilClass] extension
    # @param [TrueClass, FalseClass] iiif
    def initialize(mime_type:, extension: nil, iiif: false)
      @mime_type = mime_type
      @file = Tempfile.new(['', extension])
      @iiif = iiif
    end

    # Explicitly removing tempfile. After calling `cleanup!` this file should not be used.
    #
    # It's good practice to close and unlink a tempfile after its done being used. It ensures that is removed
    # and garbage collected quickly.
    def cleanup!
      @file.close
      @file.unlink
      @file = nil
    end
  end
end
