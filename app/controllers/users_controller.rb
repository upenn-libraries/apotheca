# frozen_string_literal: true

# Controller actions for Users
class UsersController < ApplicationController
  load_and_authorize_resource

  include PerPage

  def index
    per_page = params[:per_page] || session[:"#{controller_name}_per_page"]
    @users = User.page(params[:page]).per(per_page)
    @users = @users.users_search(params[:users_search]) if params[:users_search].present?
    @users = @users.active_filter(params[:active_filter]) if params[:active_filter].present?
    @users = @users.roles_filter(params[:roles_filter]) if params[:roles_filter].present?
  end

  def show; end

  def new; end

  def create
    @user = User.new user_params
    if @user.save
      redirect_to user_path(@user), notice: 'User created'
    else
      render :new, alert: "Problem creating user: #{@user.errors.map(&:full_message).join(', ')}"
    end
  end

  def edit; end

  def update
    @user.update user_params
    if @user.save
      redirect_to user_path(@user), notice: 'User updated'
    else
      render :edit, alert: "Problem updating user: #{@user.errors.map(&:full_message).join(', ')}"
    end
  end

  private

  def user_params
    safe_params = params.require(:user).permit(:first_name, :last_name, :email, :active, :roles)
    safe_params[:roles] = Array.wrap(safe_params[:roles]) # roles is expected to be multivalued
    safe_params
  end
end
