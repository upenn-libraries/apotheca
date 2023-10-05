# frozen_string_literal: true

module AssetsList
  # Component for rendering arranged and unarranged sections of assets and assets nav
  class Component < ViewComponent::Base
    renders_one :arranged_cards_section, lambda { |**options|
      CardsSection::Component.new(item: @item, user: @user, arranged: true, **options)
    }
    renders_one :unarranged_cards_section, lambda { |**options|
      CardsSection::Component.new(item: @item, user: @user, arranged: false, **options)
    }

    renders_one :arranged_nav_section, ->(**options) { NavSection::Component.new(arranged: true, **options) }
    renders_one :unarranged_nav_section, ->(**options) { NavSection::Component.new(arranged: false, **options) }

    # @param [ItemResource|ItemResourcePresenter] item
    # @param [User] user
    def initialize(item:, user:)
      @item = item
      @user = user
    end

    # Only use scrollspy if item has at least 8 assets
    def use_spy?
      @item.asset_count >= 8
    end
  end
end
