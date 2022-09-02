class Asset
  attr_accessor :file

  def initialize(resource)
    raise 'Resource must be an AssetResource' unless resource.is_a?(AssetResource)
    @resource = resource
    @change_set = AssetChangeSet.new(@resource)

    self
  end

  def self.create(attributes)
    attributes[:updated_by] = attributes[:created_by] if attributes[:updated_by].blank?

    asset = Asset.new(AssetResource.new)
    asset.update(attributes)
  end

  def update(file: nil, **attributes)
    # TODO: Should require `updated_by` to be set.
    valid = @change_set.validate(attributes)
    raise 'Error validating asset' unless valid

    # Sync and save asset with attributes because we need the identifier in order to attach the file.
    save

    # Add File to Asset if file present
    if file
      preservation_storage = Valkyrie::StorageAdapter.find(:preservation)
      file_resource = preservation_storage.upload(file: file, resource: @resource, original_filename: @resource.original_filename)

      # TODO: Might want to explicitly close the reference to the original file. It's not necessary, but its considered
      # good practice and can lead to the tmp space being cleaned up sooner.

      # New change set.
      @change_set = AssetChangeSet.new(@resource)
      @change_set.preservation_file_id = file_resource.id

      save
    end
  end

  private

  def before_save
    if file.present?
      add_file_characterization
      add_derivatives
      generate_sha256_checksum
    end
  end

  def save
    set_file if file_changed?

    before_save

    @resource = @change_set.sync
    @resource = Valkyrie::MetadataAdapter.find(:postgres).persister.save(resource: @resource)
  end

  # @return [TrueClass, FalseClass]
  def file_changed?
    @change_set.changed?(:preservation_file_id)
  end

  def set_file
    file_id = @change_set.preservation_file_id

    preservation_storage = Valkyrie::StorageAdapter.find(:preservation)
    @file = preservation_storage.find_by(id: file_id)
  end

  def add_file_characterization
    fits = FileCharacterization::Fits.new(url: Settings.fits.url)

    tech_metadata = fits.examine(contents: file.read, filename: @change_set.original_filename)

    @change_set.technical_metadata.raw       = tech_metadata.raw
    @change_set.technical_metadata.mime_type = tech_metadata.mime_type
    @change_set.technical_metadata.size      = tech_metadata.size
    @change_set.technical_metadata.md5       = tech_metadata.md5
    @change_set.technical_metadata.duration  = tech_metadata.duration
  end

  def add_derivatives
    # TODO: derivative generation can fail, we need to account for that.
    generator = DerivativeService::Generator.for(file, @change_set.technical_metadata.mime_type)
    derivative_storage = Valkyrie::StorageAdapter.find(:derivatives)

    # TODO: remove previous derivatives?
    # if new derivatives are generated is it overriding the current file in derivative storage
    [:thumbnail, :access].each do |type|
      derivative_file = generator.send(type) # todo: explicitly close the DerivativeFile
      file_resource = derivative_storage.upload(file: derivative_file, resource: @resource, original_filename: type)

      @change_set.derivatives << DerivativeResource.new(file_id: file_resource.id, mime_type: derivative_file.mime_type, type: type, generated_at: DateTime.current)

      # uploading the new derivatives should override them because currently they will have the same filename.
      # TODO: need to figure out what to do if we are updating a derivative
      # TODO: if derivative generation fails need to delete any files that were created.
    end
  end

  def generate_sha256_checksum
    @change_set.technical_metadata.sha256 = file.checksum digests: [Digest::SHA256.new]
  end
end
