class Item
  def initialize(resource)
    raise 'Resource must be an ItemResource' unless resource.is_a?(ItemResource)
    @resource = resource
    @change_set = ItemChangeSet.new(@resource)

    self
  end

  def self.create(attributes)
    attributes[:updated_by] = attributes[:created_by] if attributes[:updated_by].blank?

    item = Item.new(ItemResource.new)
    item.update(attributes)
  end

  def update(attributes)
    # TODO: Should require `updated_by` to be set.
    @change_set.validate(attributes) # Set values
    before_validate

    # TODO: need to return the item so that we can access validation errors
    raise 'Error validating item' unless @change_set.valid?

    save
  end

  private

  def save
    before_save

    @resource = @change_set.sync
    @resource = Valkyrie::MetadataAdapter.find(:postgres_solr_persister).persister.save(resource: @resource)
  end

  def before_validate
    mint_ark
    set_thumbnail_asset_id
  end

  def before_save
    update_ark_metadata
    # merge_marc_metadata
  end

  def mint_ark
    return if @change_set.unique_identifier.present?

    ark = Ezid::Identifier.mint
    @change_set.unique_identifier = ark
  end

  def update_ark_metadata
    # TODO: This is the metadata that we use now, but we should probably revisit.
    erc_metadata = {
      erc_who: @change_set.descriptive_metadata.creator.join('; '),
      erc_what: @change_set.descriptive_metadata.title.join('; '),
      erc_when: @change_set.descriptive_metadata.date.join('; ')
    }
    Ezid::Identifier.modify(@change_set.unique_identifier, erc_metadata)
  end

  def set_thumbnail_asset_id
    return if @change_set.thumbnail_asset_id.present?

    thumbnail_id = if @change_set.structural_metadata.arranged_asset_ids&.any?
                     @change_set.structural_metadata.arranged_asset_ids.first
                   elsif @change_set.asset_ids&.any?
                     @change_set.asset_ids.first
                   else
                     nil
                   end

    @change_set.thumbnail_asset_id = thumbnail_id
  end
end
