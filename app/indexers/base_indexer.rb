# frozen_string_literal: true

# shared behavior for Indexers
class BaseIndexer
  attr_reader :resource

  # @param [Valkyrie::Resource] resource
  def initialize(resource:)
    @resource = resource
  end
end
