# frozen_string_literal: true

Rails.application.routes.draw do
  resources :items, only: [:index, :edit, :update]
end
