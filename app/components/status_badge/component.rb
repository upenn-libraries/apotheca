# frozen_string_literal: true

module StatusBadge
  # Render a badge with style and label
  class Component < ViewComponent::Base
    attr_reader :test, :truthy, :falsey

    # @param [TrueClass, FalseClass] test
    # @param [String] truthy
    # @param [String] falsey
    def initialize(test:, truthy:, falsey:)
      @test = test
      @truthy = truthy
      @falsey = falsey
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
      content_tag :span, label, class: classes.push('badge')
    end
  end
end

