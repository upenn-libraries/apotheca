# frozen_string_literal: true

# authz logic
class Ability
  include CanCan::Ability

  def initialize(user)
    return if user.blank?

    can [:read, :create], BulkExport
    can [:update, :destroy, :cancel], BulkExport, created_by: user

    if user.viewer?
      can :read, [ItemResource, AssetResource]
    elsif user.editor?
      can [:read, :create, :update], [ItemResource, AssetResource]
    elsif user.admin?
      can :manage, :all
    end

  end
end
