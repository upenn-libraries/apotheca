# frozen_string_literal: true

class AddConstraintsToBulkExports < ActiveRecord::Migration[7.0]
  def change
    add_foreign_key :bulk_exports, :users, column: :created_by_id
    change_column_null :bulk_exports, :created_by_id, false
  end
end
