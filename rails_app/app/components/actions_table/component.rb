# frozen_string_literal: true

module ActionsTable
  # Renders table of actions for a resource
  class Component < ViewComponent::Base
    renders_many :actions, Action::Component
  end
end
