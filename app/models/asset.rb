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
    add_file_characterization
    # TODO: generate sha256 checksum
  end

  def save
    before_save

    @resource = @change_set.sync
    @resource = Valkyrie::MetadataAdapter.find(:postgres_solr_persister).persister.save(resource: @resource)
  end

  def add_file_characterization
    return unless @change_set.changed?(:file_ids)
    file_id = @change_set.file_ids.first

    preservation_storage = Valkyrie::StorageAdapter.find(:preservation)
    file = preservation_storage.find_by(id: file_id)

    fits = FileCharacterization::Fits.new(url: Settings.fits.url)

    tech_metadata = fits.examine(contents: file.read, filename: @change_set.original_filename)

    @change_set.technical_metadata.raw       = tech_metadata.raw
    @change_set.technical_metadata.mime_type = tech_metadata.mime_type
    @change_set.technical_metadata.size      = tech_metadata.size
    @change_set.technical_metadata.md5       = tech_metadata.md5
    @change_set.technical_metadata.duration  = tech_metadata.duration
  end
end