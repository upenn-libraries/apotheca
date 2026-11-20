# frozen_string_literal: true

# Shared logic for all operations.
class Operation < Dry::Operation
  # Convenience method to use `call` method without instantiating the operation.
  def self.call(...)
    new.call(...)
  end

  # Shared `on_failure` logic that adds in an error message to the failure object from translations.
  def on_failure(failure)
    add_error_message(failure)
  end

  private

  # If a failure occurs, a human-readable error message is added to the Failure.
  #
  # To generate the message, the :error key is used to look up a custom message in operations.en.yml. First, the
  # namespace of the class is checked, if none is found the namespace of the parent classes are checked. If a message
  # is not found, a generic one is created from the error key. All Failure attributes besides :error and :exception
  # are passed to the locale so messages can be customized.
  #
  # @param failure [Hash] data within failure monad
  def add_error_message(failure)
    translation_keys = failure_translation_keys(failure[:error])

    key = translation_keys.shift
    defaults = translation_keys + [failure[:error].to_s.humanize]

    failure[:message] = I18n.t(key,
                               scope: :operations,
                               default: defaults,
                               exception_message: failure[:exception]&.message,
                               **failure.except(:exceptions, :error))
  end

  # Returns list of translation keys where error messages could be provided. List is in order of precedence.
  #
  # For example, for a failure in the Asset::Create operation the following keys will be returned:
  #   operations.asset.create.failure.{error}
  #   operations.asset.failure.{error}
  #   operations.resource.failure.{error}
  #
  # @param error [Symbol]
  # @return [Array<Symbol>] translation keys where messages could be defined
  def failure_translation_keys(error)
    superclasses = self.class.ancestors.select { |a| a.is_a? Class }.take_while { |c| c != Operation }

    # Convert superclasses to translation lookup keys
    superclasses.map do |klass|
      klass.to_s.underscore.tr('/', '.').delete_suffix('.operation').concat(".failure.#{error}").to_sym
    end
  end
end
