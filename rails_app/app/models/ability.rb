# frozen_string_literal: true

# authz logic
class Ability
  include CanCan::Ability

  def initialize(user)
    return if user.blank?

    can %i[read create], BulkExport
    can %i[update destroy cancel regenerate], BulkExport, created_by: user
    can %i[read csv], BulkImport
    can [:read], Import

    if user.viewer?
      # viewer is the base level role, so all users can read the following
      can :read, [ItemResource, AssetResource, Report]
    elsif user.editor?
      can %i[read create update], AssetResource
      can %i[read create update publish unpublish reorder_assets refresh_ils_metadata regenerate_all_derivatives],
          ItemResource
      can %i[read create], BulkImport
      can %i[update cancel], BulkImport, created_by: user
      can %i[update cancel], Import, bulk_import: { created_by: user }
      can :manage, :sidekiq_dashboard
    elsif user.admin?
      can :manage, :all
    end
  end
end
