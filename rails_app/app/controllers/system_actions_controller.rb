# frozen_string_literal: true

# System-level actions
class SystemActionsController < ApplicationController
  def index
    authorize! :manage, :system_actions
  end
end
