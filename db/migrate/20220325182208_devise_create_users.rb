# frozen_string_literal: true

# create Devise-supported User class
class DeviseCreateUsers < ActiveRecord::Migration[7.0]
  def change
    create_table :users do |t|
      t.string :first_name
      t.string :last_name
      t.string :email
      t.boolean :active
      t.timestamps null: false

      # rememberable
      t.datetime :remember_created_at

      # omniauthable
      t.string :provider
      t.string :uid

      t.index :email, unique: true
    end
  end
end
