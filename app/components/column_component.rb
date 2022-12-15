# frozen_string_literal: true
class ColumnComponent < ViewComponent::Base
  def initializer(tag, col:, **options)
    @tag = tag
    @options = options

    @options[:class] = Array.wrap(@options[:class]).concat(column_classes(col))
  end

  def column_classes(col)
    case col
    when String, Integer
      "col-#{col}"
    when Hash
      col.map { |size, num| "col-#{size}-#{num}" }
    else
      'col'
    end
  end

  def call
    render(BaseComponent.new(@tag, **@options)) { content }
  end
end