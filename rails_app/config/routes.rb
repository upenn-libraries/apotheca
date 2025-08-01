# frozen_string_literal: true

require 'sidekiq/pro/web'
require 'sidekiq/cron/web'

Rails.application.routes.draw do
  devise_for :users, controllers: { omniauth_callbacks: 'users/omniauth_callbacks' }
  devise_scope :user do
    post 'sign_out', to: 'devise/sessions#destroy'
  end

  # NOTE: may need to add a subdomain constraint, e.g., `constraints: { subdomain: 'api.apotheca.library' }`
  scope module: :api do
    scope :v1, defaults: { format: :json } do
      scope :items, module: :resources do
        get '/:uuid', to: 'items#show', as: :api_item_resource
        get '/lookup/*ark', to: 'items#lookup', constraints: ->(req) { req.params[:ark] =~ %r{\Aark:/\d+/\w+\z} },
                            as: :api_ark_lookup
        get '/:uuid/preview', to: 'items#preview', as: :api_item_preview
        get '/:uuid/pdf', to: 'items#pdf', as: :api_item_pdf
      end
      scope :assets, module: :resources do
        get '/:uuid', to: 'assets#show', as: :api_asset_resource
        get '/:uuid/:file', to: 'assets#file', as: :api_asset_file
      end
    end
    namespace :iiif do
      scope :items do
        get ':uuid/manifest', to: 'items#manifest', as: :api_item_iiif_manifest
      end
    end
  end

  resources :alert_messages, only: %w[index update]
  resources :users, except: :destroy
  scope :bulk_imports do
    post 'file_listing_tool/file_list', to: 'file_listing_tool#file_list'
    get 'file_listing_tool', to: 'file_listing_tool#tool'
  end
  resources :bulk_imports, except: %i[edit destroy update] do
    member do
      patch :cancel, to: 'bulk_imports#cancel'
      get :csv, to: 'bulk_imports#csv'
    end
    resources :imports, only: %w[show] do
      member do
        patch :cancel, to: 'imports#cancel'
      end
    end
  end
  resources :bulk_exports, except: %i[edit update show] do
    member do
      get :cancel, to: 'bulk_exports#cancel'
      get :regenerate, to: 'bulk_exports#regenerate'
    end
  end

  scope :resources do
    resources :items do
      member do
        get :reorder_assets, to: 'items#reorder_assets'
        get 'file/:type', to: 'items#file', as: :file
        post :refresh_ils_metadata, to: 'items#refresh_ils_metadata'
        post :publish, to: 'items#publish'
        post :unpublish, to: 'items#unpublish'
        post :regenerate_all_derivatives, to: 'items#regenerate_all_derivatives'
      end

      collection do
        post 'refresh_all_ils_metadata', to: 'items#refresh_all_ils_metadata'
      end
    end
    resources :assets, except: :index do
      member do
        get 'file/:type', to: 'assets#file', as: :file
        post :regenerate_derivatives, to: 'assets#regenerate_derivatives'
      end
    end
  end

  resources :system_actions, only: [:index]

  resources :events, only: [:index, :show]

  resources :reports, only: [:index]

  authenticate :user, ->(u) { u.can? :manage, :sidekiq_dashboard } do
    mount Sidekiq::Web => '/sidekiq'
  end

  get 'login', to: 'login#index'

  authenticated do
    root to: 'items#index', as: :authenticated_root
  end

  root to: redirect('/login')

  # Enable Rails built in health check endpoint. This endpoint is not suitable for checking uptime because it doesn't
  # consider all of the application's services.
  get 'up', to: "rails/health#show", as: :rails_health_check
end
