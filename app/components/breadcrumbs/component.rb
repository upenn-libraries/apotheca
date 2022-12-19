# frozen_string_literal: true

# Component to create breadcrumb links.
module Breadcrumbs
  class Component < ViewComponent::Base
    renders_many :breadcrumbs, Breadcrumb::Component

    def render?
      breadcrumbs.any?
    end

    def call
      content_tag :nav, class: 'mb-3 bg-light text-dark rounded', 'aria-label': 'breadcrumb' do
        content_tag :ol, class: 'breadcrumb py-2 px-3' do
          safe_join(breadcrumbs)
        end
      end
    end
  end
end