# frozen_string_literal: true

# Base presenter logic
class BasePresenter
  attr_accessor :object

  delegate_missing_to :object

  # @param [ActiveRecord::Base|Valkyrie::Resource] object
  def initialize(object:)
    @object = object
  end
end
