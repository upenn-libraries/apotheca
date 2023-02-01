# frozen_string_literal: true

# authz logic
class Ability
  include CanCan::Ability

  def initialize(user)
    return if user.blank?

    if user.viewer?
      can :read, [BulkExport, ItemResource, AssetResource]
    elsif user.editor?
      can [:read, :create, :update], [ItemResource, AssetResource]
      can [:read, :create], BulkExport
      can [:update, :destroy], BulkExport, user: user
    elsif user.admin?
      can :manage, :all
    end

  end
end
