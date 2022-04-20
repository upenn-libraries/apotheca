# frozen_string_literal: true

Rails.application.routes.draw do
  devise_for :users, controllers: { omniauth_callbacks: 'users/omniauth_callbacks' }
  devise_scope :user do
    post 'sign_out', to: 'devise/sessions#destroy', as: :destroy_user_session
  end

  resources :users, except: :destroy
  resources :items, only: %i[index edit update]
  get 'login', to: 'login#index'

  authenticated do
    root to: 'items#index', as: :authenticated_root
  end

  root to: redirect('/login')
end
