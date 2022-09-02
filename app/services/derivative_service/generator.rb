module DerivativeService
  module Generator
    def self.for(file, mime_type)
      return Generator::Image.new(file) if Generator::Image::VALID_MIME_TYPES.include?(mime_type)
    end
  end
end