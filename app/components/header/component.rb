# frozen_string_literal: true

module Header




  class Component < ViewComponent::Base

    attr_reader :render_right_link

    # @param [Boolean] render_right_link
    def initialize(render_right_link: true)
      @render_right_link = render_right_link
    end

    renders_one :title, ->(tag: :h1, **options, &block) do
      BaseComponent.new(tag, **options, &block)
    end

    renders_one :right_link, ->(href:, **options, &block) do
      options[:class] = Array.wrap(options[:class]).append('btn', 'btn-outline-primary')
      BaseComponent.new(:a, href: href, **options, &block)
    end

  end
end
