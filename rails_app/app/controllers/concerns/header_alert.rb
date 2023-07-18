# frozen_string_literal: true

# used to mixin alert behavior
module HeaderAlert
  extend ActiveSupport::Concern

  included do
    before_action :header_alert
  end

  def header_alert
    @header_alert = AlertMessage.header
  end
end
