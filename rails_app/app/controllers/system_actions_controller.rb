# frozen_string_literal: true

# System-level actions
class SystemActionsController < UIController
  def index
    authorize! :manage, :system_actions
  end
end
