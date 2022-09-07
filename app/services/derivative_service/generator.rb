# frozen_string_literal: true

module DerivativeService
  # Generator module that determines the correct generator for a file and mime type.
  module Generator
    def self.for(file, mime_type)
      return Generator::Image.new(file) if Generator::Image::VALID_MIME_TYPES.include?(mime_type)

      Generator::Default.new(file)
    end
  end
end
