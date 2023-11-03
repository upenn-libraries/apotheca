# rubocop:disable all
# frozen_string_literal: true

# add role information to User
class AddRolesToUser < ActiveRecord::Migration[7.0]
  def change
    change_table :users do |t|
      t.string :roles, array: true, index: true, default: [], nil: false
    end
  end
end
