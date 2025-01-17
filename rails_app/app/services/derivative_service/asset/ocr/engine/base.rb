# frozen_string_literal: true

module DerivativeService
  module Asset
    module OCR
      module Engine
        # Super class from which all OCR Engine classes should inherit from.
        class Base
          def ocr
            raise NotImplementedError
          end

          def ocrable?
            raise NotImplementedError
          end
        end
      end
    end
  end
end
