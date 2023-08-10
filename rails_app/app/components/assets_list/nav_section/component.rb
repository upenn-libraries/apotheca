# frozen_string_literal: true

module AssetsList
  module NavSection
    # Component for arrangement section, holding Asset cards
    class Component < ViewComponent::Base
      attr_reader :assets, :arranged

      # @param [Array<AssetResource>] assets
      # @param [TrueClass, FalseClass] arranged
      def initialize(assets:, arranged:)
        @assets = assets
        @arranged = arranged
      end

      def title
        t(:title, scope: [:assets, :arrangement, type])
      end

      def title_href
        "#{type}-assets"
      end

      private

      def type
        arranged ? :arranged : :unarranged
      end
    end
  end
end
