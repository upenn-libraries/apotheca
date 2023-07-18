# frozen_string_literal: true

module Users
  # custom OmniAuth callbacks
  class OmniauthCallbacksController < Devise::OmniauthCallbacksController
    # see: https://github.com/omniauth/omniauth#integrating-omniauth-into-your-application
    skip_before_action :verify_authenticity_token, only: :developer

    def developer
      @user = User.from_omniauth(request.env['omniauth.auth'])

      # if user is already exists or is successfully created...
      if @user.persisted? || @user.save
        sign_in_and_redirect @user, event: :authentication
        set_flash_message(:notice, :success, kind: 'Developer') if is_navigational_format?
      else
        # problem saving - show validation errors
        if is_navigational_format?
          set_flash_message(:notice, :failure, kind: 'Developer', reason: @user.errors.to_a.join(', '))
        end
        redirect_to login_path
      end
    end

    def failure
      redirect_to root_path
    end
  end
end
