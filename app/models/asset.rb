class Asset
  def initialize(resource)
    raise 'Resource must be an AssetResource' unless resource.is_a?(AssetResource)
    @resource = resource
    @change_set = AssetChangeSet.new(@resource)

    self
  end

  def self.create(attributes)
    asset = Asset.new(AssetResource.new)
    asset.update(attributes)
  end

  def update(file: nil, **attributes)
    valid = @change_set.validate(attributes)
    raise 'Error validating asset' unless valid

    # Sync and save asset with attributes because we need the identifier in order to attach the file.
    save

    # Add File to Asset if file present
    if file
      preservation_storage = Valkyrie::StorageAdapter.find(:preservation)
      file_resource = preservation_storage.upload(file: file, resource: @resource, original_filename: @resource.original_filename)

      # New change set.
      @change_set = AssetChangeSet.new(@resource)
      @change_set.file_ids = [file_resource.id]

      save
    end
  end

  private

  def before_save
    # TODO: Generate derivatives for assets, if file was added
    # TODO: Characterize file and add technical metadata to resource, if file was added.
  end

  def save
    before_save

    @resource = @change_set.sync
    @resource = Valkyrie::MetadataAdapter.find(:postgres_solr_persister).persister.save(resource: @resource)
  end
end