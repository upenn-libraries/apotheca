# frozen_string_literal: true

module Users
  class OmniauthCallbacksController < Devise::OmniauthCallbacksController
    # see: https://github.com/omniauth/omniauth#integrating-omniauth-into-your-application
    skip_before_action :verify_authenticity_token, only: :developer

    def developer
      @user = User.from_omniauth(request.env['omniauth.auth'])
      if @user.persisted?
        sign_in_and_redirect @user, event: :authentication
        set_flash_message(:notice, :success, kind: 'Developer') if is_navigational_format?
      else
        @user.save
        sign_in_and_redirect @user, event: :authentication
        set_flash_message(:notice, :created, kind: 'Developer') if is_navigational_format?
      end
    end

    def failure
      redirect_to root_path
    end
  end
end
