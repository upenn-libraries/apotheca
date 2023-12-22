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
      can :read, [ItemResource, AssetResource]
    elsif user.editor?
      can %i[read create update], AssetResource
      can %i[read create update publish reorder_assets refresh_ils_metadata], ItemResource
      can %i[read create], BulkImport
      can %i[update cancel], BulkImport, created_by: user
      can %i[update cancel], Import, bulk_import: { created_by: user }
      can :manage, :sidekiq_dashboard
    elsif user.admin?
      can :manage, :all
    end
  end
end
