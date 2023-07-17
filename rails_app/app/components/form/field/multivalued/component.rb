# frozen_string_literal: true

module Form
  module Field
    module Multivalued
      # Renders a list of inputs with the ability to add/remove inputs.
      #
      # Note: We want to delegate the input rendering to the parent component. To do this
      # we expect populated inputs and a template of the input (with no value) to be provided.
      # This allows for the most flexibility because this component won't have to assume where
      # the values should be set within an input.
      class Component < ViewComponent::Base
        # Inputs that are already populated with values
        renders_many :inputs

        # Template for the input
        renders_one :template
      end
    end
  end
end

