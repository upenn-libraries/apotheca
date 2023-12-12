# frozen_string_literal: true

module ActionsTable
  module Action
    # Responsible for rendering single row in ActionsTable body
    class Component < ViewComponent::Base
      renders_one :form_component, Form::Component

      # @param [String] description of the action
      def initialize(description:)
        @description = description
      end
    end
  end
end
