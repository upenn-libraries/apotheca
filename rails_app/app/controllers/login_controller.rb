# frozen_string_literal: true

# do login stuff
class LoginController < ApplicationController
  skip_before_action :authenticate_user!, only: :index

  def index; end
end
