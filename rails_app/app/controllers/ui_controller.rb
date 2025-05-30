# frozen_string_literal: true

# Shared behavior for HTML-rendering controllers
class UIController < ApplicationController
  include HeaderAlert

  before_action :authenticate_user!

  rescue_from 'CanCan::AccessDenied' do |_e|
    redirect_to root_path, alert: 'You are not authorized to access this area.'
  end

  def after_sign_out_path_for(_user_scope)
    if params[:type] == 'saml'
      'https://idp.pennkey.upenn.edu/logout'
    else
      root_path
    end
  end
end
