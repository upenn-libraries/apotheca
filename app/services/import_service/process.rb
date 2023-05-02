# frozen_string_literal: true

module ImportService
  # Class to build appropriate process class base
  class Process
    CREATE = 'create'
    UPDATE = 'update'
    ACTIONS = [CREATE, UPDATE].freeze

    def self.build(**args)
      args.deep_symbolize_keys!

      action = args[:action].is_a?(String) ? args[:action].downcase : args[:action]

      case action
      when CREATE
        Process::Create.new(**args)
      when UPDATE
        Process::Update.new(**args)
      else
        Process::Invalid.new(**args)
      end
    end
  end
end
