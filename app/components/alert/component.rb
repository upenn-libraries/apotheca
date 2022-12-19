# frozen_string_literal: true

module Alert
  # Component to create Bootstrap alert box.
  class Component < ViewComponent::Base
    def initialize(tag: :div, variant: :primary, **options)
      @tag = tag
      @options = options

      @options[:class] = Array.wrap(@options[:class]).append('alert', "alert-#{variant}")
      @options[:role] = 'alert'
    end

    def call
      render(BaseComponent.new(@tag, **@options)) { content }
    end
  end
end
