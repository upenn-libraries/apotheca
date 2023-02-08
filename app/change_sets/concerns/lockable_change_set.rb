# frozen_string_literal: true

module LockableChangeSet
  extend ActiveSupport::Concern

  included do
    property :optimistic_lock_token,
             multiple: true, required: true, type: Valkyrie::Types::Set.of(Valkyrie::Types::OptimisticLockToken)

  end

  # @return [TrueClass]
  def lockable?
    true
  end
end
