# frozen_string_literal: true

module AssetsList
  module NavSection
    # Component for assets nav sidebar section, containing links to asset cards
    class Component < ViewComponent::Base
      attr_reader :assets, :arranged

      # @param [Array<AssetResource>] assets
      # @param [TrueClass, FalseClass] arranged
      def initialize(assets:, arranged:)
        @assets = assets
        @arranged = arranged
      end

      # Title of the section, eg: "Arranged"
      def title
        t(:title, scope: [:assets, :arrangement, type])
      end

      # Link to the nav section title's accompanying title in the main content
      def title_href
        "#{type}-assets"
      end

      private

      # Arranged vs unarranged assets section
      def type
        arranged ? :arranged : :unarranged
      end
    end
  end
end
