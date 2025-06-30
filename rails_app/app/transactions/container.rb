# frozen_string_literal: true

# Register and organize sets of steps within different namespaces. This class provides a convenient way to retrieve
# instances of specific steps based on their registered keys.
class Container
  extend Dry::Core::Container::Mixin

  namespace 'attributes' do
    register 'require_updated_by' do
      Steps::RequireAttribute.new(:updated_by)
    end

    register 'require_deleted_by' do
      Steps::RequireAttribute.new(:deleted_by)
    end
  end

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

    register 'enqueue_ark_metadata_update' do
      Steps::EnqueueArkMetadataUpdate.new
    end

    register 'delete_resource' do
      Steps::DeleteResource.new
    end

    register 'delete_derivatives' do
      Steps::DeleteDerivatives.new
    end

    register 'generate_derivatives' do
      Steps::GenerateDerivatives.new(DerivativeService::Item::Derivatives, :iiif_manifest, :iiif_v3_manifest, :pdf)
    end
  end

  namespace 'asset_resource' do
    register 'find_resource' do
      Steps::FindResource.new(AssetResource)
    end

    register 'find_asset_parent_item' do
      Steps::FindAssetParentItem.new
    end

    register 'create_change_set' do
      Steps::CreateChangeSet.new(AssetResource, AssetChangeSet)
    end

    register 'add_technical_metadata' do
      Steps::AddTechnicalMetadata.new
    end

    register 'cleanup' do
      Around::AssetCleanup.new
    end

    register 'delete_resource' do
      Steps::DeleteResource.new
    end

    register 'delete_derivatives' do
      Steps::DeleteDerivatives.new
    end

    register 'delete_preservation_files' do
      Steps::DeletePreservationFiles.new
    end

    register 'detach_from_item' do
      Steps::DetachFromItem.new
    end

    register 'add_preservation_events' do
      Steps::AddPreservationEvents.new
    end

    register 'virus_check' do
      Steps::VirusCheck.new
    end

    register 'generate_derivatives' do
      Steps::GenerateDerivatives.new(DerivativeService::Asset::Derivatives,
                                     :thumbnail, :access, :textonly_pdf, :text, :hocr)
    end
  end
end
