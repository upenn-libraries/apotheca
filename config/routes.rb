# frozen_string_literal: true

Rails.application.routes.draw do
  devise_for :users, controllers: { omniauth_callbacks: 'users/omniauth_callbacks' }
  devise_scope :user do
    post 'sign_out', to: 'devise/sessions#destroy', as: :destroy_user_session
  end

  resources :alert_messages, only: %w[index update]
  resources :users, except: :destroy

  scope :resources do
    resources :items do
      member do
        get :reorder_assets, to: 'items#reorder_assets'
      end
    end
    resources :assets, except: :index do
      member do
        get 'file/:type', to: 'assets#file', as: :file
      end
    end
  end

  get 'login', to: 'login#index'

  authenticated do
    root to: 'items#index', as: :authenticated_root
  end

  root to: redirect('/login')
end
