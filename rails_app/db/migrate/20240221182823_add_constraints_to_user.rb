# frozen_string_literal: true

class AddConstraintsToUser < ActiveRecord::Migration[7.1]
  def change
    change_column_null :users, :provider, false
    change_column_null :users, :uid, false
  end
end
