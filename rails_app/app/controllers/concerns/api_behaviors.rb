# frozen_string_literal: true

# shared behaviors for API controllers
module APIBehaviors
  extend ActiveSupport::Concern

  included do
    skip_before_action :authenticate_user!
  end

  # TODO: rescue resource not found
end
