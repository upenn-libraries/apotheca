class AssetChangeSet < Valkyrie::ChangeSet
  class AnnotationChangeSet < Valkyrie::ChangeSet
    property :text, multiple: false

    validates :text, presence: true
  end

  class DescriptiveMetadataChangeSet < Valkyrie::ChangeSet
    property :label, multiple: false
    collection :annotations, multiple: true, form: AnnotationChangeSet, populate_if_empty: AssetResource::Annotation
  end

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
  property :descriptive_metadata, multiple: false, form: DescriptiveMetadataChangeSet
  property :technical_metadata, multiple: false, form: TechnicalMetadataChangeSet

  collection :derivatives, multiple: true, form: DerivativeChangeSet, populate_if_empty: DerivativeResource

  # Validations
  validates :original_filename, presence: true
end
