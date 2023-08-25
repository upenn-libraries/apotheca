# frozen_string_literal: true

module Users
  # custom OmniAuth callbacks
  class OmniauthCallbacksController < Devise::OmniauthCallbacksController
    skip_before_action :verify_authenticity_token, only: [:developer, :saml, :failure]

    def saml
      @user = User.from_omniauth_saml(request.env['omniauth.auth'])
      handle_user user: @user, kind: 'PennKey'
    end

    def developer
      @user = User.from_omniauth_developer(request.env['omniauth.auth'])
      handle_user user: @user, kind: 'Developer'
    end

    def failure
      flash.alert = 'Problem with authentication, try again.'
      Honeybadger.notify 'Omniauth failure'
      redirect_to root_path
    end

    private

    # @param [User] user
    # @param [String] kind
    def handle_user(user:, kind:)
      if !user
        redirect_to login_path, notice: 'Contact a site administrator for access.'
      elsif !user.active?
        redirect_to login_path, notice: 'Your account is inactive, contact a site administrator to regain access.'
      elsif user.save
        sign_in_and_redirect user, event: :authentication
        set_flash_message(:notice, :success, kind: kind) if is_navigational_format?
      else
        set_flash_message(:notice, :failure, kind: kind, reason: user.errors.to_a.join(', ')) if is_navigational_format?
        redirect_to login_path
      end
    end
  end
end
