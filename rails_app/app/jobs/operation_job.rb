# frozen_string_literal: true

# Class that jobs can inherit from when calling operations and returning monads. This class overrides the #perform
# method so that returned Failure monads are unwrapped and raised as exceptions and retried via Sidekiq.
class OperationJob
  include Sidekiq::Job

  class Error < StandardError; end

  def operation(*_args)
    raise '#operation must be implemented when inheriting from OperationJob'
  end

  def perform(*args)
    result = operation(*args)

    return if result.success?

    failure = result.failure

    raise failure[:exception] if failure[:exception]

    raise Error, failure[:error].to_s.titleize
  end
end
