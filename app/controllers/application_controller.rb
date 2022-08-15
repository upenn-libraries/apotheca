# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include HeaderAlert

  before_action :authenticate_user!

  rescue_from 'CanCan::AccessDenied' do |_e|
    redirect_to root_path, alert: 'You are not authorized to access this area.'
  end
end
