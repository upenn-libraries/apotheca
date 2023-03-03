# frozen_string_literal: true

# decorate a collection, mostly to appease kaminari
class CollectionPresenter
  delegate_missing_to :@objects

  def initialize(objects, presenter)
    @objects = objects
    @presenter = presenter # TODO: could infer this from @objects.first? but what is an empty collection?
  end

  def each(&)
    @objects.map { |o| @presenter.new(object: o) }.each(&)
  end
end
