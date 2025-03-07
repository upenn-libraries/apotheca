# frozen_string_literal: true

# Tasks to extract translations from FromThePage.
namespace :fromthepage do
  desc 'Extract transcriptions from all collections'
  task extract_all_collection: :environment do
    skip_collections = ENV.fetch('SKIP_COLLECTIONS', 'morais').split(',')
    updated_by = ENV.fetch('UPDATED_BY', nil)
    url = ENV.fetch('URL', 'https://fromthepage.com')
    token = ENV.fetch('TOKEN', nil)

    if updated_by.blank? || url.blank? || token.blank?
      puts 'Specify "URL", "TOKEN" and "UPDATED_BY" in environment variables to run this task'
      return
    end

    from_the_page = FromThePage.new(url, token)

    # Grob all the collection urls for UPenn.
    collection_ids = from_the_page.collection_ids('upenn')

    # Skip some collections.
    collection_ids = collection_ids - skip_collections

    # Extract all manifest URLs from all collections.
    manifest_urls = collection_ids.flat_map { |id| from_the_page.work_manifests(id) }

    # Run through each manifest urls and migrate transcriptions.
    output = manifest_urls.map do |manifest_url|
      manifest = from_the_page.manifest(manifest_url)

      unique_identifier = manifest.unique_identifier
      raise "Unable to extract unique_identifier from #{manifest_url}" if unique_identifier.nil?

      # Lookup item based on unique_identifier.
      query_service = Valkyrie::MetadataAdapter.find(:postgres).query_service
      resource = query_service.custom_queries.find_by_unique_identifier(unique_identifier: unique_identifier)

      next "#{unique_identifier}: Resource not found!" unless resource
      next "#{unique_identifier}: Transcriptions already present!" if resource.arranged_assets.any? { |a| a.transcriptions.present? }

      transcriptions = manifest.transcriptions

      next "#{unique_identifier}: Number of pages in FromThePage does not match Item!" if transcriptions.count != resource.arranged_assets.count

      results = resource.arranged_assets.map.with_index do |asset, index|
        transcription = transcriptions[index].strip

        next if transcription.blank?

        UpdateAsset.new.call(id: asset.id.to_s, updated_by: updated_by, transcriptions: [{ contents: transcription, mime_type: 'text/plain' }])
      end

      if results.compact.all?(&:success?)
        "#{unique_identifier}: Transcriptions successfully migrated!"
      else
        "#{unique_identifier}: Transcriptions were not all migrated!"
      end
    end

    output.each { |str| puts str }
  end
end