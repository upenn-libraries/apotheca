# frozen_string_literal: true

module AssetsList
  module CardsSection
    # Component for arrangement section, holding Asset cards
    class Component < ViewComponent::Base
      attr_reader :arranged

      # @param [Array<AssetResource>] assets
      # @param [TrueClass, FalseClass] arranged
      def initialize(item:, user:, assets:, arranged:)
        @item = item
        @user = user
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
