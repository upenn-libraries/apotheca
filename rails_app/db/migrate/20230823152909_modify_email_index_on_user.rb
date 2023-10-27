# rubocop:disable all
# frozen_string_literal: true

# Modify index on User email field to be scoped to the provider field
class ModifyEmailIndexOnUser < ActiveRecord::Migration[7.0]
  def change
    remove_index :users, column: :email, unique: true
    add_index :users, %i[provider email], unique: true
  end
end
