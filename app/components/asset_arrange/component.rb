# frozen_string_literal: true

module AssetArrange
  # Component for rendering form and sections for arranging assets
  class Component < ViewComponent::Base
    attr_reader :item

    renders_one :unarranged_section, Section::Component
    renders_one :arranged_section, Section::Component

    def initialize(item:)
      @item = item
    end

    def instructions
      t('assets.arrangement.instructions')
    end

    def submit
      submit_tag 'Save Arrangement', class: 'btn btn-primary'
    end

    def reset
      link_to 'Reset', reorder_assets_item_path(item), class: 'btn btn-secondary'
    end
  end
end
