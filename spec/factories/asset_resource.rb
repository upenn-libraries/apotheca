# frozen_string_literal: true

# Factory for AssetResource.
#
# Use `.build` to build object and use `.persist` to persist via Valkyrie persister.
FactoryBot.define do
  factory :asset_resource do
    original_filename { 'front.jpg' }
    created_by { 'admin@library.upenn.edu' }
    updated_by { 'admin@library.upenn.edu' }
  end

  trait :with_preservation_file do
    technical_metadata { { mime_type: 'image/jpeg' } }

    transient do
      preservation_backup { false }
    end
    # Attach file as preservation file. If `preservation_backup` flag is set to true also
    # backs up preservation file.
    #
    # Note: This does not generate derivatives.
    before(:create) do |asset, evaluator|
      uploaded_file = ActionDispatch::Http::UploadedFile.new(
        tempfile: File.new(Rails.root.join('spec/fixtures/files/front.jpg')),
        filename: asset.original_filename, type: asset.technical_metadata.mime_type
      )
      preservation_storage = Valkyrie::StorageAdapter.find(:preservation)
      file = preservation_storage.upload(file: uploaded_file, resource: asset,
                                         original_filename: asset.original_filename)
      asset.preservation_file_id = file.id

      if evaluator.preservation_backup
        uploaded_file.rewind

        preservation_copy_storage = Valkyrie::StorageAdapter.find(:preservation_copy)
        file = preservation_copy_storage.upload(file: uploaded_file, resource: asset,
                                           original_filename: asset.original_filename)
        asset.preservation_copies_ids = [file.id]
      end
    end
  end

  trait :with_preservation_backup do
    transient do
      preservation_backup { true }
    end
  end
end
