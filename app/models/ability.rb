# frozen_string_literal: true

# authz logic
class Ability
  include CanCan::Ability

  def initialize(user)
    return if user.blank?

    can [:read, :create], BulkExport
    can [:update, :destroy, :cancel, :regenerate], BulkExport, created_by: user
    can [:read, :csv], BulkImport
    can [:read], Import

    if user.viewer?
      can :read, [ItemResource, AssetResource]
    elsif user.editor?
      can [:read, :create, :update], [ItemResource, AssetResource]
      can [:read, :create], BulkImport
      can [:update, :cancel], BulkImport, created_by: user
      can [:update, :cancel], Import, bulk_import: { created_by: user }
    elsif user.admin?
      can :manage, :all
    end
  end
end
