# frozen_string_literal: true

# Shared logic for all operations.
class Operation < Dry::Operation
  # Convenience method to use `call` method without instantiating the operation.
  def self.call(...)
    new.call(...)
  end

  # Shared `on_failure` logic that adds in an error message to the failure object from translations.
  def on_failure(failure)
    failure[:message] = error_message(failure)
  end

  private

  # Generate human-readable error message based on the Failure monad provided.
  #
  # To generate the message, the :error key is used to look up a custom message in operations.en.yml. First, the
  # namespace of the class is checked, if none is found the namespace of the parent classes are checked. If a message
  # is not found, a generic one is created from the error key. All Failure attributes besides :error and :exception
  # are passed to the locale so messages can be customized.
  #
  # @param failure [Hash] data within failure monad
  def error_message(failure)
    translation_keys = failure_translation_keys(failure[:error])

    key = translation_keys.shift
    defaults = translation_keys + [failure[:error].to_s.humanize]

    I18n.t(key, scope: :operations,
                default: defaults,
                exception_message: failure[:exception]&.message,
                **failure.except(:exception, :error))
  end

  # Returns list of translation keys where error messages could be provided. List is in order of precedence.
  #
  # For example, for a failure in the Asset::Create operation the following keys will be returned:
  #   asset.create.failure.{error}
  #   asset.failure.{error}
  #   resource.failure.{error}
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
