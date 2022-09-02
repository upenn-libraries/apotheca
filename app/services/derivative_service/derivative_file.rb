module DerivativeService
  class DerivativeFile
    attr_reader :mime_type, :file

    delegate_missing_to :@file

    def initialize(mime_type)
      @mime_type = mime_type
      @file = Tempfile.new
    end
  end
end