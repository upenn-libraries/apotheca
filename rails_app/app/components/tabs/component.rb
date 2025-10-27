# frozen_string_literal: true

module Tabs
  # Renders a tabbed interface. Contains multiple Tab subcomponents.
  class Component < ViewComponent::Base
    renders_many :tabs, 'Tab'

    def initialize(id:)
      @id = id
    end

    # Returns the default tab.
    def default_tab
      tabs.find { |tab| tab.default }
    end

    # Renders a single Tab component
    class Tab < ViewComponent::Base
      attr_reader :id, :title, :count, :disabled, :default

      def initialize(title:, count: nil, default: false, disabled: false)
        @id = title.downcase.tr(' ', '-')
        @title = title
        @default = default
        @count = count
        @disabled = disabled
      end

      # Tab contents.
      def call
        content
      end
    end
  end
end
