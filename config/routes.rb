# frozen_string_literal: true

Rails.application.routes.draw do
  devise_for :users, controllers: { omniauth_callbacks: 'users/omniauth_callbacks' }
  devise_scope :user do
    post 'sign_out', to: 'devise/sessions#destroy', as: :destroy_user_session
  end

  resources :items, only: [:index, :edit, :update]

  root to: 'application#login'
end
