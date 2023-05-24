# frozen_string_literal: true

module Header
  # Renders a title and associated actions of a page or tab
  class Component < ViewComponent::Base
    renders_one :title, lambda { |tag: :h1, **options, &block|
      BaseComponent.new(tag, **options, &block)
    }

    renders_many :links, lambda { |href:, **options, &block|
      options[:class] = Array.wrap(options[:class]).append('btn', 'btn-outline-primary')
      BaseComponent.new(:a, href: href, **options, &block)
    }
  end
end
