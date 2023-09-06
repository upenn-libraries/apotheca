# frozen_string_literal: true

module ImportService
  # Class to build appropriate process class base
  class Process
    CREATE = 'create'
    UPDATE = 'update'
    MIGRATE = 'migrate'
    ACTIONS = [CREATE, UPDATE, MIGRATE].freeze

    def self.build(**args)
      args.deep_symbolize_keys!

      case args[:action]&.downcase
      when CREATE
        Process::Create.new(**args)
      when UPDATE
        Process::Update.new(**args)
      when MIGRATE
        Process::Migrate.new(**args)
      else
        Process::Invalid.new(**args)
      end
    end
  end
end
