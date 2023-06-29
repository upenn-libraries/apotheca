# frozen_string_literal: true

class ItemChangeSet
  # ChangeSet for ItemResource::DescriptiveMetadata nested resource.
  class DescriptiveMetadataChangeSet < Valkyrie::ChangeSet
    ItemResource::DescriptiveMetadata::Fields.text_fields.each do |field|
      property field, multiple: true

      # Remove blank values from array.
      define_method "#{field}=" do |values|
        super(values&.compact_blank)
      end
    end

    ItemResource::DescriptiveMetadata::Fields.term_fields.each do |field|
      collection field, multiple: true, required: false, form: ControlledTermChangeSet, populator: :term!
    end

    collection :name, multiple: true, form: NameTermChangeSet,
                      populate_if_empty: ItemResource::DescriptiveMetadata::NameTerm

    validates :title, presence: true, if: ->(metadata) { metadata.bibnumber.blank? }

    def term!(collection:, index:, fragment:, **)
      if fragment['label'].blank? && fragment[:label].blank? && fragment['uri'].blank? && fragment[:uri].blank?
        skip!
      elsif (item = collection[index])
        item
      else
        collection.insert(index, ItemResource::DescriptiveMetadata::ControlledTerm.new)
      end
    end
  end
end
