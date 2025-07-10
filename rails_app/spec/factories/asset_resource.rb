# frozen_string_literal: true

# Factory for AssetResource.
#
# Use `.build` to build object and use `.persist` to persist via Valkyrie persister.
FactoryBot.define do
  factory :asset_resource do
    original_filename { 'front.tif' }
    created_by { 'admin@library.upenn.edu' }
    updated_by { 'admin@library.upenn.edu' }

    trait :with_metadata do
      label { 'Front' }
      annotations { [{ text: 'Front of Card' }] }
    end

    trait :with_metadata_no_label do
      annotations { [{ text: 'Illuminated P' }] }
    end

    trait :with_image_file do
      with_preservation_file

      technical_metadata do
        {
          size: 291_455,
          mime_type: 'image/tiff',
          sha256: ['sha256checksum'],
          height: 238,
          width: 400,
          dpi: 600,
          raw: '<?xml version="1.0" encoding="UTF-8"?>'
        }
      end

      transient do
        preservation_file { 'trade_card/original/front.tif' }
      end
    end

    trait :with_pdf_file do
      with_preservation_file

      original_filename { 'dummy.pdf' }

      technical_metadata do
        {
          size: 13_264,
          mime_type: 'application/pdf',
          sha256: ['sha256checksum']
        }
      end

      transient do
        preservation_file { 'dummy.pdf' }
      end
    end

    trait :with_audio_file do
      with_preservation_file

      technical_metadata do
        {
          mime_type: 'audio/x-wave',
          size: 30_804,
          duration: 0.17,
          sha256: ['sha256checksum']
        }
      end

      transient do
        preservation_file { 'bell.wav' }
      end
    end

    trait :with_video_file do
      with_preservation_file

      technical_metadata do
        {
          mime_type: 'video/quicktime',
          size: 480_754,
          duration: 1.134,
          height: 480,
          width: 640,
          sha256: ['sha256checksum']
        }
      end

      transient do
        preservation_file { 'video.mov' }
      end
    end

    trait :with_preservation_backup do
      transient do
        preservation_backup { true }
      end
    end

    trait :with_derivatives do
      transient do
        iiif_image { true }
        access { true }
        thumbnail { true }
        text { true }
        hocr { true }
        textonly_pdf { true }
      end
    end

    # **This trait is not meant to be used directly!!**
    # To add a file to an asset_resource use the file specific traits above: with_image_file, with_pdf_file, etc.
    trait :with_preservation_file do
      transient do
        preservation_file { nil }
        preservation_backup { false }
        iiif_image { false }
        access { false }
        thumbnail { false }
        text { false }
        hocr { false }
        textonly_pdf { false }
      end

      # Attach file as preservation file. If `preservation_backup` flag is set to true also
      # backs up preservation file. If `access_copy` is set to true generates access copy derivative.
      after(:create) do |asset, evaluator|
        uploaded_file = ActionDispatch::Http::UploadedFile.new(
          tempfile: File.new(Rails.root.join("spec/fixtures/files/#{evaluator.preservation_file}")),
          filename: asset.original_filename, type: asset.technical_metadata.mime_type
        )
        preservation_storage = Valkyrie::StorageAdapter.find(:preservation)
        file = preservation_storage.upload(file: uploaded_file, resource: asset,
                                           original_filename: asset.original_filename)
        asset.preservation_file_id = file.id

        if evaluator.preservation_backup
          preservation_file = Valkyrie::StorageAdapter.find_by(id: asset.preservation_file_id)

          preservation_copy_storage = Valkyrie::StorageAdapter.find(:preservation_copy)
          file = preservation_copy_storage.upload(
            file: preservation_file, resource: asset, original_filename: asset.original_filename
          )
          asset.preservation_copies_ids = [file.id]
        end

        change_set = AssetChangeSet.new(asset)
        change_set.ocr_strategy = 'printed'
        change_set.ocr_language = ['eng']
        derivative_service = DerivativeService::Asset::Derivatives.new(change_set)

        AssetChangeSet::DERIVATIVE_TYPES.each do |type|
          next unless evaluator.send(type) # Check if derivative was requested.

          derivative = derivative_service.send(type)

          next if derivative.nil? # Return early if no derivative could be generated.

          derivative_storage = if derivative.iiif_image
                                 Valkyrie::StorageAdapter.find(:iiif_derivatives)
                               else
                                 Valkyrie::StorageAdapter.find(:derivatives)
                               end

          file = derivative_storage.upload(file: derivative, resource: asset, original_filename: type)

          asset.derivatives << DerivativeResource.new(file_id: file.id, mime_type: derivative.mime_type,
                                                      size: derivative.size, type: type, generated_at: DateTime.current)
        end
      end
    end
  end
end
