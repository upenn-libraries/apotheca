class AssetChangeSet < Valkyrie::ChangeSet
  # class TableOfContentsChangeSet < Valkyrie::ChangeSet
  #   property :text, multiple: false, required: true
  #
  #   validates :text, presence: true
  # end
  #
  # class DescriptiveMetadataChangeSet < Valkyrie::ChangeSet
  #   property :label, multiple: false
  #   collection :table_of_contents, multiple: true, form: TableOfContentsChangeSet, populate_if_empty: AssetResource::TableOfContents
  # end

  # Defining Fields
  property :alternate_ids, multiple: true, required: false
  property :original_filename, multiple: false, required: true
  property :file_ids, multiple: true, required: false
  # property :descriptive_metadata, multiple: false, form: DescriptiveMetadataChangeSet

  # Validations
  validates :original_filename, presence: true
end