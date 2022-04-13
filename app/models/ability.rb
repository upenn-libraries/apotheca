# frozen_string_literal: true

# authz logic
class Ability
  include CanCan::Ability

  def initialize(user)
    return if user.blank?

    if user.viewer?
      can :read, [ItemResource, AssetResource]
    elsif user.editor?
      can :manage, [ItemResource, AssetResource]
    elsif user.admin?
      can :manage, :all
    end

  end
end
