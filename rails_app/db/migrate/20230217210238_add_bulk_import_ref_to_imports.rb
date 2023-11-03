# rubocop:disable all
# frozen_string_literal: true
class AddBulkImportRefToImports < ActiveRecord::Migration[7.0]
  def change
    add_reference :imports, :bulk_import, null: false, index: true, foreign_key: true
  end
end

