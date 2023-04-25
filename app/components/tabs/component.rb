# frozen_string_literal: true

# Component to render tabs
module Tabs
  class Component < ViewComponent::Base
    renders_many :tabs, 'Tab'

    def initialize(id:)
      @id = id
    end

    class Tab < ViewComponent::Base
      attr_reader :id, :active, :title, :count, :disabled

      def initialize(title:, count: nil, active: false, disabled: false)
        @id = title.downcase.tr(' ', '-')
        @title = title
        @active = active
        @count = count
        @disabled = disabled
      end

      def call
        content
      end
    end
  end
end
