# frozen_string_literal: true

namespace :apotheca do
  namespace :item do
    desc 'Republish items that have already been published'
    task republish: :environment do
      email = ENV.fetch('EMAIL', nil)

      if email.blank?
        puts 'Provide a User email for the user running this task'
        next
      end

      if User.find_by(email: email).nil?
        puts 'Provide email for valid user.'
        next
      end

      query_service = Valkyrie::MetadataAdapter.find(:postgres).query_service
      query_service.find_all_of_model(model: ItemResource).each do |item|
        PublishItemJob.perform_async(item.id.to_s, email) if item.published
      end
    end

    desc 'Fix items that are missing PDFs by re-extracting the DPI for assets with invalid (or missing) DPIs'
    task fix_items_without_pdfs: :environment do
      query_service = Valkyrie::MetadataAdapter.find(:postgres).query_service

      # Finding items that don't have PDFs to ensure that all the assets contained within those items have a valid DPI.
      # We are including unpublished items in our search to ensure those items have DPIs in case we do publish one day.
      items_without_pdfs = query_service.custom_queries.items_without_derivative(type: :pdf).select do |item|
        item.structural_metadata.arranged_asset_ids.count <= 2000 && item.assets.all?(&:image?)
      end

      items_without_pdfs.each do |item|
        item.assets.each do |asset|
          dpi = asset.technical_metadata.dpi
          AddDPI.new.call(id: asset.id.to_s, updated_by: Settings.system_user) if dpi.nil? || dpi.zero? || dpi == 1
        end

        PublishItemJob.perform_async(item.id.to_s, Settings.system_user) if item.published
      end
    end

    desc 'Migrate access image derivatives to iiif_image derivatives'
    task migrate_access_derivatives_to_iiif_image_derivative: :environment do
      query_service = Valkyrie::MetadataAdapter.find(:postgres).query_service
      query_service.find_all_of_model(model: ItemResource).each do |item|
        MigrateAccessToIIIFImageDerivativeJob.perform_async(item.id.to_s)
      end
    end
  end
end
