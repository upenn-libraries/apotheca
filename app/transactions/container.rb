# frozen_string_literal: true

class Container
  extend Dry::Container::Mixin

  namespace 'change_set' do
    register 'validate' do
      Steps::Validate.new
    end

    register 'save' do
      Steps::Save.new
    end

    register 'set_updated_by' do
      Steps::SetUpdatedBy.new
    end

    register 'require_updated_by' do
      Steps::RequireUpdatedBy.new
    end
  end

  namespace 'item_resource' do
    register 'find_resource' do
      Steps::FindResource.new(ItemResource)
    end

    register 'create_change_set' do
      Steps::CreateChangeSet.new(ItemResource, ItemChangeSet)
    end

    register 'set_thumbnail' do
      Steps::SetThumbnail.new
    end

    register 'update_ark_metadata' do
      Steps::UpdateArkMetadata.new
    end
  end

  namespace 'asset_resource' do
    register 'find_resource' do
      Steps::FindResource.new(AssetResource)
    end

    register 'create_change_set' do
      Steps::CreateChangeSet.new(AssetResource, AssetChangeSet)
    end
  end
end
