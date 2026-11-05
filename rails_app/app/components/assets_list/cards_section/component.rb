# frozen_string_literal: true

module AssetsList
  module CardsSection
    # Component for section of asset cards, arranged or unarranged
    class Component < ViewComponent::Base
      attr_reader :arranged

      # @param item [ItemPresenter]
      # @param user [User]
      # @param assets [Array<Asset>]
      # @param arranged [Boolean]
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
