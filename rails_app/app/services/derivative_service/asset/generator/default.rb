# frozen_string_literal: true

module DerivativeService
  module Asset
    module Generator
      # Default generator class for files that don't have any prescribed derivative generation logic.
      class Default < Base
        def thumbnail
          nil
        end

        def access
          nil
        end

        def textonlypdf
          nil
        end

        def text
          nil
        end

        def hocr
          nil
        end
      end
    end
  end
end
