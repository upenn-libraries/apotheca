# frozen_string_literal: true

class CreateReports < ActiveRecord::Migration[7.1]
  def change
    create_table :reports do |t|
      t.datetime :generated_at
      t.string :report_type
      t.string :status
      t.integer :duration

      t.timestamps
    end
  end
end
