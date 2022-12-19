# frozen_string_literal: true
class RowComponent < ViewComponent::Base
  def initializer(tag, **options)
    @tag = tag
    @options = options
    @options[:class] = Array.wrap(@options[:class]).append('row')
  end

  def call
    render(BaseComponent.new(@tag, **@options)) { content }
  end
end