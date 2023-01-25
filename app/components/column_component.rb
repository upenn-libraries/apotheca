# frozen_string_literal: true

# Component for Bootstrap Column.
class ColumnComponent < ViewComponent::Base
  def initialize(tag, col: nil, offset: nil, **options)
    @tag = tag
    @options = options

    @options[:class] = Array.wrap(@options[:class])
                            .concat(column_classes(col))
                            .concat(offset_classes(offset))
  end

  def column_classes(col)
    case col
    when String, Integer
      ["col-#{col}"]
    when Hash
      col.map { |size, num| "col-#{size}-#{num}" }
    else
      ['col']
    end
  end

  # Classes to offset columns: https://getbootstrap.com/docs/5.2/layout/columns/#offsetting-columns
  #
  # @param [Hash<Symbol, Integer>] offset columns
  def offset_classes(offset)
    case offset
    when Hash
      offset.map { |size, num| "offset-#{size}-#{num}" }
    else
      []
    end
  end

  def call
    render(BaseComponent.new(@tag, **@options)) { content }
  end
end
