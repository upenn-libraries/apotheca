# frozen_string_literal: true

module DerivativeService
  module Generator
    # Default generator class for files that don't have any prescribed derivative generation logic.
    class Default < Base
      def thumbnail
        nil
      end

      def access
        nil
      end
    end
  end
end
