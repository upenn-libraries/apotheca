# frozen_string_literal: true

module ActiveSupport
  module NumberHelper
    class NumberToHumanSizeConverter < NumberConverter
      private

      # We need this monkey patch because Rails has dropped support for "si" prefixed sizes. When displaying file
      # sizes, we want to calculate bytes -> to kb by dividing by 1000 not 1024. In order for us to use this helper
      # in that context we need the ability to change this base.
      def base
        options[:base] || 1000
      end
    end
  end
end
