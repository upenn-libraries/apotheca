# frozen_string_literal: true

# Module that implements a state machine to manage state of asynchronous
# jobs. Models that use this concern should implement a #run method that
# does the necessary processing and have a `status` attribute (and
# corresponding db column if using ActiveRecord).
module Queueable
  extend ActiveSupport::Concern

  included do
    include AASM

    aasm column: :state do
      state :queued, initial: true
      state :processing, :cancelled, :successful, :failed

      event :cancel do
        transitions from: :queued, to: :cancelled
      end

      event :process, after_commit: :run do
        transitions from: :queued, to: :processing
      end

      event :success do
        transitions from: :processing, to: :successful
      end

      event :failure do
        transitions from: :processing, to: :failed
      end
    end
  end
end