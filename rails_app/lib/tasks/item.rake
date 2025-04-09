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

    desc 'Generate item-level pdfs for all published items without one'
    task generate_pdf_derivatives: :environment do
      query_service = Valkyrie::MetadataAdapter.find(:postgres).query_service
      query_service.custom_queries.items_without_derivative(type: :pdf).each do |item|
        PublishItemJob.perform_async(item.id.to_s, Settings.system_user) if item.published
      end
    end

    desc 'Migrate ocr_type to ocr_strategy'
    task migrate_ocr_type: :environment do
      query_service = Valkyrie::MetadataAdapter.find(:postgres).query_service
      query_service.custom_queries.find_by_ocr_type(ocr_type: 'printed').each do |item|
        UpdateItem.new.call(id: item.id.to_s, ocr_strategy: item.ocr_type, updated_by: Settings.system_user)
      end
    end
  end
end
