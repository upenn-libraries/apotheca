# frozen_string_literal: true

# Contain and decorate a collection of objects, mostly to appease kaminari
class PaginatableSetPresenter
  attr_accessor :objects

  delegate_missing_to :objects

  # @param [ActiveRecord::Collection | Array] objects
  def initialize(objects)
    @objects = objects
  end

  # @return [Array]
  def presenters
    @presenters ||= @objects.map { |o| presenter_class.new(object: o) }
  end

  def each(&)
    presenters.each(&)
  end

  private

  # Infer presenter class based on first element of objects
  # @return [String]
  def presenter_class
    klass = @objects.try(:first).try(:class).try(:name)
    return unless klass

    @presenter_class ||= "#{klass}Presenter".constantize
  end
end
