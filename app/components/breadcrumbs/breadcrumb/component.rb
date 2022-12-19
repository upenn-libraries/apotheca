module Breadcrumbs
  module Breadcrumb
    class Component < ViewComponent::Base
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
end
