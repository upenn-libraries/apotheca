# frozen_string_literal: true

module AssetArrange
  class Component < ViewComponent::Base
    attr_reader :item, :arranged_assets, :unarranged_assets
    def initialize(item:, arranged_assets:, unarranged_assets:)
      @item = item
      @arranged_assets = arranged_assets
      @unarranged_assets = unarranged_assets
    end
  end
end
