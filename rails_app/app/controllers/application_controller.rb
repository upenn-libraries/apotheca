# frozen_string_literal: true

# Parent of all Controller classes.
#
# Configures application-wide actions, making them available in each of the controllers.
# See UIController for shared behavior for HTML-rendering controllers.
# See APIController for shared behavior for JSON-rendering controllers.
class ApplicationController < ActionController::Base; end
