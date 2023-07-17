# frozen_string_literal: true

module StatusBadge
  # Render a badge with style and label
  class Component < ViewComponent::Base
    attr_reader :test, :truthy, :falsey

    # @param [TrueClass, FalseClass] test
    # @param [String] truthy
    # @param [String] falsey
    def initialize(test:, truthy:, falsey:, **options)
      @test = test
      @truthy = truthy
      @falsey = falsey

      @options = options
      @options[:class] = Array.wrap(@options[:class]).append('badge').concat(classes)
    end

    # @return [Array<String (frozen)>]
    def classes
      test ? ['bg-success'] : %w[bg-warning text-dark]
    end

    # @return [String (frozen)]
    def label
      test ? truthy : falsey
    end

    # @return [ActiveSupport::SafeBuffer]
    def call
      render(BaseComponent.new(:span, **@options)) { label }
    end
  end
end
