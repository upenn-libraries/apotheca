# rubocop:disable all
# frozen_string_literal: true

# Provide for storage of transient alert messages in header and homepage locations
class CreateAlertMessages < ActiveRecord::Migration[7.0]
  def up
    create_table :alert_messages do |t|
      t.boolean :active, default: false
      t.string :message
      t.string :level
      t.string :location
      t.timestamps
    end

    AlertMessage.create! [{ location: 'header' }, { location: 'home' }]
  end

  def down
    drop_table :alert_messages
  end
end
