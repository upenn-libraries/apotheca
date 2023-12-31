# frozen_string_literal: true

# Component for a Bootstrap Row.
class RowComponent < ViewComponent::Base
  def initialize(tag, **options)
    @tag = tag
    @options = options
    @options[:class] = Array.wrap(@options[:class]).append('row')
  end

  def call
    render(BaseComponent.new(@tag, **@options)) { content }
  end
end
