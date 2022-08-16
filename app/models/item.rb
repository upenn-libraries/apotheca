class Item
  def initialize(resource)
    raise 'Resource must be an ItemResource' unless resource.is_a?(ItemResource)
    @resource = resource
    @change_set = ItemChangeSet.new(@resource)

    self
  end

  def self.create(attributes)
    item = Item.new(ItemResource.new)

    item.update(attributes)
  end

  def update(attributes)
    valid = @change_set.validate(attributes)
    raise 'Error validating item' unless valid # TODO: need to return the item so that we can access validation errors

    save
  end

  private

  def save
    before_save

    @resource = @change_set.sync
    @resource = Valkyrie::MetadataAdapter.find(:postgres_solr_persister).persister.save(resource: @resource)
  end

  def before_save
    mint_ark
    update_ark_metadata
    # merge_marc_metadata
    set_thumbnail_asset_id
  end

  def mint_ark
    return if ark

    ark = Ezid::Identifier.mint
    @change_set.alternate_ids = [ark]
  end

  def update_ark_metadata
    # TODO: This is the metadata that we use now, but we should probably revisit.
    erc_metadata = {
      erc_who: @change_set.descriptive_metadata.creator.join('; '),
      erc_what: @change_set.descriptive_metadata.title.join('; '),
      erc_when: @change_set.descriptive_metadata.date.join('; ')
    }
    Ezid::Identifier.modify(@change_set.alternate_ids.first.id, erc_metadata)
  end

  def ark
    arks = @change_set.alternate_ids.select { |i| i.to_s.starts_with?('ark:/') } # TODO: Maybe should check for the whole shoulder
    raise "More than one ark defined" if arks.count > 1
    arks.count == 1 ? arks.first : nil
  end

  def set_thumbnail_asset_id
    return if @change_set.thumbnail_asset_id.present?

    @resource.thumbnail_asset_id = if @change_set.structural_metadata.arranged_asset_ids&.any?
                                     @change_set.structural_metadata.arranged_asset_ids.first
                                   elsif @change_set.asset_ids&.any?
                                     @change_set.asset_ids.first
                                   else
                                     nil
                                   end
  end
end
