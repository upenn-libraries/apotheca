# frozen_string_literal: true

module API
  module Resources
    # Base controller for Resource API endpoints
    class BaseController < ApplicationController
      include APIBehaviors
    end
  end
end
