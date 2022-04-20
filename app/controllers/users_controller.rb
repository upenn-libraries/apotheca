# frozen_string_literal: true

# Controller actions for Users
class UsersController < ApplicationController
  before_action :set_user, except: [:index, :new, :create]

  def index
    @users = User.active
  end

  def show; end

  def new
    @user = User.new
  end

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

  def set_user
    @user = User.find params[:id]
  end

  def user_params
    safe_params = params.require(:user).permit(:first_name, :last_name, :email, :active, :roles)
    safe_params[:roles] = Array.wrap(safe_params[:roles]) # roles is expected to be multivalued
    safe_params
  end
end
