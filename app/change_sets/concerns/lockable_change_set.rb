# frozen_string_literal: true

# Mix in attributes and methods required for a ChangeSet to work with optimistic locking of resources
module LockableChangeSet
  extend ActiveSupport::Concern

  included do
    property :optimistic_lock_token,
             multiple: true, required: true, type: Valkyrie::Types::Set.of(Valkyrie::Types::OptimisticLockToken)
  end

  # Used in form component to tell if we should render the token as a hidden field
  # @return [TrueClass]
  def lockable?
    true
  end
end
