# frozen_string_literal: true

module DerivativeService
  # Generator module that determines the correct generator for a file and mime type.
  module Generator
    def self.for(file, mime_type)
      generator = case mime_type
                  when *Generator::Image::VALID_MIME_TYPES
                    Generator::Image
                  when *Generator::Audio::VALID_MIME_TYPES
                    Generator::Audio
                  else
                    Generator::Default
                  end
      generator.new file
    end
  end
end
