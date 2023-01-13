# frozen_string_literal: true

module Header
  class Component < ViewComponent::Base
    renders_one :title, ->(tag: :h1, **options, &block) do
      BaseComponent.new(tag, **options, &block)
    end

    renders_one :right_link, ->(href:, **options, &block) do
      options[:class] = Array.wrap(options[:class]).append('btn', 'btn-outline-primary')
      BaseComponent.new(:a, href: href, **options, &block)
    end
  end
end
