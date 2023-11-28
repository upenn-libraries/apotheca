# frozen_string_literal: true

module DerivativeService
  # Wrapper class around TempFile with additional derivative-specific variables and helper methods.
  class DerivativeFile
    attr_reader :mime_type, :file, :iiif_image, :iiif_manifest

    delegate_missing_to :@file

    # @param [String] mime_type
    # @param [String, NilClass] extension
    # @param [TrueClass, FalseClass] iiif_image
    # @param [TrueClass, FalseClass] iiif_manifest
    def initialize(mime_type:, extension: nil, iiif_image: false, iiif_manifest: false)
      @mime_type = mime_type
      @file = Tempfile.new(['', extension])
      @iiif_image = iiif_image
      @iiif_manifest = iiif_manifest
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
