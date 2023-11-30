# frozen_string_literal: true

class CreateResourceEvents < ActiveRecord::Migration[7.1]
  def change
    create_table :resource_events do |t|
      t.string :event_type, null: false
      t.string :initiated_by
      t.datetime :completed_at, null: false
      t.string :resource_identifier, null: false, index: true
      t.jsonb :resource_json

      t.timestamps
    end
  end
end
