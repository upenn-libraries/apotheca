# frozen_string_literal: true

module DerivativeService
  module Asset
    module Generator
      # Super class from which all Generator classes should inherit from.
      class Base
        attr_reader :file

        # @param file [DerivativeService::Asset::SourceFile]
        def initialize(file)
          @file = file
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
end
