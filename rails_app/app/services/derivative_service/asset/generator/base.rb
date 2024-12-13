# frozen_string_literal: true

module DerivativeService
  module Asset
    module Generator
      # Super class from which all Generator classes should inherit from.
      class Base
        attr_reader :file

        # @param file [DerivativeService::Asset::SourceFile]
        # @param asset [AssetChangeSet]
        def initialize(file, asset = nil)
          @file = file
          @asset = asset
        end

        def thumbnail
          raise NotImplementedError
        end

        def access
          raise NotImplementedError
        end

        def textonly_pdf
          raise NotImplementedError
        end

        def text
          raise NotImplementedError
        end

        def hocr
          raise NotImplementedError
        end
      end
    end
  end
end
