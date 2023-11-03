# rubocop:disable all
class CreateImport < ActiveRecord::Migration[7.0]
  def change
    create_table :imports do |t|
      t.string :state

      t.timestamps
    end
  end
end
