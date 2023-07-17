# frozen_string_literal: true

# Include Optimistic Locking behaviors from Valkyrie
module Lockable
  extend ActiveSupport::Concern

  included { enable_optimistic_locking }

  # @return [TrueClass]
  def lockable?
    true
  end
end
