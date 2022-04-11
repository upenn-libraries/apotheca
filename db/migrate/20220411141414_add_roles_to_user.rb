class AddRolesToUser < ActiveRecord::Migration[7.0]
  def change
    change_table :users do |t|
      t.string :roles, array: true, index: true
    end
  end
end
