# frozen_string_literal: true

# Component to render tabs

module Tabs
  class Component < ViewComponent::Base
    renders_many :tabs, 'Tab'

    def initialize(id:)
      @id = id
    end

    class Tab < ViewComponent::Base
      attr_reader :id, :active, :title

      def initialize(title:, active: false)
        @id = title.downcase.gsub(' ', '-')
        @title = title
        @active = active
      end

      def call
        content
      end
    end
  end
end
