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

  class TechnicalMetadataChangeSet < Valkyrie::ChangeSet
    property :raw, multiple: false
    property :mime_type, multiple: false
    property :size, multiple: false
    property :duration, multiple: false
    property :md5, multiple: false
    property :sha256, multiple: false
  end

  # Defining Fields
  property :alternate_ids, multiple: true, required: false
  property :original_filename, multiple: false, required: true
  property :file_ids, multiple: true, required: false
  # property :descriptive_metadata, multiple: false, form: DescriptiveMetadataChangeSet
  property :technical_metadata, multiple: false, form: TechnicalMetadataChangeSet

  # Validations
  validates :original_filename, presence: true
end