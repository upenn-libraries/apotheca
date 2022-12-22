# frozen_string_literal: true

module Icon
  # Component to create an <i> tag for rendering a Bootstrap Icon
  # For a lis tof all available icons, see: https://icons.getbootstrap.com
  class Component < ViewComponent::Base
    # see: https://icons.getbootstrap.com/#icon-font
    # @param [String, Symbol] name
    # @param [String, nil] size as CSS property value (font-size)
    # @param [String, nil] color
    def initialize(name:, size: nil, color: nil, **options)
      @options = options
      @options[:class] = Array.wrap(@options[:class]).append("bi-#{name.to_s}")
      @options[:style] = (@options[:style] || '') + style_from(size, color)
    end

    # @param [String] size
    # @param [String] color
    # @return [String (frozen)]
    def style_from(size, color)
      size_def = "font-size: #{size};"
      color_def = "color: #{color};"
      "#{size_def if size}#{color_def if color}"
    end

    def call
      render(BaseComponent.new(:i, **@options))
    end
  end
end
