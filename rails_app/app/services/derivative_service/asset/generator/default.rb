# frozen_string_literal: true

module DerivativeService
  module Asset
    module Generator
      # Default generator class for files that don't have any prescribed derivative generation logic.
      class Default < Base
        # @return [nil]
        def thumbnail
          nil
        end

        # @return [nil]
        def access
          nil
        end

        # @return [nil]
        def textonly_pdf
          nil
        end

        # @return [nil]
        def text
          nil
        end

        # @return [nil]
        def hocr
          nil
        end

        # @return [nil]
        def iiif_image
          nil
        end
      end
    end
  end
end
