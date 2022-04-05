# frozen_string_literal: true

# Component to create breadcrumb links.
class BreadcrumbsComponent < ViewComponent::Base
  renders_many :breadcrumbs, 'BreadcrumbComponent'

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

  class BreadcrumbComponent < ViewComponent::Base
    def initialize(href: nil, active: false)
      @href = href
      @active = active
    end

    def call
      options = { class: ['breadcrumb-item'] }
      options[:class] << 'active'       if @active
      options['aria-current'] = 'page'  if @active

      content_tag :li, options do
        if @href
          content_tag(:a, href: @href) { content }
        else
          content
        end
      end
    end
  end
end