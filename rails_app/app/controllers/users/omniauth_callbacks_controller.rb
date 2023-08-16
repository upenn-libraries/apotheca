# frozen_string_literal: true

module Users
  # custom OmniAuth callbacks
  class OmniauthCallbacksController < Devise::OmniauthCallbacksController
    # see: https://github.com/omniauth/omniauth#integrating-omniauth-into-your-application
    skip_before_action :verify_authenticity_token, only: [:developer, :saml]

    def saml
      @user = User.from_omniauth_saml(request.env['omniauth.auth'])
      handle_user user: @user, kind: 'SAML'
    end

    def developer
      @user = User.from_omniauth_developer(request.env['omniauth.auth'])
      handle_user user: @user, kind: 'Developer'
    end

    def failure
      redirect_to root_path
    end

    private

    # @param [User] user
    # @param [String] kind
    def handle_user(user:, kind:)
      # if user is already exists or is successfully created...
      if user.persisted? || user.save
        sign_in_and_redirect user, event: :authentication
        set_flash_message(:notice, :success, kind: kind) if is_navigational_format?
      else
        # problem saving - show validation errors
        if is_navigational_format?
          set_flash_message(:notice, :failure, kind: kind,
                            reason: user.errors.to_a.join(', '))
        end
        redirect_to login_path
      end
    end
  end
end
