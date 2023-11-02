# rubocop:disable all
# frozen_string_literal: true

# Add fields to Import
class ChangeImport < ActiveRecord::Migration[7.0]
  def change
    change_table :imports do |t|
      t.string :process_errors, array: true
      t.jsonb :import_data
      t.integer :duration
      t.string :resource_identifier
    end
  end
end
