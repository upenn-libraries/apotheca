# frozen_string_literal: true

# Base presenter logic
class BasePresenter
  attr_accessor :object # #object_id is an Object method, but #object is OK

  delegate_missing_to :object

  # #to_param is a method on Object and so is not delegated. It is used by Rails route helpers (at least)
  # and passing a presenter to route helpers results in broken URLs. This delegates to the source, making route helpers
  # work with Presenters.
  # @todo if this causes issues, route helpers can be changed to call the #id method on a presenter
  delegate :to_param, to: :object

  # @param [ActiveRecord::Base|Valkyrie::Resource] object
  def initialize(object:)
    @object = object
  end
end
