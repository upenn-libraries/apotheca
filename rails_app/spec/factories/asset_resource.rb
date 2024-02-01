# frozen_string_literal: true

# Factory for AssetResource.
#
# Use `.build` to build object and use `.persist` to persist via Valkyrie persister.
FactoryBot.define do
  factory :asset_resource do
    original_filename { 'front.tif' }
    created_by { 'admin@library.upenn.edu' }
    updated_by { 'admin@library.upenn.edu' }
  end

  trait :with_metadata do
    label { 'Front' }
    annotations { [{ text: 'Front of Card' }] }
  end

  trait :with_preservation_file do
    technical_metadata do
      {
        size: 291_455,
        mime_type: 'image/tiff',
        sha256: ['sha256checksum'],
        height: 238,
        width: 400,
        raw: '<?xml version="1.0" encoding="UTF-8"?>'
      }
    end

    transient do
      preservation_backup { false }
      access_copy { false }
      thumbnail { false }
      preservation_file { 'front.tif' }
    end

    # Attach file as preservation file. If `preservation_backup` flag is set to true also
    # backs up preservation file. If `access_copy` is set to true generates access copy derivative.
    after(:create) do |asset, evaluator|
      uploaded_file = ActionDispatch::Http::UploadedFile.new(
        tempfile: File.new(Rails.root.join("spec/fixtures/files/trade_card/original/#{evaluator.preservation_file}")),
        filename: asset.original_filename, type: asset.technical_metadata.mime_type
      )
      preservation_storage = Valkyrie::StorageAdapter.find(:preservation)
      file = preservation_storage.upload(file: uploaded_file, resource: asset,
                                         original_filename: asset.original_filename)
      asset.preservation_file_id = file.id

      if evaluator.preservation_backup
        uploaded_file.rewind

        preservation_copy_storage = Valkyrie::StorageAdapter.find(:preservation_copy)
        file = preservation_copy_storage.upload(
          file: uploaded_file, resource: asset, original_filename: asset.original_filename
        )
        asset.preservation_copies_ids = [file.id]
      end

      if evaluator.access_copy
        uploaded_file.rewind

        iiif_derivative_storage = Valkyrie::StorageAdapter.find(:iiif_derivatives)
        file = iiif_derivative_storage.upload(
          file: uploaded_file, resource: asset, original_filename: 'access'
        )

        asset.derivatives << DerivativeResource.new(file_id: file.id, mime_type: asset.technical_metadata.mime_type,
                                                    type: 'access', generated_at: DateTime.current)
      end

      if evaluator.thumbnail
        uploaded_file.rewind

        derivative_storage = Valkyrie::StorageAdapter.find(:derivatives)
        file = derivative_storage.upload(
          file: uploaded_file, resource: asset, original_filename: 'thumbnail'
        )

        asset.derivatives << DerivativeResource.new(file_id: file.id, mime_type: asset.technical_metadata.mime_type,
                                                    type: 'thumbnail', generated_at: DateTime.current)
      end
    end
  end

  trait :with_preservation_backup do
    transient do
      preservation_backup { true }
    end
  end

  trait :with_derivatives do
    transient do
      access_copy { true }
      thumbnail { true }
    end
  end
end
