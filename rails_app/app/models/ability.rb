# frozen_string_literal: true

# authz logic
class Ability
  include CanCan::Ability

  ITEM_OBJECTS = [ItemResource, ItemPresenter].freeze

  def initialize(user)
    return if user.blank?

    can %i[read create], BulkExport
    can %i[update destroy cancel regenerate], BulkExport, created_by: user
    can %i[read csv], BulkImport
    can [:read], [Import, Report]

    if user.viewer?
      can :read, [*ITEM_OBJECTS, AssetResource]
      can :file, ITEM_OBJECTS
    elsif user.editor?
      can %i[read create update], AssetResource
      can %i[read create update file publish unpublish reorder_assets refresh_ils_metadata regenerate_all_derivatives],
          ITEM_OBJECTS
      can %i[read create], BulkImport
      can %i[update cancel], BulkImport, created_by: user
      can %i[update cancel], Import, bulk_import: { created_by: user }
      can :manage, :sidekiq_dashboard
    elsif user.admin?
      can :manage, :all
    end
  end
end
