# frozen_string_literal: true

class CreateBulkImports < ActiveRecord::Migration[7.0]
  def change
    create_table :bulk_imports do |t|
      t.text :note
      t.text :original_filename
      t.references :created_by, null: false, index: true, foreign_key: { to_table: :users }

      t.timestamps
    end
  end
end
