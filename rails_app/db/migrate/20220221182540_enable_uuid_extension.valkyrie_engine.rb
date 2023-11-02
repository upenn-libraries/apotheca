# rubocop:disable all
# frozen_string_literal: true
# This migration comes from valkyrie_engine (originally 20160111215816)
class EnableUuidExtension < ActiveRecord::Migration[5.0]
  def change
    enable_extension 'uuid-ossp'
  end
end
