# frozen_string_literal: true

# Controller actions for Users
class UsersController < UIController
  include PerPage

  load_and_authorize_resource

  def index
    @users = User.page(params[:page]).per(per_page)
    @users = @users.users_search(params[:users_search]) if params[:users_search].present?
    @users = @users.active_filter(params[:active_filter]) if params[:active_filter].present?
    @users = @users.roles_filter(params[:roles_filter]) if params[:roles_filter].present?
    @users = PaginatableSetPresenter.new @users
  end

  def show
    @user = UserPresenter.new object: @user
  end

  def new; end

  def create
    @user.update(**user_params, provider: 'saml')
    if @user.save
      flash.notice = "User access granted for #{@user.uid}"
      redirect_to user_path(@user)
    else
      flash.alert = "Problem adding user: #{@user.errors.map(&:full_message).join(', ')}"
      render :edit
    end
  end

  def edit; end

  def update
    @user.update user_params
    if @user.save
      flash.notice = 'User updated'
      redirect_to user_path(@user)
    else
      flash.alert = "Problem updating user: #{@user.errors.map(&:full_message).join(', ')}"
      render :edit
    end
  end

  private

  def user_params
    params.require(:user).permit(:first_name, :last_name, :uid, :email, :active, :roles).tap do |p|
      p[:roles] = Array.wrap(p[:roles]) # roles is expected to be multivalued
      p[:email] = "#{p[:uid]}@upenn.edu" if p[:email].blank?
    end
  end
end
