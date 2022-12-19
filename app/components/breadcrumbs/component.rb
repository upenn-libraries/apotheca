# frozen_string_literal: true

# Component to create breadcrumb links.
module Breadcrumbs
  class Component < ViewComponent::Base
    renders_many :breadcrumbs, Breadcrumb::Component

    def initialize(**options)
      @options = options

      @options[:class] = Array.wrap(@options[:class]).append('mb-3 bg-light text-dark rounded')
    end

    def render?
      breadcrumbs.any?
    end

    def call
      render(BaseComponent.new(:nav, 'aria-label': 'breadcrumb', **@options)) do
        content_tag :ol, class: 'breadcrumb py-2 px-3' do
          safe_join(breadcrumbs)
        end
      end
    end
  end
end