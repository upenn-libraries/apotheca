# frozen_string_literal: true

# Parent of all Controller classes. Configures application-wide actions, making them available in each of the controllers.
class ApplicationController < ActionController::Base
  include HeaderAlert

  before_action :authenticate_user!

  rescue_from 'CanCan::AccessDenied' do |_e|
    redirect_to root_path, alert: 'You are not authorized to access this area.'
  end

  def after_sign_out_path_for(current_user)
    'https://idp.pennkey.upenn.edu/logout'
  end
end
